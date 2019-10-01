//
//  SKWebImageManagerDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;
NS_ASSUME_NONNULL_BEGIN
@class SKImageManager;
/**
 * Delegate protocol for SKWebImageManager
 */

@protocol SKWebImageManagerDelegate <NSObject>
@optional
/**
 * Called while an image is downloading with an partial image object representing the currently downloaded portion of the image.
 * This delegate is called only if ImageIO is available and `SKWebImageProgressiveDownload` option has been used.
 *
 * @param imageManager The image manager
 * @param image The retrived image object
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SKImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info;

- (void)webImageManager:(SKImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url;

/**
 * Called when image download is completed successfuly.
 *
 * @param imageManager The image manager
 * @param image The retrived image object
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SKImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info;
- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url;
- (void)webImageManager:(SKImageManager *)imageManager didFinishWithImage:(UIImage *)image;

/**
 * Called when an error occurred.
 *
 * @param imageManager The image manager
 * @param error The error
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SKImageManager *)imageManager didFailWithError:(NSError *)error forURL:(NSURL *)url userInfo:(NSDictionary *)info;
- (void)webImageManager:(SKImageManager *)imagerManager didFailWithError:(NSError *)error forURL:(NSURL *)url;
- (void)webImageManager:(SKImageManager *)imageManager didFailWithError:(NSError *)error;


@end

NS_ASSUME_NONNULL_END
