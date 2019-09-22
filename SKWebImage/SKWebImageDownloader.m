//
//  SKWebImageDownloader.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/9.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageDownloader.h"
#import "SKWebImageCache.h"

@interface DownloadOperationParams : NSObject
@property (strong,nonatomic) NSURL *url;
@property (nonatomic,copy) SKWebImageDownloaderCompletedBlock completedBlock;
@end
@implementation DownloadOperationParams
@end
@interface SKWebImageDownloader ()<NSURLSessionDelegate>

@property (strong,nonatomic) NSURL *url;

/**
 返还给调用者
 */
@property (nonatomic,copy) SKWebImageDownloaderCompletedBlock completedBlock;

/**
 dataTask对象
 */
@property (strong, nonatomic) NSURLSessionTask *dataTask;

/**
 存储图片数据
 */
@property (strong, nonatomic, nullable) NSMutableData *imageData;

@end

@implementation SKWebImageDownloader

+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static SKWebImageDownloader *instance;
    dispatch_once(&once, ^{
        instance = [[SKWebImageDownloader alloc]init];
    });
    return instance;
}

- (void)downloadImageWithURL:(nullable NSURL *)url
                   completed:(nullable SKWebImageDownloaderCompletedBlock)completedBlock {
//    @synchronized (self) {
        self.url = url;
        self.completedBlock = completedBlock;
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 15;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        self.dataTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]];
//    }
    //发送请求
    [self.dataTask resume];

}


#pragma mark NSURLSessionDataDelegate

/*
请求得到服务端的响应
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSLog(@"收到服务端的响应dataTask.taskIdentifier == %lu  %@",dataTask.taskIdentifier,[NSThread currentThread]);

    NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
    self.imageData = [[NSMutableData alloc]initWithCapacity:expected];
    //这个表示允许继续加载
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}
/*
 *多次调用。获取图片数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    //根据request的选项。决定是否缓存NSCachedURLResponse
//    NSCachedURLResponse *cachedResponse = proposedResponse;
    
//    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
//        // Prevents caching of responses
//        cachedResponse = nil;
//    }
    if (completionHandler) {
        completionHandler(nil);
    }
}
#pragma mark NSURLSessionTaskDelegate

/*
 网络请求加载完成，在这里处理获得的数据
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"已经完成 task.taskIdentifier = %lu, %@",task.taskIdentifier,[NSThread currentThread]);
//    @synchronized(self) {
        [self.dataTask cancel];
        self.dataTask = nil;
//    }
    if (self.imageData) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        if (image) {
            self.completedBlock(image, error);

            NSLog(@"didCompleteWithError Thread = %@",[NSThread currentThread]);
            [[SKWebImageCache sharedImageCache] saveImage:image imageData:self.imageData withKey:self.url.absoluteString completed:^(BOOL finish) {
                NSLog(@"self.imageData.length = %lu",self.imageData.length);
               NSLog(@"finish = %d",finish);
            }];
        }
    }
    else {
        self.completedBlock(nil, [NSError errorWithDomain:@"SKWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}]);
    }
    self.imageData = nil;
}
@end
