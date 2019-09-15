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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"viewDidLoad");
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [[SKWebImageManage manager]fetchImageWithKey:url completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (image) {
            dispatch_main_async_safe(^{
                self.imageView.image = image;
            });
        }
    }];
}

@end
