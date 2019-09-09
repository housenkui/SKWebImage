//
//  SKWebImageDownloader.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/9.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageDownloader.h"
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
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}
- (void)downloadImageWithURL:(nullable NSURL *)url
                   completed:(nullable SKWebImageDownloaderCompletedBlock)completedBlock {
    SKWebImageDownloader *instance = [SKWebImageDownloader sharedDownloader];
    instance.url = url;
    instance.completedBlock = completedBlock;
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 15;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    self.dataTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]];
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

//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
// willCacheResponse:(NSCachedURLResponse *)proposedResponse
// completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
//    //根据request的选项。决定是否缓存NSCachedURLResponse
//    NSCachedURLResponse *cachedResponse = proposedResponse;
//
//    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
//        // Prevents caching of responses
//        cachedResponse = nil;
//    }
//    if (completionHandler) {
//        completionHandler(cachedResponse);
//    }
//}

#pragma mark NSURLSessionTaskDelegate

/*
 网络请求加载完成，在这里处理获得的数据
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.imageData) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        if (image) {
            self.completedBlock(image, error);
        }
    }
    else {
        self.completedBlock(nil, [NSError errorWithDomain:@"SKWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}]);
    }
   
}
/*
 验证HTTPS的证书
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;

    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    disposition = NSURLSessionAuthChallengeUseCredential;
    //使用可信任证书机构的证书
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        //如果SDWebImageDownloaderAllowInvalidSSLCertificates属性设置了，则不验证SSL证书。直接信任
//        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates)) {
//            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
//        } else {
//            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
//            disposition = NSURLSessionAuthChallengeUseCredential;
//        }
//    } else {
//        //使用自己生成的证书
//        if (challenge.previousFailureCount == 0) {
//            if (self.credential) {
//                credential = self.credential;
//                disposition = NSURLSessionAuthChallengeUseCredential;
//            } else {
//                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
//            }
//        } else {
//            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
//        }
//    }
    //验证证书
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
@end
