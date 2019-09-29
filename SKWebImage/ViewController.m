//
//  ViewController.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//
#import "SKWebImageDownloader.h"
#import "ViewController.h"
#import "SKWebImageMacros.h"
#import "SKWebImageManage.h"
//#import "UIImageView+WebCache.h"
static NSString *url =  @"https://avatars2.githubusercontent.com/u/5885635?s=460&v=4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;

@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@property (weak, nonatomic) IBOutlet UIImageView *imageView4;

@property (weak, nonatomic) IBOutlet UIImageView *imageView5;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"viewDidLoad");
   
//    [self test];
    NSDate *date1 = [NSDate date];
    NSLog(@"date1= %@",date1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //子线程网络请求
        NSDate *date2 = [NSDate date];
        NSLog(@"date2= %@",date2);
        
        
        [self performSelectorOnMainThread:@selector(onMainThread) withObject:nil waitUntilDone:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //主线程刷新数据
            NSDate *date3= [NSDate date];
            NSLog(@"date3= %@",date3);
        });
    });

}
- (void)onMainThread
{
    NSDate *date4= [NSDate date];
    NSLog(@"date4= %@",date4);
}
- (void)test {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
//    [[SKWebImageManage new]fetchImageWithKey:@"https://ss0.bdstatic.com/94oJfD_bAAcT8t7mm9GUKT-xh_/timg?image&quality=100&size=b4000_4000&sec=1568615259&di=8d3ebd57d3383903a19b6142b6a0d2ac&src=http://b-ssl.duitang.com/uploads/item/201804/14/20180414011051_bgicv.png" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
//        if (image) {
//            dispatch_main_async_safe(^{
//                self.imageView.image = image;
//            });
//        }
//    }];
//
//// self.imageView
//
//    [[SKWebImageManage new]fetchImageWithKey:@"http://b-ssl.duitang.com/uploads/item/201705/13/20170513174746_dGwY3.jpeg" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
//        if (image) {
//            dispatch_main_async_safe(^{
//                self.imageView2.image = image;
//
//            });
//        }
//    }];
//    [[SKWebImageManage new]fetchImageWithKey:@"https://timgsa.baidu.com/timg?image&quality=80&size=b10000_10000&sec=1568808186&di=b76d6bcfaeebd2b1a8bbd1a67847620a&src=http://gss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/zhidao/pic/item/ca1349540923dd54cdbb9509d109b3de9d824882.jpg" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
//        if (image) {
//            dispatch_main_async_safe(^{
//                self.imageView3.image = image;
//            });
//        }
//    }];
//
//    [[SKWebImageManage new]fetchImageWithKey:@"https://timgsa.baidu.com/timg?image&quality=80&size=b10000_10000&sec=1568808280&di=86ed58af90d56bc1dab17bb068aec47a&src=http://img4q.duitang.com/uploads/blog/201504/24/20150424162422_wscQy.jpeg" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
//        if (image) {
//            dispatch_main_async_safe(^{
//                self.imageView4.image = image;
//            });
//        }
//    }];
//    [[SKWebImageManage new]fetchImageWithKey:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1568824165016&di=b48c20176874a59eddf6b3003a43d5e4&imgtype=0&src=http%3A%2F%2Fphotocdn.sohu.com%2F20160223%2Fmp60173169_1456232942601_2.jpeg" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
//        if (image) {
//            dispatch_main_async_safe(^{
//                self.imageView5.image = image;
//                self.imageView5.highlighted = YES;
//                self.imageView5.highlightedImage = nil;
//            });
//        }
//    }];
    
//    [self.imageView5 setImageWithURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1568824165016&di=b48c20176874a59eddf6b3003a43d5e4&imgtype=0&src=http%3A%2F%2Fphotocdn.sohu.com%2F20160223%2Fmp60173169_1456232942601_2.jpeg"]];
}

@end
