//
//  DJXCoreDataManager.h
//  DJXWebImage
//
//  Created by umeng on 16/7/23.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

extern NSString * const kDJXImageIncrementalStoreResourceIdentifierAttributeName;


@interface DJXCoreDataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSManagedObjectContext *backManagedObjectContext;

+ (DJXCoreDataManager *)defaultManager;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end
