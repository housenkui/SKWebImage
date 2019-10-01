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
typedef enum
{
    SKWebImageRetryFailed = 1 << 0,
    SKWebImageLowPriority = 1 << 1,
    SKWebImageCacheMemoryOnly = 1 << 2,
    SKWebImageProgressiveDownload = 1 << 3

}SKWebImageOptions;
typedef NSString *_Nullable(^CacheKeyFilter)(NSURL *url);
@interface SKImageManager : NSObject<SKImageDownloaderDelegate,SKImageCacheDelegate>
{
    NSMutableArray *downloadDelegates;
    NSMutableArray *downloaders;
    NSMutableArray *cacheDelegates;
    NSMutableArray *cacheURLs;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}

@property (nonatomic,copy) CacheKeyFilter cacheKeyFilter;
+ (SKImageManager *)sharedManager;
- (UIImage *)imageWithURL:(NSURL *)url;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate;
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate options:(SKWebImageOptions)options;

- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed __attribute__ ((deprecated));
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority __attribute__ ((deprecated));;

- (void)downloadWithURL:(NSURL *)url
               delegate:(id<SKWebImageManagerDelegate>)delegate
                options:(SKWebImageOptions)options
                success:(void (^)(UIImage * image))success
                failure:(void (^)(NSError *error))failure;

- (void)cancelForDelegate:(id <SKWebImageManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END