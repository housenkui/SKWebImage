//
//  SKImageManager.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageManager.h"
#import "SKImageCache.h"
#import "SKImageDownloader.h"
#import <objc/message.h>
@interface SKImageCombinedOperation:NSObject<SKWebImageOperation>
@property (assign,nonatomic,getter=isCancelled)BOOL cancelled;
@property (strong,nonatomic) void (^cancelBlock)(void);
@end
@implementation SKImageCombinedOperation
- (void)setCancelBlock:(void (^)(void))cancelBlock
{
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
    }
    else
    {
        _cancelBlock = cancelBlock;
    }
}

- (void)cancel
{
    self.cancelled = YES;
    if (self.cancelBlock) {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
}
@end
@interface SKImageManager ()
//@property (strong,nonatomic) SKImageCache *imageCache;
//@property (strong,nonatomic) SKImageDownloader *imageDownloader;
@property (strong,nonatomic) NSMutableArray *failedURLs;
@property (strong,nonatomic) NSMutableArray *runingOperations;
@end
@implementation SKImageManager

+ (SKImageManager *)sharedManager {
    
    static SKImageManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"onceToken = %ld",onceToken);
        instance = [SKImageManager new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init])
    {
        _imageCache = SKImageCache.new;
        _imageDownloader = SKImageDownloader.new;
        _failedURLs = NSMutableArray.new;
        _runingOperations = NSMutableArray.new;
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

- (id<SKWebImageOperation>)downloadWithURL:(NSURL *)url options:(SKWebImageOptions)options progress:(SKWebImageDownloaderProgressBlock)progressBlock completed:(SKWebImageCompletedBlock)completedBlock
{
    
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    __block SKImageCombinedOperation *operation = SKImageCombinedOperation.new;
    if (!url || !completedBlock || (!(options & SKWebImageRetryFailed) &&[self.failedURLs containsObject:url])) {
        if (completedBlock) {
            completedBlock(nil,nil,NO,NO);
            return operation;
        }
    }
    [self.runingOperations addObject:operation];
    NSString *key = [self cacheKeyForURL:url];
     NSLog(@"self.imageCache queryDiskCacheForKey:111");
    [self.imageCache queryDiskCacheForKey:key down:^(UIImage * _Nonnull image) {
        NSLog(@"self.imageCache queryDiskCacheForKey:222");
        if (operation.isCancelled) {
            return ;
        }
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completedBlock(image,nil,YES,YES);
                [self.runingOperations removeObject:operation];
            });
        }
        else
        {
            SKWebImageDownloaderOptions downloadOptions = 0;
            if (options & SKWebImageLowPriority) {
                downloadOptions |= SKWebImageDownloaderlowPriority;
            }
            if (options & SKWebImageProgressiveDownload) {
                downloadOptions |= SKWebImageDownloaderProgressiveDownload;
            }
            __block id <SKWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloadOptions progress:progressBlock completed:^(UIImage * _Nullable image, NSError * _Nullable error, BOOL finish) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completedBlock(image,error,NO,finish);
                    
                    if (error) {
                        [self.failedURLs addObject:url];
                    }
                    else if (image && finish) {
                        [self.imageCache storeImage:image forKey:key];
                    }
                    if (finish) {
                        [self.runingOperations removeObject:operation];
                    }
                });
            }];
            operation.cancelBlock = ^{
                [subOperation cancel];
            };
        }
    }];
    return  operation;
}

- (void)cancelAll
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.runingOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runingOperations removeAllObjects];
    });
}
@end
