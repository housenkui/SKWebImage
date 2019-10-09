/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import <objc/message.h>

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (strong, nonatomic) void (^cancelBlock)(void);

@end

@interface SDWebImageManager ()

@property (strong, nonatomic, readwrite) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSMutableArray *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation SDWebImageManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    if ((self = [super init]))
    {
        _imageCache = SDImageCache.new;
        _imageDownloader = SDWebImageDownloader.new;
        _failedURLs = NSMutableArray.new;
        _runningOperations = NSMutableArray.new;
    }
    return self;
}


- (NSString *)cacheKeyForURL:(NSURL *)url
{
    if (self.cacheKeyFilter)
    {
        return self.cacheKeyFilter(url);
    }
    else
    {
        return [url absoluteString];
    }
}

- (id<SDWebImageOperation>)downloadWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock
{    
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }

    __block SDWebImageCombinedOperation *operation = SDWebImageCombinedOperation.new;
    
    if (!url || !completedBlock || (!(options & SDWebImageRetryFailed) && [self.failedURLs containsObject:url]))
    {
        if (completedBlock) completedBlock(nil, nil, NO);
        return operation;
    }

    [self.runningOperations addObject:operation];
    NSString *key = [self cacheKeyForURL:url];

    [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image)
    {
        if (operation.isCancelled) return;

        if (image)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                completedBlock(image, nil, YES);
                [self.runningOperations removeObject:operation];
            });
        }
        else
        {
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            id<SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSError *error, BOOL finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (error)
                    {
                        [self.failedURLs addObject:url];
                    }
                    completedBlock(downloadedImage, error, NO);
                    [self.runningOperations removeObject:operation];
                    if (downloadedImage)
                    {
                        [self.imageCache storeImage:downloadedImage forKey:key];
                    }
                });
            }];
            operation.cancelBlock = ^{[subOperation cancel];};
        }
    }];

    return operation;
}

- (void)cancelAll
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.runningOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeAllObjects];
    });
}

@end

@implementation SDWebImageCombinedOperation

- (void)setCancelBlock:(void (^)(void))cancelBlock
{
    if (self.isCancelled)
    {
        if (cancelBlock) cancelBlock();
    }
    else
    {
        _cancelBlock = cancelBlock;
    }
}

- (void)cancel
{
    self.cancelled = YES;
    if (self.cancelBlock)
    {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
}

@end
