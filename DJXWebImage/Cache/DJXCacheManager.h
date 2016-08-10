//
//  DJXCacheManager.h
//  DJXWebImage
//
//  Created by umeng on 16/7/23.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DJXRequestOperation.h"

typedef void(^DJXLocalDataFinishHandler)(NSData *imageData, UIImage *image, NSError *error);


@interface DJXCacheManager : NSObject

+ (DJXCacheManager *)manager;

- (void)imageWithImageUrl:(NSString *)imageUrl cacheType:(NSInteger)cacheType completion:(DJXLocalDataFinishHandler)completion;

- (void)insertImageModelWithAttributes:(NSDictionary *)attributes cacheType:(NSInteger)cacheType;

@end
