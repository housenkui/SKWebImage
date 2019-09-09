//
//  ViewController.m
//  SKWebImage
//
//  Created by 侯森魁 on 2019/9/8.
//  Copyright © 2019 侯森魁. All rights reserved.
//
#import "SKWebImageDownloader.h"
#import "ViewController.h"

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif
static NSString *url =  @"https://avatars2.githubusercontent.com/u/5885635?s=460&v=4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong,nonatomic) NSURLSession *session;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [[SKWebImageDownloader sharedDownloader]downloadImageWithURL:[NSURL URLWithString:@"https://avatars2.githubusercontent.com/u/5885635?s=460&v=4"] completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (image) {
            dispatch_main_async_safe(^{
                self.imageView.image = image;
            });
        }
    }];
    
}

@end
