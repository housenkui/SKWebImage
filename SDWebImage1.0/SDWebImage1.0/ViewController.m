//
//  ViewController.m
//  SDWebImage1.0
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
static NSString *url03 = @"http://b-ssl.duitang.com/uploads/item/201705/13/20170513174746_dGwY3.jpeg";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image01;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.image01 setImageWithURL:[NSURL URLWithString:url03] placeholderImage:nil completed:^(UIImage *image, NSError *error, BOOL fromCache, BOOL finished) {
        
    }];
    // Do any additional setup after loading the view.
}


@end
