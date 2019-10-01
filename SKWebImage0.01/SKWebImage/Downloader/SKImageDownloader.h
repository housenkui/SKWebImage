//
//  SKImageDownloader.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKImageDownloaderDelegate.h"
#import "SKWebImageCompat.h"
NS_ASSUME_NONNULL_BEGIN
extern NSString * const SKWebImageDownloadStartNotification;
extern NSString * const SKWebImageDownloadStopNotification;

@interface SKImageDownloader : NSObject
{
    @private
    NSURL *url;
    __weak id <SKImageDownloaderDelegate> delegate;
    NSURLConnection *connection;
    NSMutableData *imageData;
    id userInfo;
    BOOL lowPriority;
    NSUInteger expectedSize;
    BOOL progressive;
    size_t width,height;
}
@property(strong,nonatomic)NSURL *url;
@property(weak,nonatomic)id <SKImageDownloaderDelegate>delegate;
@property (strong,nonatomic,nullable) NSMutableData *imageData;
@property (strong,nonatomic) id userInfo;
@property (assign,nonatomic)BOOL lowPriority;
@property (assign,nonatomic)BOOL progressive;

+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo lowPriority:(BOOL)lowPriority;
+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo;
+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate;
+(void)setMaxConcurrentDownloaders:(NSUInteger)max __attribute__((deprecated));
- (void)start;
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
