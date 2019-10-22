//
//  SKWebImageCompat.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/27.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#ifndef SKWebImageCompat_h
#define SKWebImageCompat_h
#import "CPmetamacros.h"
#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#ifndef UIImage
#define UIImage NSImage
#endif
#ifndef UIImageView
#define UIImageView NSImageView
#endif
#else
#import <UIKit/UIKit.h>
#endif

#ifndef weakify
#define weakify(...) \
cp_keywordify \
metamacro_foreach_cxt(cp_weakify_,, __weak, __VA_ARGS__)
#endif

#ifndef strongify
#define strongify(...) \
cp_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(cp_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")
#endif

#define cp_weakify_(INDEX, CONTEXT, VAR) \
CONTEXT __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

#define cp_strongify_(INDEX, VAR) \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);

#if DEBUG
#define cp_keywordify autoreleasepool {}
#else
#define cp_keywordify try {} @catch (...) {}
#endif

//最终转换为 //https://www.jianshu.com/p/701da54bd78c
//@weakify(self) = @autoreleasepool{} __weak __typeof__ (self) self_weak_ = self;
//
//@strongify(self) = @autoreleasepool{} __strong __typeof__(self) self = self_weak_;

/**
 根据屏幕分辨率 返回一张放大的图，有这个必要吗？？？

 @param path <#path description#>
 @param imageData <#imageData description#>
 @return <#return value description#>
 */
NS_INLINE UIImage *SKScaledImageForPath(NSString *path,NSObject *imageData)
{
    if (!imageData)
    {
        return nil;
    }
    UIImage *image;
    if (imageData && [imageData isKindOfClass:[UIImage class]]) {
        image = (UIImage *)imageData;
    }
    else if([imageData isKindOfClass:[NSData class]])
    {
      image = [[UIImage alloc]initWithData:(NSData *)imageData];
    }
    else
    {
        return nil;
    }
    CGFloat scale = 1.0;
    if (path.length >= 8)
    {
        NSRange range = [path rangeOfString:@"@2x." options:0 range:NSMakeRange(path.length - 8, 5)];
        if (range.location != NSNotFound)
        {
            scale = 2.0;
        }
    }
    UIImage *scaledImage = [[UIImage alloc]initWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
    image = scaledImage;
    return image;
}

#endif /* SKWebImageCompat_h */
