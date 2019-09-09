//
//  SKWebImageDownloader.h
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/9.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef void(^SKWebImageDownloaderCompletedBlock)(UIImage * _Nullable image,NSError * _Nullable error);
@interface SKWebImageDownloader : NSObject
/**
 单列方法。返回一个单列对象
 @return 返回一个单列的SKWebImageDownloader对象
 */
+ (nonnull instancetype)sharedDownloader;

- (void)downloadImageWithURL:(nullable NSURL *)url
                   completed:(nullable SKWebImageDownloaderCompletedBlock)completedBlock;
@end

NS_ASSUME_NONNULL_END
