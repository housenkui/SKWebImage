//
//  SKImageCacheDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/27.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageCompat.h"
NS_ASSUME_NONNULL_BEGIN
@class SKImageCache;
/**
 * Delegate protocol for SDImageCache
 */
@protocol SKImageCacheDelegate <NSObject>
@optional
/**
 * Called when [SDImageCache queryDiskCacheForKey:delegate:userInfo:] retrived the image from cache
 *
 * @param imageCache The cache store instance
 * @param image The requested image instance
 * @param key The requested image cache key
 * @param info The provided user info dictionary
 */
- (void)imageCache:(SKImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info;

/**
 * Called when [SDImageCache queryDiskCacheForKey:delegate:userInfo:] did not find the image in the cache
 *
 * @param imageCache The cache store instance
 * @param key The requested image cache key
 * @param info The provided user info dictionary
 */
- (void)imageCache:(SKImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
