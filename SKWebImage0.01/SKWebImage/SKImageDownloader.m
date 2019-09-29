//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"

//#ifdef ENABLE_SDWEBIMAGE_DECODER
#import "SKImageDecoder.h"
@interface SKImageDownloader (ImageDecoder)<SKWebImageDecoderDelegate>
@end
//#endif
NSString * const SKWebImageDownloadStartNotification = @"SKWebImageDownloadStartNotification";
NSString * const SKWebImageDownloadStopNotification = @"SKWebImageDownloadStopNotification";
@interface SKImageDownloader ()
@property (strong,nonatomic) NSURLConnection *connection;
@end
@implementation SKImageDownloader
@synthesize url,delegate,connection,imageData,userInfo,lowPriority;

+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate {
    
    return [self downloaderWithURL:url delegate:delegate userInfo:nil];
}
+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo lowPriority:(BOOL)lowPriority {
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
    downloader.lowPriority = lowPriority;
    //Ensure the downloader is started from the main thread
    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return downloader;
}
+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo
{
    return [self downloaderWithURL:url delegate:delegate userInfo:userInfo lowPriority:NO];
}
+ (void)setMaxConcurrentDownloaders:(NSUInteger)max {
    // NOOP
}

- (void)start {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    self.connection = [[NSURLConnection alloc]initWithRequest:request delegate:self startImmediately:NO];
    if (!lowPriority) {
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
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
    NSLog(@"-----%@---- %@-",[NSThread currentThread], [[NSRunLoop currentRunLoop] currentMode]);
   

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
        UIImage *image = SKScaledImageForPath(url.absoluteString, imageData);
#ifdef ENABLE_SDWEBIMAGE_DECODER
        [[SKImageDecoder sharedImageDecoder]decodeImage:image withDelegate:self userInfo:nil];
#else
        [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
#endif
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
#pragma mark SKWebImageDecoderDelegate
#ifdef ENABLE_SDWEBIMAGE_DECODER

- (void)imageDecoder:(SKImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)userInfo
{
    [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
}
#endif

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
@end
