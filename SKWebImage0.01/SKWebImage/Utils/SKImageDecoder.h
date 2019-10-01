//
//  SKImageDecoder.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/28.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@protocol SKWebImageDecoderDelegate;
/**
 * Decoding image data is the most expensive step, and it is performed on the main thread. SDWebImageDecoder force the
 * image decoding in a separate thread so UIImage will have high chance to reuse the cached result when used by UI in
 * the main thread.
 *
 */

@interface SKImageDecoder : NSObject
{
    NSOperationQueue *imageDecodingQueue;
}
/**
 * Returns a shared global instance of image decoder
 *
 * @return An SDWebImageDecoder shared instance
 */
+ (SKImageDecoder *)sharedImageDecoder;

/**
 * Pre-decode a given image in a separate thread.
 *
 * @param image The image to pre-decode
 * @param delegate The object to notify once pre-decoding is completed
 * @param userInfo A user info object
 */
- (void)decodeImage:(UIImage *)image withDelegate:(id <SKWebImageDecoderDelegate>) delegate userInfo:(nullable NSDictionary *)userInfo;
@end
/**
 * Delegate protocol for SDWebImageDecoder
 */
@protocol SKWebImageDecoderDelegate <NSObject>
/**
 * Called when pre-decoding is completed
 *
 * @param decoder The image decoder instance
 * @param image The pre-decoded image
 * @param userInfo the provided user info dictionary
 */
- (void)imageDecoder:(SKImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(nullable NSDictionary *)userInfo;

@end
@interface UIImage (ForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image;

@end
NS_ASSUME_NONNULL_END
