//
//  UIButton+WebCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/28.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "UIButton+WebCache.h"
#import "SKImageManager.h"
@implementation UIButton (WebCache)
- (void)setImageWithURL:(NSURL *)url
{
    return [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    SKImageManager *manager = [SKImageManager sharedManager];
    
    //Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    [self setImage:placeholder forState:UIControlStateNormal];

    if (url)
    {
        [manager downloadWithURL:url delegate:self];
    }
}
- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setImage:placeholder forState:UIControlStateNormal];
    });
}

- (void)cancelCurrentImageLoad {
    
    [[SKImageManager sharedManager] cancelForDelegate:self];
}
@end
