//
//  SKImageDownloader.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKWebImageCompat.h"
#import "SKWebImageOperation.h"
NS_ASSUME_NONNULL_BEGIN

typedef enum
{
    SKWebImageDownloaderlowPriority = 1 << 0,
    SKWebImageDownloaderProgressiveDownload = 1 << 1
} SKWebImageDownloaderOptions;
extern NSString * const SKWebImageDownloadStartNotification;
extern NSString * const SKWebImageDownloadStopNotification;

typedef void(^SKWebImageDownloaderProgressBlock)(NSUInteger receiveSize,long long expectedSize);
typedef void(^SKWebImageDownloaderCompletedBlock)(UIImage * _Nullable image, NSError * _Nullable error,BOOL finish);


/**
 Asynchronous downloader dedicated and optimized for image loading.
 */
@interface SKImageDownloader : NSObject

@property (assign,nonatomic)NSInteger maxConcurrentDownloaders;

+ (SKImageDownloader *)sharedDownloader;

/**
 <#Description#>

 @param url <#url description#>
 @param options <#options description#>
 @param progressBlock <#progressBlock description#>
 @param completedBlock <#completedBlock description#>
 @return <#return value description#>
 */
- (id <SKWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SKWebImageDownloaderOptions)options
                                        progress:(SKWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SKWebImageDownloaderCompletedBlock)completedBlock;
@end

NS_ASSUME_NONNULL_END
