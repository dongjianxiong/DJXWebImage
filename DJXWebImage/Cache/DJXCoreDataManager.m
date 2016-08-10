//
//  DJXCoreDataManager.m
//  DJXWebImage
//
//  Created by umeng on 16/7/23.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXCoreDataManager.h"

//extern NSString *const kUMCommanagedObjectContextDidMergeNotification;
static NSString *const kUMCommanagedObjectContextDidMergeNotification = @"kUMCommanagedObjectContextDidMergeNotification";
NSString * const kDJXImageIncrementalStoreResourceIdentifierAttributeName = @"__DJXImage_resourceIdentifier";



@implementation DJXCoreDataManager

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


+ (DJXCoreDataManager *)defaultManager
{
    static DJXCoreDataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[[self class] alloc] init];
        }
    });
    return instance;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          if (note.object == _managedObjectContext) {
                                                              return;
                                                          }
                                                          NSManagedObjectContext *noteContext = note.object;
                                                          if (noteContext.persistentStoreCoordinator != coordinator) {
                                                              return;
                                                          }
                                                          
                                                          [_managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                          
                                                      }];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)backManagedObjectContext {
    if (!_backManagedObjectContext) {
        _backManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backManagedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
        _backManagedObjectContext.retainsRegisteredObjects = YES;
        [_backManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];//
    }
    return _backManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DJXWebImage" withExtension:@"momd"];
    if (!modelURL) {
        modelURL = [[NSBundle mainBundle] URLForResource:@"DJXWebImage" withExtension:@"mom"];
    }
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSManagedObjectModel *model = [managedObjectModel mutableCopy];
    for (NSEntityDescription *entity in model.entities) {
        if ([entity superentity]) {
            continue;
        }
        NSAttributeDescription *resourceIdentifierProperty = [[NSAttributeDescription alloc] init];
        [resourceIdentifierProperty setName:kDJXImageIncrementalStoreResourceIdentifierAttributeName];
        [resourceIdentifierProperty setAttributeType:NSStringAttributeType];
        [resourceIdentifierProperty setIndexed:YES];
        [entity setProperties:[entity.properties arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:resourceIdentifierProperty, nil]]];
    }
    _managedObjectModel = model;
    return _managedObjectModel;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DJXWebImage.sqlite"];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption: @(YES)
                              };
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:nil]) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        NSError * error = nil;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        }
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.backManagedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}
- (void)didEnterBackground
{
    [[DJXCoreDataManager defaultManager].backManagedObjectContext performBlockAndWait:^{
        [[DJXCoreDataManager defaultManager] saveContext];
    }];
}
- (void)didTerminate
{
    [self saveContext];

//    //清空coredata数据
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"UMComModel.sqlite"];
//    NSDictionary *fileAttributeDic=[[NSFileManager defaultManager] attributesOfItemAtPath:storeURL.path error:nil];
//    if ([fileAttributeDic fileSize] > 1024*1024*30) {
//        
//        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"UMComModel.sqlite"];
//        NSError *error = nil;
//        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
//        
//        self.managedObjectContext = nil;
//        self.backManagedObjectContext = nil;
//        self.persistentStoreCoordinator = nil;
//    }else{
//        [self saveContext];
//        
//    }
}

@end
