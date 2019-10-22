//
//  SKWebImageDownloaderOperation.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/10/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageDownloaderOperation.h"
#import "SKImageDecoder.h"
#import <ImageIO/ImageIO.h>
@interface SKWebImageDownloaderOperation ()
@property (copy,nonatomic) SKWebImageDownloaderProgressBlock progressBlock;
@property (nonatomic,copy) SKWebImageDownloaderCompletedBlock completedBlock;
@property (nonatomic,copy) void (^cancelBlock)(void);
@property (assign,nonatomic,getter= isExecuting)BOOL executing;
@property (assign,nonatomic,getter= isFinished)BOOL finished;
@property (assign,nonatomic)long long expectedSize;
@property (strong,nonatomic) NSMutableData *imageData;
@property (strong,nonatomic) NSURLConnection *connect;
@end

@implementation SKWebImageDownloaderOperation
{
    size_t width,height;
}
@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(NSURLRequest *)request options:(SKWebImageDownloaderOptions)options progress:(SKWebImageDownloaderProgressBlock)progressBlock completed:(SKWebImageDownloaderCompletedBlock)completedBlock cancelled:(nonnull void (^)(void))cancelBlock
{
    if (self = [super init]) {
        _request = request;
        _options = options;
        _progressBlock = progressBlock;
        _completedBlock = completedBlock;
        _cancelBlock = cancelBlock;
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
    }
    return self;
}

- (void)start
{
    if (self.isCancelled) {
        self.finished = YES;
        [self reset];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connect = [NSURLConnection.alloc initWithRequest:self.request delegate:self startImmediately:NO];
        [self.connect scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.connect start];
        self.executing = YES;
        
        if (self.options & SKWebImageDownloaderlowPriority) {
            [self.connect scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }
        if (self.connect) {
            [[NSNotificationCenter defaultCenter]postNotificationName:SKWebImageDownloadStartNotification object:self];
        }
        else
        {
            if (self.completedBlock) {
                self.completedBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Connection can't be initialized"}], NO);
            }
        }
    });
}
- (void)cancel
{
    if (self.isFinished) {
        return;
    }
    [super cancel];
    if (self.cancelBlock) self.cancelBlock();
    
    if (self.connect) {
        [self.connect cancel];
        [[NSNotificationCenter defaultCenter]postNotificationName:SKWebImageDownloadStopNotification object:self];
        
        //As we cancelled the connection,its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (!self.isFinished) self.finished = YES;
        if (self.isExecuting) self.executing = NO;
    }
    [self reset];
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
    [self reset];
}
- (void)reset
{
    self.cancelBlock = nil;
    self.completedBlock = nil;
    self.progressBlock = nil;
    self.connect = nil;
    self.imageData = nil;
}
- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark NSURLConnection (delegate)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response");
    if ([response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse *)response statusCode] < 400)
    {
        self.expectedSize = response.expectedContentLength > 0 ? response.expectedContentLength : 0;
        self.imageData = [[NSMutableData alloc]initWithCapacity:self.expectedSize];
    }
    else
    {
        [connection cancel];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];
        if (self.completedBlock) {
            self.completedBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode]  userInfo:nil], NO);
        }
        [self done];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.imageData appendData:data];
    //这里data.length 数值和什么有关系，最大值是多少？
    NSLog(@"-----%@---- %@----%lu",[NSThread currentThread], [[NSRunLoop currentRunLoop] currentMode],data.length);
    //一下是图片解码的操作绝对不能放在主线程
    if ((self.options & SKWebImageDownloaderProgressiveDownload) && self.expectedSize > 0 && self.completedBlock)
    {
        //Get the total bytes downloaded
        const NSUInteger totalSize = [self.imageData length];
        
        //Update the data source,we must pass All the data,not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
        CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)self.imageData, totalSize == self.expectedSize);
        
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
        
        if (width + height > 0 && totalSize < self.expectedSize)
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
                UIImage *image = [UIImage decodedImageWithImage:SKScaledImageForPath(self.request.URL.absoluteString, [UIImage imageWithCGImage:partialImageRef])];
                CGImageRelease(partialImageRef);
                self.completedBlock(image, nil, NO);
            }
        }
        CFRelease(imageSource);
    }
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connect = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:self];
    
    if (self.completedBlock) {
        __block SKWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;
        UIImage *image = SKScaledImageForPath(self.request.URL.absoluteString, self.imageData);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            UIImage *decodedImage = [UIImage decodedImageWithImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(decodedImage,nil,YES);
                completionBlock = nil;
            });
        });
    }
    [self done];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SKWebImageDownloadStopNotification object:nil];
    if (self.completedBlock) {
        self.completedBlock(nil, error, NO);
    }
    [self done];
}

//prevent caching of responses in Cache.db
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}
//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
//{
//    return YES;
//}
//
//- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
//{
//    return YES;
//}
@end
