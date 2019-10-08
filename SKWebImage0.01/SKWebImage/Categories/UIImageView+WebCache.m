//
//  UIImageView+WebCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "UIImageView+WebCache.h"

@implementation UIImageView (WebCache)
- (void)setImageWithURL:(NSURL *)url
{
    return [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    
    [self setImageWithURL:url placeholderImage:placeholder options:0];
}
- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SKWebImageOptions)options
{
    SKImageManager *manager = [SKImageManager sharedManager];
    
    //Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    self.image = placeholder;
    
    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options];
    }
}

- (void)setImageWithURL:(NSURL *)url
                success:(SKWebImageSuccessBlock)success
                failure:(SKWebImageFailureBlock)failure
{
    [self setImageWithURL:url placeholderImage:nil options:0 success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(nullable UIImage *)placeholder
                success:(SKWebImageSuccessBlock)success
                failure:(SKWebImageFailureBlock)failure
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SKWebImageOptions)options success:(SKWebImageSuccessBlock)success failure:(SKWebImageFailureBlock)failure
{
    
    SKImageManager *manager = [SKImageManager sharedManager];
    //Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    self.image = placeholder;
    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options success:success failure:failure];
    }
}
- (void)webImageManager:(SKImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url
{
    self.image = image;
    [self setNeedsLayout];
}
- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(UIImage *)image{
    self.image = image;
    [self setNeedsLayout];//work not well
}

- (void)cancelCurrentImageLoad {
    [[SKImageManager sharedManager] cancelForDelegate:self];
}
@end
