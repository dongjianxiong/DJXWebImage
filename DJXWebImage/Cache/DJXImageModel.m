//
//  DJXImageModel.m
//  DJXWebImage
//
//  Created by umeng on 16/7/25.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXImageModel.h"
#import <UIKit/UIKit.h>

@implementation DJXImageModel

// Insert code here to add functionality to your managed object subclass

@end

@implementation DJXImage : NSValueTransformer
+ (Class)transformedValueClass
{
    return [UIImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}


@end