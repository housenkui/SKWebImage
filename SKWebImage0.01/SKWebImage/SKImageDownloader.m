//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"
NSString * const SKWebImageDownloadStartNotification = @"SKWebImageDownloadStartNotification";
NSString * const SKWebImageDownloadStopNotification = @"SKWebImageDownloadStopNotification";
@interface SKImageDownloader ()
@property (strong,nonatomic) NSURLConnection *connection;
@end
@implementation SKImageDownloader
@synthesize url,delegate,connection,imageData,userInfo;

+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate {
    
    return [[self class]downloaderWithURL:url delegate:delegate userInfo:nil];
}
+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo
{
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SKWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SKWebImageDownloadStopNotification object:nil];
    }
    
    SKImageDownloader *downloader = [[SKImageDownloader alloc]init];
    downloader.url = url;
    downloader.delegate = delegate;
    downloader.userInfo = userInfo;
    //Ensure the downloader is started from the main thread
    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return downloader;
}
+ (void)setMaxConcurrentDownloaders:(NSUInteger)max {
    // NOOP
}

- (void)start {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    self.connection = [[NSURLConnection alloc]initWithRequest:request delegate:self startImmediately:NO];
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
    
    if (connection) {
        self.imageData = [NSMutableData data];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStartNotification object:nil];
    }
    else {
        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
        {
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:nil];
        }
    }
}
- (void)cancel
{
    if (connection)
    {
        [connection cancel];
        self.connection = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
    NSLog(@"-----%@-----",[NSThread currentThread]);
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];

    if ([delegate respondsToSelector:@selector(imageDownloaderDidFinish:)])
    {
        [delegate performSelector:@selector(imageDownloaderDidFinish:) withObject:self];
    }
    if ([delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)])
    {
        UIImage *image = [[UIImage alloc]initWithData:imageData];
        [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];
    if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
    {
        [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
    }
    self.connection = nil;
    self.imageData = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
@end
