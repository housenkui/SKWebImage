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
@implementation SKImageManager

- (instancetype)init {
    if (self = [super init]) {
        delegates = [[NSMutableArray alloc]init];
        downloaders = [[NSMutableArray alloc]init];
        downloaderForURL = [[NSMutableDictionary alloc]init];
        failedURLs = [[NSMutableArray alloc]init];
    }
    return self;
}
+ (SKImageManager *)sharedManager {
    
    static SKImageManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"onceToken = %ld",onceToken);
        instance = [SKImageManager new];
    });
    return instance;
}

- (UIImage *)imageWithURL:(NSURL *)url {
    
    return [[SKImageCache sharedImageCache]imageFromKey:url.absoluteString];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate
{
    [self downloadWithURL:url delegate:delegate retryFailed:NO];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed
{
    [self downloadWithURL:url delegate:delegate retryFailed:retryFailed lowPriority:NO];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority;
{
    if (url == nil ||!delegate|| (!retryFailed && [failedURLs containsObject:url]))
    {
        return;
    }
    
    //Check the on-disk cache async so we don't block the main thread
    NSDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:delegate,@"delegate",url,@"url",[NSNumber numberWithBool:lowPriority],@"low_priority", nil];
    [[SKImageCache sharedImageCache]queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];
}
- (void)cancelForDelegate:(id<SKWebImageManagerDelegate>)delegate
{
        NSUInteger idx = [delegates indexOfObjectIdenticalTo:delegate];
        if (idx == NSNotFound)
        {
            return;
        }
        SKImageDownloader *downloader = [downloaders objectAtIndex:idx];
        [delegates removeObjectAtIndex:idx];
        [downloaders removeObjectAtIndex:idx];
        if (![downloaders containsObject:downloader]) {
            
            //No more delegate are waiting for this download,cancel it
            [downloader cancel];
            [downloaderForURL removeObjectForKey:downloader.url];
        }
}

#pragma mark SKImageCacheDelegate
- (void)imageCache:(SKImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info
{
    id <SKWebImageManagerDelegate>delegate = [info objectForKey:@"delegate"];
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
    }
}

- (void)imageCache:(SKImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id <SKWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];
    BOOL lowPriority = [[info objectForKey:@"low_priority"] boolValue];
    
    //Share the same downloader for identical URLs so we don't download the same URL several times
    SKImageDownloader *downloader = [downloaderForURL objectForKey:url];
    if (!downloader) {
        downloader = [SKImageDownloader downloaderWithURL:url delegate:self userInfo:nil lowPriority:lowPriority];
        [downloaderForURL setObject:downloader forKey:url];
    }
    //If we get a normal priority request,make sure to change type since downloader is shared
    if (!lowPriority && downloader.lowPriority)
    {
        downloader.lowPriority = NO;
    }
    [delegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark --SKImageDownloaderDelegate

- (void)imageDownloader:(SKImageDownloader *)downloader didFinishWithImage:(UIImage *)image
{
    //notify all the delegates with this downloader
    for (NSInteger idx = [downloaders count] - 1; idx >= 0; idx --)
    {
        SKImageDownloader *aDownloader = [downloaders objectAtIndex:idx];
        if (aDownloader == downloader)
        {
            id <SKWebImageManagerDelegate> delegate = [delegates objectAtIndex:idx];
            
            if (image)
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:nil];
                }
            }
            
            [downloaders removeObjectAtIndex:idx];
            [delegates removeObjectAtIndex:idx];
        }
    }
    if (image)
    {
        //Store the image in the cache
        [[SKImageCache sharedImageCache] storeImage:image
                                             forKey:downloader.url.absoluteString
                                          imageData:downloader.imageData
                                             toDisk:YES];
    }
    else
    {
        //The image can't be downloaded from this URL,mark the URL as failed so we won't try and fail again and again
        [failedURLs addObject:downloader.url];
    }
    
    //release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
}

- (void)imageDownloader:(SKImageDownloader *)downloader didFailWithError:(NSError *)error
{
    for (NSInteger idx = downloaders.count - 1; idx >= 0; idx--)
    {
        SKImageDownloader *aDownloader = [downloaders objectAtIndex:idx];
        if (aDownloader == downloader) {
            id <SKWebImageManagerDelegate> delegate = [delegates objectAtIndex:idx];
            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)]) {
                [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:error];
            }
            [downloaders removeObjectAtIndex:idx];
            [delegates removeObjectAtIndex:idx];
        }
    }
    [downloaderForURL removeObjectForKey:downloader.url];
}
@end
