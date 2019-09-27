//
//  SKImageCacheDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/27.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SKImageCache;
@protocol SKImageCacheDelegate <NSObject>
@optional

- (void)imageCache:(SKImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info;
- (void)imageCache:(SKImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
