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
/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */

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

/**
 * If set to YES, enables progressive download support.
 *
 * The [SKWebImageDownloaderDelegate imageDownloader:didUpdatePartialImage:] delegate method is then called
 * while the image is downloaded with an image object containing the portion of the currently downloaded
 * image.
 *
 */

@property (assign,nonatomic)BOOL progressive;
/**
 * Creates a SKWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SKWebImageDownloaderDelegate
 *
 * @param url The URL to the image to download
 * @param delegate The delegate object
 * @param userInfo A NSDictionary containing custom info
 * @param lowPriority Ensure the download won't run during UI interactions
 *
 * @return A new SKWebImageDownloader instance
 */

+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo lowPriority:(BOOL)lowPriority;
+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate userInfo:(nullable id)userInfo;
+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate;
+(void)setMaxConcurrentDownloaders:(NSUInteger)max __attribute__((deprecated));
- (void)start;

/**
 * Cancel the download immediatelly
 */

- (void)cancel;
@end

NS_ASSUME_NONNULL_END
