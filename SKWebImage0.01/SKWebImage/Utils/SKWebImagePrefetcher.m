//
//  SKWebImagePrefetcher.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/29.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImagePrefetcher.h"
#import "SKImageManager.h"
@interface SKWebImagePrefetcher ()
@property (strong,nonatomic) NSArray *prefetchURLs;
@end
@implementation SKWebImagePrefetcher
@synthesize prefetchURLs,maxConcurrentDownloader,options;

+ (SKWebImagePrefetcher *)sharedImagePrefetcher
{
    static SKWebImagePrefetcher * instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [SKWebImagePrefetcher new];
        instance.maxConcurrentDownloader = 3;
        instance.options = SKWebImageLowPriority;
    });
    return instance;
}

- (void)startPrefetchingAtIndex:(NSUInteger)index withManager:(SKImageManager *)imageManager
{
    if (index >= [self.prefetchURLs count]) {
        return;
    }
    _requestedCount ++;
    [imageManager downloadWithURL:[self.prefetchURLs objectAtIndex:index] delegate:self options:self.options];
}

- (void)reportStatus
{
    NSUInteger total = [self.prefetchURLs count];
    NSLog(@"Finished prefetching (%lu successful, %lu skipped, timeElasped %.2f)", total - _skippedCount, _skippedCount, CFAbsoluteTimeGetCurrent() - _startedTime);
}

- (void)prefetchURLs:(NSArray *)urls
{
    [self cancelPrefetching]; //Prevent duplicate prefetch request
    _startedTime = CFAbsoluteTimeGetCurrent();
    self.prefetchURLs = urls;
    
    NSUInteger listCount = [self.prefetchURLs count];
    SKImageManager *manager = [SKImageManager sharedManager];
    for (NSUInteger i = 0; i < self.maxConcurrentDownloader && _requestedCount < listCount; i++)
    {
        [self startPrefetchingAtIndex:i withManager:manager];
    }
}

- (void)cancelPrefetching
{
    self.prefetchURLs = nil;
    _skippedCount = 0;
    _requestedCount = 0;
    _finishedCount = 0;
    [[SKImageManager sharedManager]cancelForDelegate:self];
}

#pragma mark --SKWebImagePrefetcher (SKImageManagerDelegate)

- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(id)image
{
    _finishedCount ++;
    NSLog(@"Prefetched %lu out of %lu", _finishedCount, [self.prefetchURLs count]);

    if ([self.prefetchURLs count] > _requestedCount)
    {
        [self startPrefetchingAtIndex:_requestedCount withManager:imagerManager];
    }
    else if (_finishedCount == _requestedCount)
    {
        [self reportStatus];
    }
}

- (void)webImageManager:(SKImageManager *)imagerManager didFailWithError:(NSError *)error
{
    _finishedCount ++;
    
    //Add last failed
    _skippedCount ++;
    
    if ([self.prefetchURLs count] > _requestedCount) {
        [self startPrefetchingAtIndex:_requestedCount withManager:imagerManager];
    }
    else if (_finishedCount == _requestedCount)
    {
        [self reportStatus];
    }
}
- (void)dealloc
{
    self.prefetchURLs = nil;
}
@end
