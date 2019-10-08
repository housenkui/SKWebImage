//
//  ViewController.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIImageView *imageView01;
@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) NSMutableArray *dataArray;
@end
static NSString *REUSEID = @"cell";
static NSString *url00 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1568824165016&di=b48c20176874a59eddf6b3003a43d5e4&imgtype=0&src=http%3A%2F%2Fphotocdn.sohu.com%2F20160223%2Fmp60173169_1456232942601_2.jpeg";
static NSString *url01 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b10000_10000&sec=1568808280&di=86ed58af90d56bc1dab17bb068aec47a&src=http://img4q.duitang.com/uploads/blog/201504/24/20150424162422_wscQy.jpeg";
static NSString *url02 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b10000_10000&sec=1568808186&di=b76d6bcfaeebd2b1a8bbd1a67847620a&src=http://gss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/zhidao/pic/item/ca1349540923dd54cdbb9509d109b3de9d824882.jpg";

static NSString *url03 = @"http://b-ssl.duitang.com/uploads/item/201705/13/20170513174746_dGwY3.jpeg";

static NSString *url04 = @"https://ss0.bdstatic.com/94oJfD_bAAcT8t7mm9GUKT-xh_/timg?image&quality=100&size=b4000_4000&sec=1568615259&di=8d3ebd57d3383903a19b6142b6a0d2ac&src=http://b-ssl.duitang.com/uploads/item/201804/14/20180414011051_bgicv.png";
static NSString *url05 = @"https://www.tuchuang001.com/images/2017/05/02/1.png";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"viewDidLoad");
    self.tableView.backgroundColor = [UIColor whiteColor];
    NSDate *date1 = [NSDate date];
    NSLog(@"date1= %@",date1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //记一次主线程切换到子线程的时间 157us
        //子线程网络请求
        NSDate *date2 = [NSDate date];
        NSLog(@"date2= %@",date2);
       
        
        //这个方法比 dispatch_async 的方法慢500us左右
        [self performSelectorOnMainThread:@selector(onMainThread) withObject:nil waitUntilDone:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //记一次子线程切换到主线程的时间 162010us (这个数值的大小和CPU的负载有关系、寄存器)
            //记一次子线程切换到主线程的时间 151387us (这个数值的大小和CPU的负载有关系、寄存器)

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
- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc]initWithObjects:url00,url01,url02,url03,url04,nil];
    }
    return _dataArray;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:REUSEID];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 5;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell  =[tableView dequeueReusableCellWithIdentifier:REUSEID];
    UIImage *placeholder = [UIImage imageNamed:@"placeholder.jpeg"];
//    [cell.imageView setImageWithURL:[NSURL URLWithString:self.dataArray[indexPath.row]] placeholderImage:nil];
    [cell.imageView setImageWithURL:[NSURL URLWithString:self.dataArray[indexPath.row]] placeholderImage:placeholder options:0 success:^(UIImage * _Nonnull image,BOOL cache) {
        NSLog(@"cellForRowAtIndexPath");
    } failure:^(NSError * _Nonnull error) {

    }];

    cell.textLabel.text = [NSString stringWithFormat:@"{%ld-%ld}",(long)indexPath.section,(long)indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"indexPath = %@",indexPath);
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UILabel *lable = [[UILabel alloc]init];
    lable.backgroundColor = [UIColor grayColor];
    lable.text = [NSString stringWithFormat:@"section %ld footer",section];
    return lable;
}

@end
