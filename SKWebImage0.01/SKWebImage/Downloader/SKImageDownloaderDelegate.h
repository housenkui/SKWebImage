//
//  SKImageDownloaderDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKWebImageCompat.h"
NS_ASSUME_NONNULL_BEGIN
@class SKImageDownloader;
/**
 * Delegate protocol for SKWebImageDownloader
 */
@protocol SKImageDownloaderDelegate <NSObject>
@optional

- (void)imageDownloaderDidFinish:(SKImageDownloader *)downloader;

/**
 * Called repeatedly while the image is downloading when [SKWebImageDownloader progressive] is enabled.
 *
 * @param downloader The SKWebImageDownloader instance
 * @param image The partial image representing the currently download portion of the image
 */
- (void)imageDownloader:(SKImageDownloader *)downloader didUpdatePartialImage:(UIImage *)image;

/**
 * Called when download completed successfuly.
 *
 * @param downloader The SKWebImageDownloader instance
 * @param image The downloaded image object
 */
- (void)imageDownloader:(SKImageDownloader *)downloader didFinishWithImage:(UIImage *)image;

/**
 * Called when an error occurred
 *
 * @param downloader The SKWebImageDownloader instance
 * @param error The error details
 */

- (void)imageDownloader:(SKImageDownloader *)downloader didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
