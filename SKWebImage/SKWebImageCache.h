//
//  SKWebImageCache.h
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/15.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKWebImageCache : NSObject
+ (instancetype)sharedImageCache;
    
/**
 保存到磁盘

 @param key <#key description#>
 */
- (void)saveImage:(NSData *)data inDiskCacheWithkey:(NSString *)key completed:(void (^)(BOOL finished))completed;
/**
 保存到内存
 */
- (void)saveImage:(UIImage *)image inMemoryCacheWithkey:(NSString *)key;

/**
 从内存中获取
 */
- (void)getImageInMemoryCacheWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed;

/**
 从磁盘中获取
 */
    
- (void )getImageInDiskCacheWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed;

/**
 外部真正调用的方法

 @param key <#key description#>
 @param completed <#completed description#>
 */
- (void)getImageWithKey:(NSString *)key completed:(void(^)(UIImage *image))completed;
    
/**
 这里还需要带一个网络下载的完整data过来，因为在图片编解码的过程中，图片的文件大小会变大，应该尽量减少图片的编解码操作，我屮艸芔茻

 @param image <#image description#>
 @param data <#data description#>
 @param key <#key description#>
 @param completed <#completed description#>
 */
- (void)saveImage:(UIImage *)image imageData:(NSData *)data withKey:(NSString *)key completed:(void(^)(BOOL finish))completed;

@end

NS_ASSUME_NONNULL_END
