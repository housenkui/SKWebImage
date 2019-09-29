//
//  UIButton+WebCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/28.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKWebImageCompat.h"
#import "SKWebImageManagerDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface UIButton (WebCache)<SKWebImageManagerDelegate>

/**
 * Set the imageView 'image' with an 'url'
 * The download is asynchronous and cached.
 @param url The url that the image is found.
 */
- (void)setImageWithURL:(NSURL *)url;

/**
 * Set the imageView 'image' with an 'url' and a placeholder.
 * The download is asynchronous and cached.

 @param url The url that the image is found.
 @param placeholder A `image` that will be visible while loading hte final image.
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder;

/**
 * Cancel the current download
 */
- (void)cancelCurrentImageLoad;
@end

NS_ASSUME_NONNULL_END
