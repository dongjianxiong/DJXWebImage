//
//  ViewController.m
//  DJXWebImage
//
//  Created by umeng on 16/7/23.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+DJXWebImage.h"
#import "DJXImageCell.h"
#import "DJXTableViewController.h"




@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *imageUrlArray;




@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 200;
    [self.tableView registerClass:[DJXImageCell class] forCellReuseIdentifier:@"cellID"];
    [self.view addSubview:self.tableView];
    
    self.imageUrlArray = [NSArray arrayWithObjects:@"http://pic29.nipic.com/20130508/9252150_163600489317_2.jpg",@"http://www.pptbz.com/pptpic/UploadFiles_6909/201204/2012041411433867.jpg",@"http://tu.qiumibao.com/uploads/day_160807/201608070254387734.png",@"http://pic7.nipic.com/20100519/2088016_220212106210_2.jpg",@"http://picm.photophoto.cn/005/008/007/0080071732.jpg",@"http://img.taopic.com/uploads/allimg/110720/6442-110H01U054100.jpg",@"http://pic10.nipic.com/20100927/2457331_105358511000_2.jpg",@"http://down.tutu001.com/d/file/20111024/05e15ef6bfe7c8793215110771_560.jpg",@"http://www.xxjxsj.cn/article/UploadPic/2009-7/200972521575027249.jpg",@"http://pic28.nipic.com/20130415/11038568_140348200000_2.jpg",@"http://picm.photophoto.cn/005/008/009/0080090218.jpg",@"http://pic26.nipic.com/20121217/9252150_110558501000_2.jpg",@"http://pic65.nipic.com/file/20150426/5848774_105635047000_2.jpg",@"http://m2.quanjing.com/2m/top018/top-726631.jpg", nil];
    

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 100, 50);
    [button addTarget:self action:@selector(reloadImage) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    
//    [self initScaleLayer];
//    [self initGroupLayer];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.imageUrlArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cellID";
    DJXImageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[DJXImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    [cell.djx_setImageView djx_setImageWithUrlString:self.imageUrlArray[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DJXTableViewController *tableVc = [[DJXTableViewController alloc] init];
    [self.navigationController pushViewController:tableVc animated:YES];
}

- (void)reloadImage
{
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0],[NSIndexPath indexPathForRow:1 inSection:0],[NSIndexPath indexPathForRow:2 inSection:0],[NSIndexPath indexPathForRow:3 inSection:0],[NSIndexPath indexPathForRow:4 inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView reloadData];
}



- (void)initScaleLayer
{
    //演员初始化
    CALayer *scaleLayer = [[CALayer alloc] init];
    scaleLayer.backgroundColor = [UIColor blueColor].CGColor;
    scaleLayer.frame = CGRectMake(60, 20 + 100, 50, 50);
    scaleLayer.cornerRadius = 10;
    [self.view.layer addSublayer:scaleLayer];
    
    //设定剧本
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:2.5];
    scaleAnimation.autoreverses = YES;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.repeatCount = MAXFLOAT;
    scaleAnimation.duration = 0.2;
    //开演
    [scaleLayer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
}

- (void)initGroupLayer
{
    //演员初始化
    CALayer *groupLayer = [[CALayer alloc] init];
    groupLayer.frame = CGRectMake(60, 340+100 + 100, 50, 50);
    groupLayer.cornerRadius = 10;
    groupLayer.backgroundColor = [[UIColor purpleColor] CGColor];
    [self.view.layer addSublayer:groupLayer];
    
    //设定剧本
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1.5];
    scaleAnimation.autoreverses = YES;
    scaleAnimation.repeatCount = MAXFLOAT;
    scaleAnimation.duration = 0.8;
    
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.fromValue = [NSValue valueWithCGPoint:groupLayer.position];
    moveAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(320 - 80,
                                                                  groupLayer.position.y)];
    moveAnimation.autoreverses = YES;
    moveAnimation.repeatCount = MAXFLOAT;
    moveAnimation.duration = 2;
    
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    rotateAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    rotateAnimation.toValue = [NSNumber numberWithFloat:6.0 * M_PI];
    rotateAnimation.autoreverses = YES;
    rotateAnimation.repeatCount = MAXFLOAT;
    rotateAnimation.duration = 2;
    
    CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
    groupAnnimation.duration = 2;
    groupAnnimation.autoreverses = YES;
    groupAnnimation.animations = @[moveAnimation, scaleAnimation, rotateAnimation];
    groupAnnimation.repeatCount = MAXFLOAT;
    //开演
    [groupLayer addAnimation:groupAnnimation forKey:@"groupAnnimation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
