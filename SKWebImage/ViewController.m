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
static NSString *url =  @"https://avatars2.githubusercontent.com/u/5885635?s=460&v=4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
    
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"viewDidLoad");
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"11111");
    }];
    [blockOperation addExecutionBlock:^{
        NSLog(@"2222");
    }];
    [blockOperation start];
    
    
    NSMutableDictionary *mdict = [[NSMutableDictionary alloc]init];
    [mdict setObject:@"111" forKey:[NSURL URLWithString:@"1111"]];
    
    NSString *string = [mdict objectForKey:[NSURL URLWithString:@"1111"]];
    NSLog(@"string = %@",string);
  
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    [[SKWebImageManage new]fetchImageWithKey:@"https://ss0.bdstatic.com/94oJfD_bAAcT8t7mm9GUKT-xh_/timg?image&quality=100&size=b4000_4000&sec=1568615259&di=8d3ebd57d3383903a19b6142b6a0d2ac&src=http://b-ssl.duitang.com/uploads/item/201804/14/20180414011051_bgicv.png" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (image) {
            dispatch_main_async_safe(^{
                self.imageView.image = image;
            });
        }
    }];
    
    [[SKWebImageManage new]fetchImageWithKey:@"http://b-ssl.duitang.com/uploads/item/201705/13/20170513174746_dGwY3.jpeg" completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (image) {
            dispatch_main_async_safe(^{
                self.imageView2.image = image;
            });
        }
    }];
}

@end
