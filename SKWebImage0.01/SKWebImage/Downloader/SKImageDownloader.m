//
//  SKImageDownloader.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDownloader.h"
#import "SKImageDecoder.h"
#import <ImageIO/ImageIO.h>
@interface SKImageDownloader (ImageDecoder)<SKWebImageDecoderDelegate>
@end

NSString * const SKWebImageDownloadStartNotification = @"SKWebImageDownloadStartNotification";
NSString * const SKWebImageDownloadStopNotification = @"SKWebImageDownloadStopNotification";
@interface SKImageDownloader ()
@property (strong,nonatomic) NSURLConnection *connection;
@end
@implementation SKImageDownloader
@synthesize url,delegate,connection,imageData,userInfo,lowPriority,progressive;

+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate {
    
    return [self downloaderWithURL:url delegate:delegate userInfo:nil];
}
+(id)downloaderWithURL:(NSURL *)url delegate:(id<SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo lowPriority:(BOOL)lowPriority {
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
+ (NSString *)defaultRunLoopMode
{
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    NSProcessInfo *ProcessInfo = [NSProcessInfo processInfo];
    NSLog(@"ProcessInfo = %lu",ProcessInfo.activeProcessorCount);
    //mini 6个cpu ,IPhone6p,2个cpu
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}
- (void)start {
    [[self class] defaultRunLoopMode];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:30];
    self.connection = [[NSURLConnection alloc]initWithRequest:request delegate:self startImmediately:NO];
    if (!lowPriority) {
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    [connection start];
    
    if (connection) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStartNotification object:self];
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
#pragma mark NSURLConnection (delegate)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse *)response statusCode] < 400)
    {
        expectedSize = response.expectedContentLength > 0 ? response.expectedContentLength : 0;
        self.imageData = [[NSMutableData alloc]initWithCapacity:expectedSize];
    }
    else
    {
        [connection cancel];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];
        
        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)]) {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                        code:[((NSHTTPURLResponse *)response) statusCode]
                                                    userInfo:nil];
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
        }
        self.connection = nil;
        self.imageData = nil;
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
    //这里data.length 数值和什么有关系，最大值是多少？
    NSLog(@"-----%@---- %@----%lu",[NSThread currentThread], [[NSRunLoop currentRunLoop] currentMode],data.length);
    //一下是图片解码的操作绝对不能放在主线程
    if (self.progressive && expectedSize > 0 && [delegate respondsToSelector:@selector(imageDownloader:didUpdatePartialImage:)])
    {
        //Get the total bytes downloaded
        const NSUInteger totalSize = [imageData length];
        
        //Update the data source,we must pass All the data,not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
        CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)imageData, totalSize == expectedSize);
        
        if (width + height == 0)
        {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties)
            {
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) {
                    CFNumberGetValue(val, kCFNumberLongType, &height);
                }
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) {
                    CFNumberGetValue(val, kCFNumberLongType, &width);
                }
                CFRelease(properties);
            }
        }
        
        if (width + height > 0 && totalSize < expectedSize)
        {
          // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            
            if (partialImageRef)
            {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, colorSpace, kCGBitmapByteOrderDefault|kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext)
                {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f,.origin.y = 0.0f,.size.width = width,.size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else
                {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
            if (partialImageRef) {
                UIImage *image = SKScaledImageForPath(url.absoluteString, [UIImage imageWithCGImage:partialImageRef]);
                [[SKImageDecoder sharedImageDecoder]decodeImage:image
                                                   withDelegate:self
                                                       userInfo:[NSDictionary dictionaryWithObject:@"partial" forKey:@"type"]];
                
                CGImageRelease(partialImageRef);

            }
        }
        CFRelease(imageSource);
    }
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:self];

    if ([delegate respondsToSelector:@selector(imageDownloaderDidFinish:)])
    {
        [delegate performSelector:@selector(imageDownloaderDidFinish:) withObject:self];
    }
    if ([delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)])
    {
        UIImage *image = SKScaledImageForPath(url.absoluteString, imageData);
        [[SKImageDecoder sharedImageDecoder]decodeImage:image withDelegate:self userInfo:nil];

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

//prevent caching of responses in Cache.db
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

#pragma mark SKWebImageDecoderDelegate

- (void)imageDecoder:(SKImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)userInfo
{
    if ([[userInfo valueForKey:@"type"] isEqualToString:@"partial"])
    {
        [delegate imageDownloader:self didUpdatePartialImage:image];
    }
    [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
@end
