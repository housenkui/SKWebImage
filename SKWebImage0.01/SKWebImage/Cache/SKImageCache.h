//
//  SKImageCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SKImageCacheDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface SKImageCache : NSObject
{
    NSMutableDictionary *memCache;
    NSString *diskCachePath;
    NSOperationQueue *cacheInQueue,*cacheOutQueue;
}
+ (SKImageCache *)sharedImageCache;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key imageData:(nullable NSData *)data toDisk:(BOOL)toDisk;

- (UIImage *)imageFromKey:(NSString *)key;
- (UIImage *)imageFromKey:(NSString *)key fromDisk:(BOOL)fromDisk;
- (void)queryDiskCacheForKey:(NSString *)key delegate:(id <SKImageCacheDelegate>) delegate userInfo:(NSDictionary *)info;

- (void)removeImageForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

- (void)clearMemory;
- (void)clearDisk;
- (void)cleanDisk;
- (unsigned long long)getSize;
@end

NS_ASSUME_NONNULL_END
