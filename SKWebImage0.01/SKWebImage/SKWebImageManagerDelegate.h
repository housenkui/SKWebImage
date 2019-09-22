//
//  SKWebImageManagerDelegate.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SKImageManager;
@protocol SKWebImageManagerDelegate <NSObject>
@optional
- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
