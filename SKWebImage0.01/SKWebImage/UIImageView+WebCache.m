//
//  UIImageView+WebCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "SKImageManager.h"
@implementation UIImageView (WebCache)
- (void)setImageWithURL:(NSURL *)url
{
    return [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    SKImageManager *manager = [SKImageManager sharedManager];
    
    //Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    UIImage *cachedImage = nil;
    if (url) {
       cachedImage = [manager imageWithURL:url];
    }
    if (cachedImage) {
        self.image = cachedImage;
    }
    else
    {
        if (placeholder) {
            self.image = placeholder;
        }
        if (url) {
            [manager downloadWithURL:url delegate:self];
        }
    }
}
- (void)webImageManager:(SKImageManager *)imagerManager didFinishWithImage:(UIImage *)image{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.image = image;
    });
}

- (void)cancelCurrentImageLoad {
    
    [[SKImageManager sharedManager] cancelForDelegate:self];
}
@end
