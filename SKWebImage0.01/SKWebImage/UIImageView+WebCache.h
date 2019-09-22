//
//  UIImageView+WebCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//


#import <UIKit/UIkit.h>
#import "SKWebImageManagerDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WebCache) <SKWebImageManagerDelegate>

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder;
@end

NS_ASSUME_NONNULL_END
