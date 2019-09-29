//
//  UIImageView+WebCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//


#import "SKWebImageCompat.h"
#import "SKWebImageManagerDelegate.h"
#import "SKImageManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WebCache) <SKWebImageManagerDelegate>

/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the image is found.
 * @see setImageWithURL:placeholderImage:
 */

- (void)setImageWithURL:(NSURL *)url;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @see setImageWithURL:placeholderImage:options:
 */

- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder;
/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @param options A list of `SDWebImageOptions` for current `imageView`. Available options are `SDWebImageRetryFailed`, `SDWebImageLowPriority` and `SDWebImageCacheMemoryOnly`.
 */

- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SKWebImageOptions)options;


/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 *@param url The url for the image.
 *@param success A block to be executed when the image request succeed This block has no return value and takes the retrieved image as argument.
 *@param failure  A block object to be executed when the image request failed. This block has no return value and takes the error object describing the network or parsing error that occurred (may be nil).
 */
- (void)setImageWithURL:(NSURL *)url
                success:(void (^)(UIImage * image))success
                failure:(void (^)(NSError *error))failure;

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(nullable UIImage *)placeholder
                success:(void (^)(UIImage * image))success
                failure:(void (^)(NSError *error))failure;

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(nullable UIImage *)placeholder
                options:(SKWebImageOptions)options
                success:(void (^)(UIImage * image))success
                failure:(void (^)(NSError *error))failure;;


/**
 * Cancel the current download
 */
- (void)cancelCurrentImageLoad;
@end

NS_ASSUME_NONNULL_END
