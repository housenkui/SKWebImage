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
const char *kDiskIOQueueName = "com.github.SKWebImageDiskCache";
static NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 7 days

@interface SKImageCache ()
@property (strong,nonatomic) NSCache *memCache;
@property (copy,nonatomic) NSString *diskCachePath;
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
        dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
        dispatch_async(queue, ^{
            NSData *data = imageData;
            if (!data) {
                if (image) {
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
            }
            if (data)
            {
                if (![[NSFileManager defaultManager]fileExistsAtPath:self->_diskCachePath]) {
                    [[NSFileManager defaultManager]createDirectoryAtPath:self->_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
                NSString *path = [self cachePathForKey:key];
                dispatch_io_t ioChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, [path UTF8String], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH, queue, nil);
                dispatch_data_t dispatchData = dispatch_data_create(data.bytes, data.length, queue, ^{[data self];});
                
                dispatch_io_write(ioChannel, 0, dispatchData, queue, ^(bool done, dispatch_data_t  _Nullable data, int error) {
                    if (error != 0) {
                        NSLog(@"SKWebImageCache:Error writing image from disk cache:error = %d",error);
                    }
                    if (done) {
                        dispatch_io_close(ioChannel, 0);
                    }
                });
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

- (void)queryDiskCacheForKey:(NSString *)key down:(nonnull void (^)(UIImage * image ))downBlock
{
    if (!downBlock) return;
    
    if (!key)
    {
        downBlock(nil);
        return;
    }
    //First check the in-memory cache...
    UIImage *image = [self.memCache objectForKey:key];
    if (image) {
        downBlock(image);
        return;
    }
    NSString *path = [self cachePathForKey:key];
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_io_t ioChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, path.UTF8String, O_RDONLY, 0, queue, nil);
    dispatch_io_read(ioChannel, 0, SIZE_MAX, queue, ^(bool done, dispatch_data_t  _Nullable data, int error) {
        if (error) {
            if (error != 2) {
                NSLog(@"SKWebImageCache:Error reading image from disk cache:error = %d",error);
            }
            downBlock(nil);
            return ;
        }
        
        dispatch_data_apply(data, ^bool(dispatch_data_t  _Nonnull region, size_t offset, const void * _Nonnull buffer, size_t size) {
            UIImage *diskImage = SKScaledImageForPath(key, [NSData dataWithBytes:buffer length:size]);
            if (diskImage) {
                UIImage *decodedImage = [UIImage decodedImageWithImage:diskImage];
                if (decodedImage) {
                    diskImage = decodedImage;
                }
                [self.memCache setObject:diskImage forKey:key cost:image.size.height * image.size.width *image.scale];
            }
            NSLog(@"dispatch_data_apply");
            downBlock(diskImage);
            return true;
        });
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
        dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
        dispatch_async(queue, ^{
            [[NSFileManager defaultManager]removeItemAtPath:[self cachePathForKey:key] error:nil];
        });
    }
}


- (void)clearMemory {
    [self.memCache removeAllObjects];
}
- (void)clearDisk {
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_async(queue, ^{
        [[NSFileManager defaultManager]removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager]createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    });
}
#pragma mark ---清除一周内没有使用的图片
- (void)cleanDisk {
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_async(queue, ^{
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
