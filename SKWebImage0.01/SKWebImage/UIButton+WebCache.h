//
//  UIButton+WebCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/28.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKWebImageCompat.h"
#import "SKWebImageManagerDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface UIButton (WebCache)<SKWebImageManagerDelegate>
- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder;
- (void)cancelCurrentImageLoad;
@end

NS_ASSUME_NONNULL_END
