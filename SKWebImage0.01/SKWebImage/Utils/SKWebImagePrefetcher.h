//
//  SKWebImagePrefetcher.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/29.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKWebImageManagerDelegate.h"
#import "SKImageManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface SKWebImagePrefetcher : NSObject<SKWebImageManagerDelegate>
{
    NSArray *_prefetchURLs;
    NSUInteger _skippedCount;
    NSUInteger _finishedCount;
    NSUInteger _requestedCount;
    NSTimeInterval _startedTime;
}

/**
 * Maximum number of URLs to prefetch at the same time.Defaults to 3.
 */
@property (assign,nonatomic)NSUInteger maxConcurrentDownloader;
@property (assign,nonatomic)SKWebImageOptions options;
+ (SKWebImagePrefetcher *)sharedImagePrefetcher;

/**
 * Assign list of URLs to let SKWebImagePrefetcher to queue the prefetching,
 * currently one image is downloaded at the time,
 * and skips images for failed downloads and proceed to image in the list

 @param urls list of URLs to prefetch
 */
- (void)prefetchURLs:(NSArray *)urls;


/**
 * Remove and cancel queued list
 */
- (void)cancelPrefetching;
@end

NS_ASSUME_NONNULL_END
