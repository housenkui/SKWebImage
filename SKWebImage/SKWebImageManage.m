//
//  SKWebImageManage.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKWebImageManage.h"
#import "SKWebImageCache.h"
#import "SKWebImageDownloader.h"
@interface SKWebImageManage()
@property (strong,nonatomic) SKWebImageCache *imageCache;
@property (strong,nonatomic) SKWebImageDownloader *downloader;
@end
@implementation SKWebImageManage
+ (instancetype)manager {
    static SKWebImageManage *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SKWebImageManage alloc]init];
        [manager setup];
    });
    return manager;
}
- (void)setup {
    self.imageCache = [SKWebImageCache sharedImageCache];
}
- (SKWebImageCache *)imageCache {
    if (!_imageCache) {
        _imageCache = [SKWebImageCache sharedImageCache];
    }
    return _imageCache;
}
- (SKWebImageDownloader *)downloader {
    if (!_downloader) {
        _downloader = [[SKWebImageDownloader alloc]init];
    }
    return _downloader;
}
- (void)fetchImageWithKey:(NSString *)key completed:(SKWebImagefetchImageCompletedBlock) fetchImageCompletedBlock  {
    
    [self.imageCache getImageWithKey:key completed:^(UIImage * _Nonnull image) { //先去取内存缓存和磁盘缓存
        if (image) {
            fetchImageCompletedBlock(image,nil);
        } else {//没有再去下载
            [self.downloader downloadImageWithURL:[NSURL URLWithString:key] completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
                fetchImageCompletedBlock(image,error);
            }];
        }
    }];
}
@end
