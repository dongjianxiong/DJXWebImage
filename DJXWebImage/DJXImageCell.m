//
//  DJXImageCell.m
//  DJXWebImage
//
//  Created by umeng on 16/7/25.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXImageCell.h"


@implementation DJXImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.djx_setImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        [self.contentView addSubview:self.djx_setImageView];
    }
    return self;
}

@end