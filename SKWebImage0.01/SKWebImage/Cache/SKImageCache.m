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
static NSInteger cacheMaxCacheAge = 60 * 60 * 24 * 7; // 7 days
@implementation SKImageCache

- (instancetype)init {
    if (self = [super init]) {
        //Init the memory cache
        memCache = [[NSMutableDictionary alloc]init];
        
        //Init the disk cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        diskCachePath = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"SKImageCache"];
        if (![[NSFileManager defaultManager]fileExistsAtPath:diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSLog(@"diskCachePath = %@",diskCachePath);
        //Init the operation queue
        cacheInQueue = [[NSOperationQueue alloc]init];
        cacheInQueue.maxConcurrentOperationCount = 1;
        cacheOutQueue = [[NSOperationQueue alloc]init];
        cacheOutQueue.maxConcurrentOperationCount = 1;
#if !TARGET_OS_IPHONE
        //Subscribe to app events
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(clearMemory)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(cleanDisk)
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(clearMemory)
                                                        name:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
        }
#endif
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
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [diskCachePath stringByAppendingPathComponent:filename];
}
#pragma mark --存储到硬盘中
- (void)storeKeyWithDataToDisk:(NSArray *)keyAndData {
    
    //Can't use defaultManager another thread
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    
    NSString *key = [keyAndData objectAtIndex:0];
    NSData *data = [keyAndData count] > 1 ? [keyAndData objectAtIndex:1]:nil;
    
    if (data) {
        [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
    }
    else{
        //If no data representation given,convert the UIImage in JPEG and store it
        //This trick is more CPU/memory intensive and doesn't preserve alpha channel
        UIImage *image = [self imageFromKey:key fromDisk:YES];
        if (image) {
#if TARGET_OS_IPHONE
            [fileManager createFileAtPath:[self cachePathForKey:key] contents:UIImageJPEGRepresentation(image, (CGFloat)1.0) attributes:nil];
#else
            NSArray*  representations  = [image representations];
            NSData* jpegData = [NSBitmapImageRep representationOfImageRepsInArray: representations usingType: NSJPEGFileType properties:nil];
            [fileManager createFileAtPath:[self cachePathForKey:key] contents:jpegData attributes:nil];

#endif
        }
    }
}
- (void)notifyDelegate:(NSDictionary *)arguments
{
    NSString *key = [arguments objectForKey:@"key"];
    id <SKImageCacheDelegate> delegate = [arguments objectForKey:@"delegate"];
    NSDictionary *info = [arguments objectForKey:@"userInfo"];
    UIImage *image = [arguments objectForKey:@"image"];
    if (image)
    {
        [memCache setObject:image forKey:key];
        if ([delegate respondsToSelector:@selector(imageCache:didFindImage:forKey:userInfo:)]) {
            [delegate imageCache:self didFindImage:image forKey:key userInfo:info];
        }
    }
    else
    {
        if ([delegate respondsToSelector:@selector(imageCache:didNotFindImageForKey:userInfo:)])
        {
            [delegate imageCache:self didNotFindImageForKey:key userInfo:info];
        }
    }
}
- (void)queryDiskCacheOperation:(NSDictionary *)arguments
{
    NSString *key = [arguments objectForKey:@"key"];
    NSMutableDictionary *mutableArguments = [arguments mutableCopy];
    //先以你 哼  这行代码
    UIImage *image = SKScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]]);
//    UIImage *image = [UIImage imageWithContentsOfFile:[self cachePathForKey:key]];

    if (image) {
        UIImage *decodedImage = [UIImage decodedImageWithImage:image];
        if (decodedImage) {
            image = decodedImage;
        }
        [mutableArguments setObject:image forKey:@"image"];
    }
    [self performSelectorOnMainThread:@selector(notifyDelegate:) withObject:mutableArguments waitUntilDone:NO];
}

#pragma mark --ImageCache
- (void)storeImage:(UIImage *)image forKey:(NSString *)key imageData:(nullable NSData *)data toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    [memCache setObject:image forKey:key];
    if (toDisk)
    {
        NSArray *keyWithData;
        if (data)
        {
            keyWithData = [NSArray arrayWithObjects:key,data, nil];
        }
        else
        {
            keyWithData = [NSArray arrayWithObjects:key, nil];
        }
        NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(storeKeyWithDataToDisk:) object:keyWithData];
        [cacheInQueue addOperation:invocationOperation];
        
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image forKey:key imageData:nil toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image forKey:key imageData:nil toDisk:toDisk];
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
        image = SKScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]]);
        if (image) {
            [memCache setObject:image forKey:key];
        }
    }
    return image;
}
- (void)queryDiskCacheForKey:(NSString *)key delegate:(id<SKImageCacheDelegate>)delegate userInfo:(NSDictionary *)info
{
    if (!delegate) {
        return;
    }
    if (!key) {
        if ([delegate respondsToSelector:@selector(imageCache:didNotFindImageForKey:userInfo:)]) {
            [delegate imageCache:self didNotFindImageForKey:key userInfo:info];
        }
        return;
    }
    //First check the in-memory cache...
    UIImage *image = [memCache objectForKey:key];
    if (image) {
        
        //...notify delegate immediately,no need to go async
        if ([delegate respondsToSelector:@selector(imageCache:didFindImage:forKey:userInfo:)]) {
            [delegate imageCache:self didFindImage:image forKey:key userInfo:info];
        }
        return;
    }
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithCapacity:3];
    [arguments setObject:key forKey:@"key"];
    [arguments setObject:delegate forKey:@"delegate"];
    if (info) {
        [arguments setObject:info forKey:@"userInfo"];
    }
    
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(queryDiskCacheOperation:) object:arguments];
    [cacheOutQueue addOperation:invocationOperation];
    
}
- (void)removeImageForKey:(NSString *)key {
    [self removeImageForKey:key fromDisk:YES];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    if (!key) {
        return;
    }
    [memCache removeObjectForKey:key];
    if (fromDisk) {
        [[NSFileManager defaultManager]removeItemAtPath:[self cachePathForKey:key] error:nil];
    }
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

- (unsigned long long)getSize
{
    int size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager]enumeratorAtPath:diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager]attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}
@end