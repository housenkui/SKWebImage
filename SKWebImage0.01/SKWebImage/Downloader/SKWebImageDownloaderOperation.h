//
//  SKWebImageDownloaderOperation.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/10/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "SKImageDownloader.h"
#import "SKWebImageOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKWebImageDownloaderOperation : NSOperation <SKWebImageOperation>

@property (strong,nonatomic,readonly) NSURLRequest *request;
@property (assign,nonatomic,readonly) SKWebImageDownloaderOptions options;
- (instancetype)initWithRequest:(NSURLRequest *)request
                          queue:(dispatch_queue_t)queue
                        options:(SKWebImageDownloaderOptions)options
                       progress:(SKWebImageDownloaderProgressBlock)progressBlock
                      completed:(SKWebImageDownloaderCompletedBlock)completedBlock
                      cancelled:(void(^)(void))cancelBlock;
@end

NS_ASSUME_NONNULL_END
