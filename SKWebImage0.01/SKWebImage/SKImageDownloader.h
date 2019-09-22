//
//  SKImageDownloader.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import "SKImageDownloaderDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface SKImageDownloader : NSOperation
{
    NSURL *url;
    __weak id <SKImageDownloaderDelegate> delegate;
}
@property(strong,nonatomic)NSURL *url;
@property(weak,nonatomic)id <SKImageDownloaderDelegate>delegate;

+(id)downloaderWithURL:(NSURL *)url delegate:(id <SKImageDownloaderDelegate>)delegate;
+(void)setMaxConcurrentDownloaders:(NSUInteger)max;
@end

NS_ASSUME_NONNULL_END
