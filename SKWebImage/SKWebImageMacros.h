//
//  SKWebImageMacros.h
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/15.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#ifndef SKWebImageMacros_h
#define SKWebImageMacros_h

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif
#endif /* SKWebImageMacros_h */
