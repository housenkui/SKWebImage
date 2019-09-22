//
//  SKImageDownloaderDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SKImageDownloader;
@protocol SKImageDownloaderDelegate <NSObject>
@optional
- (void)imageDownloader:(SKImageDownloader *)downloader didFinishWithImage:(UIImage *)image;
- (void)imageDownloader:(SKImageDownloader *)downloader didFailWithError:(NSError *)error;
@end

NS_ASSUME_NONNULL_END
