//
//  Config.h
//  CPPaySDK
//
//  Created by 侯森魁 on 2019/8/31.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#ifndef Config_h
#define Config_h
#import "CPmetamacros.h"
//获取导航栏+状态栏的高度
#define getRectNavAndStatusHight  self.navigationController.navigationBar.frame.size.height+[[UIApplication sharedApplication] statusBarFrame].size.height
//16进制颜色值转 rgb
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define UTILLOG(message,isShow) [CPPaySDKUtil printLog:message showLog:isShow]

#define IsStrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) || ![(_ref) isKindOfClass:[NSString class]] ||([(_ref)isEqualToString:@""]))

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
#endif /* Config_h */
