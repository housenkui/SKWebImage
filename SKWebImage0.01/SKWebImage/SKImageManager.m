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
        instance = [SKImageManager new];
    });
    return instance;
}

- (UIImage *)imageWithURL:(NSURL *)url {
    
    return [[SKImageCache sharedImageCache]imageFromKey:url.absoluteString];
}
- (void)downloadWithURL:(NSURL *)url delegate:(id<SKWebImageManagerDelegate>)delegate {
    if (url == nil || [failedURLs containsObject:url]) {
        return;
    }
    SKImageDownloader *downloader = [downloaderForURL objectForKey:url];
    if (!downloader) {
        downloader = [SKImageDownloader downloaderWithURL:url delegate:self];
        [downloaderForURL setObject:downloader forKey:url];
    }
    @synchronized (self) {
        [delegates addObject:delegate];
        [downloaders addObject:downloader];
    }
}

- (void)cancelForDelegate:(id<SKWebImageManagerDelegate>)delegate {
    @synchronized (self) {
        NSUInteger idx = [delegates indexOfObject:delegate];
        if (idx == NSNotFound) {
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
}

- (void)imageDownloader:(SKImageDownloader *)downloader didFinishWithImage:(UIImage *)image {
    @synchronized (self) {
        for (NSInteger idx = [downloaders count] - 1; idx >= 0; idx --) {
            SKImageDownloader *aDownloader = [downloaders objectAtIndex:idx];
            if (aDownloader == downloader) {
                id <SKWebImageManagerDelegate> delegate = [delegates objectAtIndex:idx];
                if (image && [delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)]) {
                    [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
                }
                [downloaders removeObjectAtIndex:idx];
                [delegates removeObjectAtIndex:idx];
            }
        }
    }
    if (image) {
        [[SKImageCache sharedImageCache] storeImage:image forKey:downloader.url.absoluteString];
    }else {
        //The image can't be downloaded from this URL,mark the URL as failed so we won't try and fail again and again
        [failedURLs addObject:downloader.url];
    }
    
    //release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
}
@end
