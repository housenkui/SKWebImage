//
//  UIImageView+WebCache.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "objc/runtime.h"

static char operationKey;

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
    [self setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SKWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}



- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SKWebImageOptions)options completed:(nonnull SKWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];

}


- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SKWebImageOptions)options progress:(SKWebImageDownloaderProgressBlock)progressBlock completed:(SKWebImageCompletedBlock)completedBlock
{
    NSLog(@"setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder");
    [self cancelCurrentImageLoad];
    self.image = placeholder;
    if (url) {
        id <SKWebImageOperation>operation = [SKImageManager.sharedManager downloadWithURL:url options:options progress:progressBlock completed:^(UIImage * _Nullable image, NSError * _Nullable error, BOOL fromCache) {
            if (image) {
                self.image = image;
                [self setNeedsLayout];
            }
            if (completedBlock) {
                completedBlock(image,error,fromCache);
            }
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
- (void)cancelCurrentImageLoad {
   //Cancel in progress downloader from queue
    id <SKWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation) {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
@end
