/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";

NSString *const kProgressCallbackKey = @"completed";
NSString *const kCompletedCallbackKey = @"completed";

@interface SDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
@property (strong, nonatomic) dispatch_queue_t barrierQueue;

@end

@implementation SDWebImageDownloader

+ (void)initialize
{
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }
}

+ (SDWebImageDownloader *)sharedDownloader
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
        _downloadQueue = NSOperationQueue.new;
        _downloadQueue.maxConcurrentOperationCount = 10;
        _URLCallbacks = NSMutableDictionary.new;
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSInteger)maxConcurrentDownloads
{
    return _downloadQueue.maxConcurrentOperationCount;
}

- (NSOperation *)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(void (^)(NSUInteger, long long))progressBlock completed:(void (^)(UIImage *, NSError *, BOOL))completedBlock
{
    __block SDWebImageDownloaderOperation *operation;
    __weak SDWebImageDownloader *wself = self;

    [self addProgressCallback:progressBlock andCompletedBlock:completedBlock forURL:url createCallback:^
    {
        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
        NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPShouldUsePipelining = YES;
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        operation = [SDWebImageDownloaderOperation.alloc initWithRequest:request options:options progress:^(NSUInteger receivedSize, long long expectedSize)
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            NSArray *callbacksForURL = [sself removeAndReturnCallbacksForURL:url];
            for (NSDictionary *callbacks in callbacksForURL)
            {
                SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                if (callback) callback(receivedSize, expectedSize);
            }
        }
        completed:^(UIImage *image, NSError *error, BOOL finished)
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            NSArray *callbacksForURL = [sself removeAndReturnCallbacksForURL:url];
            for (NSDictionary *callbacks in callbacksForURL)
            {
                SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                if (callback) callback(image, error, finished);
            }
        }
        cancelled:^
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            [sself removeAndReturnCallbacksForURL:url];
        }];
        [self.downloadQueue addOperation:operation];
    }];


    return operation;
}

- (void)addProgressCallback:(void (^)(NSUInteger, long long))progressBlock andCompletedBlock:(void (^)(UIImage *, NSError *, BOOL))completedBlock forURL:(NSURL *)url createCallback:(void (^)(void))createCallback
{
    dispatch_barrier_async(self.barrierQueue, ^
    {
        BOOL first = NO;
        if (!self.URLCallbacks[url])
        {
            self.URLCallbacks[url] = NSMutableArray.new;
            first = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = NSMutableDictionary.new;
        if (progressBlock) callbacks[kProgressCallbackKey] = progressBlock;
        if (completedBlock) callbacks[kCompletedCallbackKey] = completedBlock;
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;

        if (first)
        {
            createCallback();
        }
    });
}

- (NSArray *)removeAndReturnCallbacksForURL:(NSURL *)url
{
    __block NSArray *callbacksForURL;
    dispatch_barrier_sync(self.barrierQueue, ^
    {
        callbacksForURL = self.URLCallbacks[url];
        [self.URLCallbacks removeObjectForKey:url];
    });
    return callbacksForURL;
}

@end
