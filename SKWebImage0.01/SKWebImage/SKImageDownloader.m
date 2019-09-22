//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"
static NSOperationQueue *downloadQueue;
@implementation SKImageDownloader
@synthesize url,delegate;
+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate {
    SKImageDownloader *downloader = [[SKImageDownloader alloc]init];
    downloader.url = url;
    downloader.delegate = delegate;
    if (downloadQueue == nil) {
        downloadQueue = [[NSOperationQueue alloc]init];
        downloadQueue.maxConcurrentOperationCount = 8;
    }
    [downloadQueue addOperation:downloader];
    return downloader;
}
+ (void)setMaxConcurrentDownloaders:(NSUInteger)max {
    if (downloadQueue == nil) {
        downloadQueue = [[NSOperationQueue alloc]init];
    }
    downloadQueue.maxConcurrentOperationCount = max;
}
- (void)main
{
    @autoreleasepool {
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        UIImage *image = [UIImage imageWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:NULL]];
        NSLog(@"我走下载了 %@",[NSThread currentThread]);
        if (!self.cancelled && [delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)]) {
            [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
        }
    }
}
@end
