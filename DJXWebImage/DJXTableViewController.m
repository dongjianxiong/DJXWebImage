//
//  DJXTableViewController.m
//  DJXWebImage
//
//  Created by umeng on 16/7/25.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXTableViewController.h"
#import "DJXImageCell.h"
#import "UIImageView+DJXWebImage.h"

@interface DJXTableViewController ()

@property (nonatomic, strong) NSArray *imageUrlArray;

@end

@implementation DJXTableViewController

- (void)viewDidLoad
{
    self.tableView.rowHeight = 200;
    [self.tableView registerClass:[DJXImageCell class] forCellReuseIdentifier:@"cellID"];
    
    self.imageUrlArray = [NSArray arrayWithObjects:@"http://pic29.nipic.com/20130508/9252150_163600489317_2.jpg",@"http://www.pptbz.com/pptpic/UploadFiles_6909/201204/2012041411433867.jpg",@"http://img10.3lian.com/c1/newpic/10/08/04.jpg",@"http://pic7.nipic.com/20100519/2088016_220212106210_2.jpg",@"http://picm.photophoto.cn/005/008/007/0080071732.jpg",@"http://img.taopic.com/uploads/allimg/110720/6442-110H01U054100.jpg",@"http://pic10.nipic.com/20100927/2457331_105358511000_2.jpg",@"http://down.tutu001.com/d/file/20111024/05e15ef6bfe7c8793215110771_560.jpg",@"http://www.xxjxsj.cn/article/UploadPic/2009-7/200972521575027249.jpg",@"http://pic28.nipic.com/20130415/11038568_140348200000_2.jpg",@"http://picm.photophoto.cn/005/008/009/0080090218.jpg",@"http://pic26.nipic.com/20121217/9252150_110558501000_2.jpg",@"http://pic65.nipic.com/file/20150426/5848774_105635047000_2.jpg",@"http://m2.quanjing.com/2m/top018/top-726631.jpg", nil];
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
    [cell.djx_setImageView djx_setImageWithUrlString:self.imageUrlArray[indexPath.row] placeHolder:nil];
    return cell;
}


@end
