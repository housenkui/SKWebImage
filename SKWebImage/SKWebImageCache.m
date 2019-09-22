//
//  SKWebImageCache.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/15.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface SKWebImageCache ()
@property (copy,nonatomic) NSString *savePath;
@property (strong,nonatomic) NSCache *memoryCache;
@property (strong,nonatomic) dispatch_queue_t io_queue;
@end
@implementation SKWebImageCache
    
+ (instancetype)sharedImageCache {
    static SKWebImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SKWebImageCache alloc]init];
        [instance setup];
    });
    return instance;
}
    
- (void)setup {
    self.memoryCache = [[NSCache alloc]init];

    self.io_queue = dispatch_queue_create("SKWebImage_io_Queue", DISPATCH_QUEUE_SERIAL);//自定义串行队列
    self.savePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"CacheImage"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager fileExistsAtPath:self.savePath]) {
        if(![fileManager createDirectoryAtPath:self.savePath withIntermediateDirectories:YES attributes:nil error:&error]){
            NSLog(@"文件目录创建失败,请检查设备磁盘是否已满 %@",error);
        }
    }
    NSLog(@"self.savePath = %@",self.savePath);
}
/**
 保存到磁盘
 
 @param key <#key description#>
 */

- (void)saveImage:(NSData *)data inDiskCacheWithkey:(NSString *)key completed:(void (^)(BOOL finished))completed {
    NSString * savePath = [self.savePath stringByAppendingPathComponent:[self cachedFileNameForKey:key]];
    __block BOOL finished = NO;
    dispatch_async(self.io_queue, ^{
        NSLog(@"self.io_queue saveImage  Thread = %@",[NSThread currentThread]);
        finished =  [data writeToFile:savePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            completed(finished);
        });
    });
}
    
/**
 保存到内存中的数据格式是UIImage
 
 @param key <#key description#>
 */
- (void )saveImage:(UIImage *)image inMemoryCacheWithkey:(NSString *)key {
    [self.memoryCache setObject:image forKey:[self cachedFileNameForKey:key]];
}
    
/**
 从内存中获取
 
 @param key <#key description#>
 */
- (void)getImageInMemoryCacheWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed{
    UIImage *image = [self.memoryCache objectForKey:[self cachedFileNameForKey:key]];
    completed(image);
}
    
/**
 从磁盘中获取
 @param key <#key description#>
 */
- (void)getImageInDiskCacheWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed  {
    NSString * savePath = [self.savePath stringByAppendingPathComponent:[self cachedFileNameForKey:key]];
    dispatch_async(self.io_queue, ^{
        NSData *data = [NSData dataWithContentsOfFile:savePath];
        UIImage *image = [UIImage imageWithData:data];
        NSLog(@"self.io_queue getImage  Thread = %@",[NSThread currentThread]);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                [self saveImage:image inMemoryCacheWithkey:key];   //从磁盘取出来就放到内存中去
                completed(image);
            }else{
                completed(nil);
            }
        });
    });
}
    
- (void)getImageWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed {
    [self getImageInMemoryCacheWithKey:key completed:^(UIImage * _Nonnull image) { //先查内存
        if (image) {
            completed(image);
        }else{
            [self getImageInDiskCacheWithKey:key completed:^(UIImage * _Nonnull image) {//再查磁盘
                completed(image);
            }];
        }
    }];
}




- (void)saveImage:(UIImage *)image imageData:(NSData *)imageData withKey:(NSString *)key completed:(void(^)(BOOL finish))completed {
    [self saveImage:image inMemoryCacheWithkey:key];//保存到内存中
    [self saveImage:imageData inDiskCacheWithkey:key completed:^(BOOL finished) {
        completed(finished);//YES代表保存到磁盘中成功，NO代表保存到磁盘中失败
    }];//保存到磁盘中
}

/**
 MD5加密
 X 表示以十六进制形式输出
 02 表示不足两位，前面补0输出；出过两位，不影响
 
 @param key key
 @return 加密后的数据
 */
- (nullable NSString *)cachedFileNameForKey:(nullable NSString *)key {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [key.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", key.pathExtension]];
    return filename;
}
@end
