//
//  SKImageCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SKWebImageCompat.h"
NS_ASSUME_NONNULL_BEGIN

/**
 * SKImageCache maintains a memory cache and an optional disk cache. Disk cache write operations are performed
 * asynchronous so it doesn’t add unnecessary latency to the UI.
 */
@interface SKImageCache : NSObject
@property (assign,nonatomic) NSUInteger maxCacheAge;
/**
 * Returns global shared cache instance
 *
 * @return SKImageCache global instance
 */
+ (SKImageCache *)sharedImageCache;


/**
 Init a new cache store with a specific namespace

 @param ns The namespace to use for this cache store.
 @return <#return value description#>
 */
- (instancetype)initWithNamespace:(NSString *)ns;
/**
 * Store an image into memory and disk cache at the given key.
 *
 * @param image The image to store
 * @param key The unique image cache key, usually it's image absolute URL
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

/**
 * Store an image into memory and optionally disk cache at the given key.
 *
 * @param image The image to store
 * @param key The unique image cache key, usually it's image absolute URL
 * @param toDisk Store the image to disk cache if YES
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * Store an image into memory and optionally disk cache at the given key.
 *
 * @param image The image to store
 * @param data The image data as returned by the server, this representation will be used for disk storage
 *             instead of converting the given image object into a storable/compressed image format in order
 *             to save quality and CPU
 * @param key The unique image cache key, usually it's image absolute URL
 * @param toDisk Store the image to disk cache if YES
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key imageData:(nullable NSData *)data toDisk:(BOOL)toDisk;

/**
 Query the disk cache asynchronously.

 @param key The unique cache asynchronousely.
 @param downBlock <#downBlock description#>
 */
- (void)queryDiskCacheForKey:(NSString *)key down:(void (^)(UIImage *image))downBlock;
/**
 * Remove the image from memory and disk cache synchronousely
 *
 * @param key The unique image cache key
 */
- (void)removeImageForKey:(NSString *)key;

/**
 * Remove the image from memory and optionaly disk cache synchronousely
 *
 * @param key The unique image cache key
 * @param fromDisk Also remove cache entry from disk if YES
 */
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

/**
 * Clear all memory cached images
 */
- (void)clearMemory;

/**
 * Clear all disk cached images
 */
- (void)clearDisk;

/**
 * Remove all expired cached image from disk
 */
- (void)cleanDisk;

/**
 * Get the size used by the disk cache
 */
- (unsigned long long)getSize;
/**
 * Get the number of images in the disk cache
 */

- (NSUInteger)getDiskCount;
@end

NS_ASSUME_NONNULL_END
