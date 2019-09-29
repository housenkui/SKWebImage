//
//  SKWebImageCompat.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/27.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#ifndef SKWebImageCompat_h
#define SKWebImageCompat_h
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

/**
 根据屏幕分辨率 返回一张放大的图，有这个必要吗？？？

 @param path <#path description#>
 @param imageData <#imageData description#>
 @return <#return value description#>
 */
NS_INLINE UIImage *SKScaledImageForPath(NSString *path,NSData *imageData)
{
    if (!imageData)
    {
        return nil;
    }
    UIImage *image = [[UIImage alloc]initWithData:imageData];
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
