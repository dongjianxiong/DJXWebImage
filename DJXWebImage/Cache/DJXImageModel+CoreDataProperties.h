//
//  DJXImageModel+CoreDataProperties.h
//  DJXWebImage
//
//  Created by umeng on 16/7/25.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DJXImageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DJXImageModel (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *format;
@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, retain) NSString *url_str;
@property (nullable, nonatomic, retain) NSString *image_id;
@property (nullable, nonatomic, retain) id image;

@end

NS_ASSUME_NONNULL_END
