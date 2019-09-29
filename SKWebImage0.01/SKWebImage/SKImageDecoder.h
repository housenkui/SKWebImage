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

@interface SKImageDecoder : NSObject
{
    NSOperationQueue *imageDecodingQueue;
}
+ (SKImageDecoder *)sharedImageDecoder;
- (void)decodeImage:(UIImage *)image withDelegate:(id <SKWebImageDecoderDelegate>) delegate userInfo:(nullable NSDictionary *)userInfo;
@end
@protocol SKWebImageDecoderDelegate <NSObject>

- (void)imageDecoder:(SKImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(nullable NSDictionary *)userInfo;

@end
@interface UIImage (ForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image;

@end
NS_ASSUME_NONNULL_END
