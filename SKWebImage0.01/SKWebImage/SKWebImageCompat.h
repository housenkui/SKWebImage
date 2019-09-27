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


#endif /* SKWebImageCompat_h */
