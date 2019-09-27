//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"

@interface SKImageDownloader ()
@property (strong,nonatomic) NSURLConnection *connection;
@end
@implementation SKImageDownloader
@synthesize url,delegate,connection,imageData;

+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate {
    SKImageDownloader *downloader = [[SKImageDownloader alloc]init];
    downloader.url = url;
    downloader.delegate = delegate;
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
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
    NSLog(@"-----%@-----",[NSThread currentThread]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
    
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
    if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
    {
        [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
    }
    self.connection = nil;
    self.imageData = nil;
}
@end
