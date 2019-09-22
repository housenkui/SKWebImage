//
//  SKImageManager.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SKWebImageManagerDelegate.h"
#import "SKImageDownloaderDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface SKImageManager : NSObject<SKImageDownloaderDelegate>
{
    NSMutableArray *delegates;
    NSMutableArray *downloaders;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}
+ (SKImageManager *)sharedManager;
- (UIImage *)imageWithURL:(NSURL *)url;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate;
- (void)cancelForDelegate:(id <SKWebImageManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END