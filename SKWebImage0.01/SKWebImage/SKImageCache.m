//
//  SKImageCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageCache.h"
#import <CommonCrypto/CommonDigest.h>
static NSInteger cacheMaxCacheAge = 60 * 60 * 24 * 7; // 7 days
@implementation SKImageCache

- (instancetype)init {
    if (self = [super init]) {
        //Init the memory cache
        memCache = [[NSMutableDictionary alloc]init];
        
        //Init the disk cache
        storeDataQueue = [[NSMutableDictionary alloc]init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        diskCachePath = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"SKImageCache"];
        if (![[NSFileManager defaultManager]fileExistsAtPath:diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSLog(@"diskCachePath = %@",diskCachePath);
        //Init the operation queue
        cacheInQueue = [[NSOperationQueue alloc]init];
        cacheInQueue.maxConcurrentOperationCount = 2;
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(clearMemory)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(cleanDisk)
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
#ifdef __IPHONE_4_0
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(clearMemory)
                                                        name:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
        }
#endif
    }
    return self;
}
#pragma mark SKImageCache (class methods)
+ (SKImageCache *)sharedImageCache {
    static SKImageCache *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SKImageCache alloc]init];
    });
    return instance;
}
#pragma mark SKImageCache (private)
- (NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (unsigned int)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [diskCachePath stringByAppendingPathComponent:filename];
}
#pragma mark --存储到硬盘中
- (void)storeKeyToDisk:(NSString *)key {
    
    //Can't use defaultManager another thread
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSData *data = [storeDataQueue objectForKey:key];
    if (data) {
        [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
        @synchronized (storeDataQueue)
        {
            [storeDataQueue removeObjectForKey:key];
        }
    }
    else{
        //If no data representation given,convert the UIImage in JPEG and store it
        //This trick is more CPU/memory intensive and doesn't preserve alpha channel
        UIImage *image = [self imageFromKey:key fromDisk:YES];
        if (image) {
            [[NSFileManager defaultManager]createFileAtPath:[self cachePathForKey:key] contents:UIImageJPEGRepresentation(image, (CGFloat)1.0) attributes:nil];
        }
    }
}
- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    if (toDisk && !data) {
        return;
    }
    [memCache setObject:image forKey:key];
    if (toDisk) {
        [storeDataQueue setObject:data forKey:key];
        NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(storeKeyToDisk:) object:key];
        [cacheInQueue addOperation:invocationOperation];
        
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk];
}
- (UIImage *)imageFromKey:(NSString *)key
{
  return  [self imageFromKey:key fromDisk:YES];
}

- (UIImage *)imageFromKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    if (!key) {
        return nil;
    }
    UIImage *image = [memCache objectForKey:key];
    if (!image && fromDisk) {
        image = [UIImage imageWithContentsOfFile:[self cachePathForKey:key]];
        if (image) {
            [memCache setObject:image forKey:key];
        }
    }
    return image;
}

- (void)removeImageForKey:(NSString *)key {
    if (!key) {
        return;
    }
    [memCache removeObjectForKey:key];
    [[NSFileManager defaultManager]removeItemAtPath:[self cachePathForKey:key] error:nil];
}

- (void)clearMemory {
    [cacheInQueue cancelAllOperations];
    [memCache removeAllObjects];
}
- (void)clearDisk {
    [cacheInQueue cancelAllOperations];
    [[NSFileManager defaultManager]removeItemAtPath:diskCachePath error:nil];
    [[NSFileManager defaultManager]createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
}
#pragma mark ---清除一周内没有使用的图片
- (void)cleanDisk {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-cacheMaxCacheAge];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:diskCachePath];
    
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager]attributesOfItemAtPath:filePath error:nil];
        if ([[[attrs fileModificationDate]laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
        }
    }
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
