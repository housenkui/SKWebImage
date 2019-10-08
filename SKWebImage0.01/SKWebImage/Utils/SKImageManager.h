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
typedef void(^SKWebImageSuccessBlock)(UIImage *image,BOOL cached);
typedef void(^SKWebImageFailureBlock)(NSError *error);

typedef NSString *_Nullable(^CacheKeyFilter)(NSURL *url);
/**
 * The SKWebImageManager is the class behind the UIImageView+WebCache category and likes.
 * It ties the asynchronous downloader (SKWebImageDownloader) with the image cache store (SKImageCache).
 * You can use this class directly to benefit from web image downloading with caching in another context than
 * a UIView.
 *
 * Here is a simple example of how to use SKWebImageManager:
 *
 *  SKWebImageManager *manager = [SKWebImageManager sharedManager];
 *  [manager downloadWithURL:imageURL
 *                  delegate:self
 *                   options:0
 *                   success:^(UIImage *image,BOOL cached)
 *                   {
 *                       // do something with image
 *                   }
 *                   failure:nil];
 */

@interface SKImageManager : NSObject<SKImageDownloaderDelegate,SKImageCacheDelegate>
{
    NSMutableArray *downloadInfo;
    NSMutableArray *downloadDelegates;
    NSMutableArray *downloaders;
    NSMutableArray *cacheDelegates;
    NSMutableArray *cacheURLs;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}

/**
 * The cache filter is a block used each time SKWebManager need to convert an URL into a cache key. This can
 * be used to remove dynamic part of an image URL.
 *
 * The following example sets a filter in the application delegate that will remove any query-string from the
 * URL before to use it as a cache key:
 *
 *     [[SKWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url)
 *    {
 *        url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
 *        return [url absoluteString];
 *    }];
 */

@property (nonatomic,copy) CacheKeyFilter cacheKeyFilter;
/**
 * Returns global SKWebImageManager instance.
 *
 * @return SKWebImageManager shared instance
 */
+ (SKImageManager *)sharedManager;

- (UIImage *)imageWithURL:(NSURL *)url __attribute__ ((deprecated));

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @see [SKWebImageManager downloadWithURL:delegate:options:]
 * @see [SKWebImageManager downloadWithURL:delegate:options:success:failure:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate;

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @see [SKWebImageManager downloadWithURL:delegate:options:success:failure:]
 */

- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate options:(SKWebImageOptions)options;

// use options:SKWebImageRetryFailed instead
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed __attribute__ ((deprecated));
// use options:SKWebImageRetryFailed|SKWebImageLowPriority instead
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority __attribute__ ((deprecated));

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @param success A block called when image has been retrived successfuly
 * @param failure A block called when couldn't be retrived for some reason
 * @see [SKWebImageManager downloadWithURL:delegate:options:]
 */
- (void)downloadWithURL:(NSURL *)url
               delegate:(id<SKWebImageManagerDelegate>)delegate
                options:(SKWebImageOptions)options
                success:(SKWebImageSuccessBlock)success
                failure:(SKWebImageFailureBlock)failure;

/**
 * Cancel all pending download requests for a given delegate
 *
 * @param delegate The delegate to cancel requests for
 */

- (void)cancelForDelegate:(id <SKWebImageManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
