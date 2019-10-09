//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"
#import "SKWebImageDownloaderOperation.h"
#import "SKImageDecoder.h"
#import <ImageIO/ImageIO.h>
@interface SKImageDownloader (ImageDecoder)<SKWebImageDecoderDelegate>
@end
NSString * const SKWebImageDownloadStartNotification = @"SKWebImageDownloadStartNotification";
NSString * const SKWebImageDownloadStopNotification = @"SKWebImageDownloadStopNotification";

NSString * const kProgressCallbackKey = @"progress";
NSString * const kCompletedCallbackKey = @"completed";

@interface SKImageDownloader ()
@property (strong,nonatomic) NSOperationQueue *downloadQueue;
@property (strong,nonatomic) NSMutableDictionary *URLCallbacks;
@end
@implementation SKImageDownloader

+ (void)initialize
{
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop
        
        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SKWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SKWebImageDownloadStopNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SKWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SKWebImageDownloadStopNotification object:nil];
    }
}
+ (SKImageDownloader *)sharedDownloader
{
    static SKImageDownloader * instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [SKImageDownloader new];
    });
    return instance;
}
- (instancetype)init
{
    if (self = [super init]) {
        _downloadQueue = NSOperationQueue.new;
        _downloadQueue.maxConcurrentOperationCount = 10;
        _URLCallbacks = NSMutableDictionary.new;
    }
    return self;
}

- (void)setMaxConcurrentDownloaders:(NSInteger)maxConcurrentDownloaders
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloaders;
}
- (NSInteger)maxConcurrentDownloaders
{
    return _downloadQueue.maxConcurrentOperationCount;
}

- (id <SKWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SKWebImageDownloaderOptions)options
                                        progress:(SKWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SKWebImageDownloaderCompletedBlock)completedBlock
{
    __block SKWebImageDownloaderOperation *operation;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL performDownload = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = NSMutableArray.new;
            performDownload = YES;
        }
        //Handle single download of simultaneous(同步的) download request for the same URL
        {
            NSMutableArray *callbacksForURL = self.URLCallbacks[url];
            NSMutableDictionary *callbacks = NSMutableDictionary.new;
            if (progressBlock) {
                callbacks[kProgressCallbackKey] = progressBlock;
            }
            if (completedBlock) {
                callbacks[kCompletedCallbackKey] = completedBlock;
            }
            [callbacksForURL addObject:callbacks];
            self.URLCallbacks[url] = callbacksForURL;
        }
        if (performDownload) {
//            NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
            NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15];
            request.HTTPShouldHandleCookies = NO;
            request.HTTPShouldUsePipelining = YES;
            [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

            operation = [SKWebImageDownloaderOperation.alloc initWithRequest:request options:options progress:^(NSUInteger receiveSize, long long expectedSize) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *callbacksForURL = self.URLCallbacks[url];
                    for (NSDictionary *callbacks in callbacksForURL) {
                        SKWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                        if (callback) {
                            callback(receiveSize,expectedSize);
                        }
                    }
                });
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, BOOL finish) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *callbacksForURL = self.URLCallbacks[url];
                    [self.URLCallbacks removeObjectForKey:url];
                    for (NSDictionary *callbacks in callbacksForURL) {
                        SKWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                        if (callback) {
                            callback(image,error,finish);
                        }
                    }
                });
            }];
            [self.downloadQueue addOperation:operation];
        }
    });
    
    return operation;
}

@end
