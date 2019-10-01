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
typedef void (^SuccessBlock)(UIImage *image);
typedef void (^FailureBlock)(NSError *error);

@interface SKImageManager ()
@end
@implementation SKImageManager
- (instancetype)init {
    if (self = [super init])
    {
        downloadDelegates = [[NSMutableArray alloc]init];
        downloaders = [[NSMutableArray alloc]init];
        cacheDelegates = [[NSMutableArray alloc]init];
        cacheURLs = [[NSMutableArray alloc]init];
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

- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed
{
    [self downloadWithURL:url delegate:delegate options:(retryFailed ? SKWebImageRetryFailed : 0)];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority;
{
    
    SKWebImageOptions options = 0;
    if (retryFailed) options |= SKWebImageRetryFailed;
    if (lowPriority) {
        options |= SKWebImageLowPriority;
    }
    [self downloadWithURL:url delegate:delegate options:options];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate
{
    [self downloadWithURL:url delegate:delegate options:0];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate options:(SKWebImageOptions)options
{
    
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    if (url == nil ||!delegate|| (!(options &&SKWebImageRetryFailed)&& [failedURLs containsObject:url]))
    {
        return;
    }
    
    //Check the on-disk cache async so we don't block the main thread
    [cacheDelegates addObject:delegate];
    [cacheURLs addObject:url];
    NSDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:delegate,@"delegate",url,@"url",[NSNumber numberWithBool:options],@"options", nil];
    [[SKImageCache sharedImageCache]queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];
    
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate options:(SKWebImageOptions)options success:(void (^)(UIImage * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
    
    // repeated logic from above due to requirement for backwards compatability for iOS versions without blocks
    
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (!url || !delegate || (!(options & SKWebImageRetryFailed) && [failedURLs containsObject:url]))
    {
        return;
    }
    //Check the on-disk cache async so we don't block the main thread
    [cacheDelegates addObject:delegate];
    [cacheURLs addObject:url];
    
    SuccessBlock successCopy = [success copy];
    FailureBlock failureCopy = [failure copy];
    NSDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:delegate,@"delegate",url,@"url",[NSNumber numberWithBool:options],@"options",successCopy,@"success",failureCopy,@"failure", nil];
    [[SKImageCache sharedImageCache]queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];}

- (void)cancelForDelegate:(id<SKWebImageManagerDelegate>)delegate
{
    NSUInteger idx;
    while ((idx = [cacheDelegates indexOfObjectIdenticalTo:delegate] != NSNotFound))
    {
        [cacheDelegates removeObjectAtIndex:idx];
        [cacheURLs removeObjectAtIndex:idx];
    }
    [cacheDelegates removeObjectIdenticalTo:delegate];
    
    while ((idx = [downloadDelegates indexOfObjectIdenticalTo:delegate])!= NSNotFound)
    {
        SKImageDownloader *downloader = [downloaders objectAtIndex:idx];
        
        [downloadDelegates removeObjectAtIndex:idx];
        [downloaders removeObjectAtIndex:idx];
        
        if (![downloaders containsObject:downloader]) {
            
            //No more delegate are waiting for this download,cancel it
            [downloader cancel];
            [downloaderForURL removeObjectForKey:downloader.url];
        }
    }
}

#pragma mark SKImageCacheDelegate
- (NSUInteger)indexOfDelegate:(id <SKWebImageManagerDelegate>)delegate waitingForURL:(NSURL *) url
{
    NSUInteger idx;
    for (idx = 0; idx < [cacheDelegates count]; idx ++)
    {
        if ([cacheDelegates objectAtIndex:idx] == delegate && [[cacheURLs objectAtIndex:idx] isEqual:url])
        {
            return idx;
        }
    }
    return NSNotFound;
}

- (void)imageCache:(SKImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id <SKWebImageManagerDelegate>delegate = [info objectForKey:@"delegate"];
    
    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        //Request has since been canceled
        return;
    }
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
    }
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:)])
    {
        objc_msgSend(delegate,@selector(webImageManager:didFinishWithImage:forURL:),self,image,url);
    }
    if([info objectForKey:@"success"])
    {
        SuccessBlock success = [info objectForKey:@"success"];
        success(image);
    }
    //Remove one instance of delegate from the array,
    //not all of them (as /removeObjectIndentical:would)
    //in case multiple requests are issued.
    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];
}

- (void)imageCache:(SKImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id <SKWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];
    SKWebImageOptions options = [[info objectForKey:@"options"] boolValue];
    
    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        //Request has since been canceled
        return;
    }
    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];
    
    //Share the same downloader for identical URLs so we don't download the same URL several times
    SKImageDownloader *downloader = [downloaderForURL objectForKey:url];
    if (!downloader) {
        downloader = [SKImageDownloader downloaderWithURL:url delegate:self userInfo:nil lowPriority:(options & SKWebImageLowPriority)];
        [downloaderForURL setObject:downloader forKey:url];
    }
    //If we get a normal priority request,make sure to change type since downloader is shared
    else
    {
        //Reuse shared downloader
        downloader.userInfo = info;
        downloader.lowPriority = (options & SKWebImageLowPriority);
    }
    [downloadDelegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark --SKImageDownloaderDelegate

- (void)imageDownloader:(SKImageDownloader *)downloader didFinishWithImage:(UIImage *)image
{
    SKWebImageOptions options = [[downloader.userInfo objectForKey:@"options"]intValue];
    //notify all the delegates with this downloader
    for (NSInteger idx = [downloaders count] - 1; idx >= 0; idx --)
    {
        SKImageDownloader *aDownloader = [downloaders objectAtIndex:idx];
        if (aDownloader == downloader)
        {
            id <SKWebImageManagerDelegate> delegate = [downloadDelegates objectAtIndex:idx];
            
            if (image)
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
                }
                if([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:)])
                {
                    objc_msgSend(delegate, @selector(webImageManager:didFinishWithImage:forURL:),self,image,downloader.url);
                }
                if([downloader.userInfo objectForKey:@"success"])
                {
                    SuccessBlock success = [downloader.userInfo objectForKey:@"success"];
                    success(image);
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:nil];
                }
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:)])
                {
                    objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:),self,image,downloader.url);
                }
                if([downloader.userInfo objectForKey:@"failure"])
                {
                    FailureBlock failure = [downloader.userInfo objectForKey:@"failure"];
                    failure(nil);
                }
            }
            
            [downloaders removeObjectAtIndex:idx];
            [downloadDelegates removeObjectAtIndex:idx];
        }
    }
    if (image)
    {
        //Store the image in the cache
        [[SKImageCache sharedImageCache] storeImage:image
                                             forKey:downloader.url.absoluteString
                                          imageData:downloader.imageData
                                             toDisk:!(options & SKWebImageCacheMemoryOnly)];
    }
    else if (!(options & SKWebImageRetryFailed))
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
            id <SKWebImageManagerDelegate> delegate = [downloadDelegates objectAtIndex:idx];
            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
            {
                [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:error];
            }
            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:)])
            {
                objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:),self,error,downloader.url);
            }
            if([downloader.userInfo objectForKey:@"failure"])
            {
                FailureBlock failure = [downloader.userInfo objectForKey:@"failure"];
                failure(nil);
            }
            [downloaders removeObjectAtIndex:idx];
            [downloadDelegates removeObjectAtIndex:idx];
        }
    }
    [downloaderForURL removeObjectForKey:downloader.url];
}
@end
