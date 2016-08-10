//
//  DJXImageModel.h
//  DJXWebImage
//
//  Created by umeng on 16/7/25.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface DJXImageModel : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

@interface DJXImage : NSValueTransformer

//+ (UIImage *)

@end

NS_ASSUME_NONNULL_END

#import "DJXImageModel+CoreDataProperties.h"
