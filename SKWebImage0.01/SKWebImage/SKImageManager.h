//
//  SKImageManager.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKWebImageCompat.h"
#import "SKWebImageManagerDelegate.h"
#import "SKImageDownloaderDelegate.h"
#import "SKImageCacheDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface SKImageManager : NSObject<SKImageDownloaderDelegate,SKImageCacheDelegate>
{
    NSMutableArray *downloadDelegates;
    NSMutableArray *downloaders;
    NSMutableArray *cacheDelegates;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}
+ (SKImageManager *)sharedManager;
- (UIImage *)imageWithURL:(NSURL *)url;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority;

- (void)cancelForDelegate:(id <SKWebImageManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
