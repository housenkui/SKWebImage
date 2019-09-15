//
//  SKWebImageManage.h
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef void(^SKWebImagefetchImageCompletedBlock)(UIImage * _Nullable image,NSError * _Nullable error);

@interface SKWebImageManage : NSObject
+ (instancetype)manager;
- (void)fetchImageWithKey:(NSString *)key completed:(SKWebImagefetchImageCompletedBlock) fetchImageCompletedBlock;
    
@end

NS_ASSUME_NONNULL_END
