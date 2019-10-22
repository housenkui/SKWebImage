//
//  SKImageManager.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKWebImageCompat.h"
#import "SKWebImageOperation.h"
#import "SKImageDownloader.h"
#import "SKImageCache.h"
NS_ASSUME_NONNULL_BEGIN
typedef enum
{
    SKWebImageRetryFailed = 1 << 0,
    SKWebImageLowPriority = 1 << 1,
    SKWebImageCacheMemoryOnly = 1 << 2,
    SKWebImageProgressiveDownload = 1 << 3

}SKWebImageOptions;

typedef void(^SKWebImageCompletedBlock)(UIImage *image,NSError *error,BOOL fromCache,BOOL finished);

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

@interface SKImageManager : NSObject
@property (strong,nonatomic) SKImageCache *imageCache;
@property (strong,nonatomic) SKImageDownloader *imageDownloader;
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

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param options A mask to specify options to use for this request
 * @param progressBlock A block called while image is downloading
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 * @return Return a cancellable NSOperation
 */
- (id<SKWebImageOperation>)downloadWithURL:(NSURL *)url
                options:(SKWebImageOptions)options
               progress:(SKWebImageDownloaderProgressBlock)progressBlock
              completed:(SKWebImageCompletedBlock)completedBlock;

/**
 * Cancel all pending download requests for a given delegate
 *
 * @param delegate The delegate to cancel requests for
 */


/**
 Cancel all current operations
 */
- (void)cancelAll;
@end

NS_ASSUME_NONNULL_END
