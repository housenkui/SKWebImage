//
//  SKImageCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageCache.h"
#import "SKImageDecoder.h"
#import <CommonCrypto/CommonDigest.h>

static NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 7 days

@interface SKImageCache ()
@property (strong,nonatomic) NSCache *memCache;
@property (copy,nonatomic) NSString *diskCachePath;
@property (strong,nonatomic) dispatch_queue_t ioQueue;
@end
@implementation SKImageCache

#pragma mark SKImageCache (class methods)
+ (SKImageCache *)sharedImageCache {
    static SKImageCache *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SKImageCache alloc]init];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithNamespace:@"default"];
}

- (instancetype)initWithNamespace:(NSString *)ns
{
    if (self = [super init]) {
        
        NSString *fullNamespace = [@"com.github.SKWebImageCache." stringByAppendingString:ns];
        
        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.github.SKWebImageCache", DISPATCH_QUEUE_SERIAL);
        //Init default values
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        
        //Init the memory cache
        _memCache = [[NSCache alloc]init];
        _memCache.name = fullNamespace;
        
        //Init the disk cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
        NSLog(@"_diskCachePath = %@",_diskCachePath);
       
#if TARGET_OS_IPHONE
        //Subscribe to app events
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(clearMemory)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(cleanDisk)
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
#endif
    }
    return self;
}

#pragma mark SKImageCache (private)
- (NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [self.diskCachePath stringByAppendingPathComponent:filename];
}

#pragma mark --ImageCache
- (void)storeImage:(UIImage *)image forKey:(NSString *)key imageData:(nullable NSData *)imageData toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    [self.memCache setObject:image forKey:key cost:image.size.height * image.size.width *image.scale];
    if (toDisk)
    {
        dispatch_async(self.ioQueue, ^{
            NSData *data = imageData;
            if (!data) {
                if (image) {
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
            }
            if (data)
            {
                //Can't use defaultManager another thread
                NSFileManager *fileManager = NSFileManager.new;
                if (![fileManager fileExistsAtPath:self->_diskCachePath]) {
                    [fileManager createDirectoryAtPath:self->_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
                [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
            }
        });
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image forKey:key imageData:nil toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image forKey:key imageData:nil toDisk:toDisk];
}

- (void)queryDiskCacheForKey:(NSString *)key down:(nonnull void (^)(UIImage * image ))doneBlock
{
    if (!doneBlock) return;
    
    if (!key)
    {
        doneBlock(nil);
        return;
    }
    //First check the in-memory cache...
    UIImage *image = [self.memCache objectForKey:key];
    if (image) {
        doneBlock(image);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        UIImage *diskImage = [UIImage decodedImageWithImage:SKScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]])];
        if (diskImage) {
            [self.memCache setObject:diskImage forKey:key cost:image.size.height * image.size.width *image.scale];
        }
        doneBlock(diskImage);
    });
}
- (void)removeImageForKey:(NSString *)key {
    [self removeImageForKey:key fromDisk:YES];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    if (!key) {
        return;
    }
    [self.memCache removeObjectForKey:key];
    if (fromDisk) {
        dispatch_async(self.ioQueue, ^{
            [[NSFileManager defaultManager]removeItemAtPath:[self cachePathForKey:key] error:nil];
        });
    }
}


- (void)clearMemory {
    [self.memCache removeAllObjects];
}
- (void)clearDisk {
    dispatch_async(self.ioQueue, ^{
        [[NSFileManager defaultManager]removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager]createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    });
}
#pragma mark ---清除一周内没有使用的图片
- (void)cleanDisk {
    dispatch_async(self.ioQueue, ^{
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
        
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager]attributesOfItemAtPath:filePath error:nil];
            if ([[[attrs fileModificationDate]laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
            }
        }
    });
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (unsigned long long)getSize
{
    int size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager]enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager]attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}
- (NSUInteger)getDiskCount
{
    NSUInteger count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        count += 1;
    }
    
    return count;
}
@end
