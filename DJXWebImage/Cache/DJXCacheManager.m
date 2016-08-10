//
//  DJXCacheManager.m
//  DJXWebImage
//
//  Created by umeng on 16/7/23.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXCacheManager.h"
#import "DJXCoreDataManager.h"
#import "DJXRequestOperation.h"
#import "DJXImageModel.h"


@interface DJXCacheManager ()

@property (nonatomic, strong) NSCache *backingObjectIDByObjectID;

@property (nonatomic, strong) NSCache *imageCache;

@end

@implementation DJXCacheManager



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
}

+ (DJXCacheManager *)manager
{
    return [[self alloc]init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backingObjectIDByObjectID = [[NSCache alloc] init];
        self.imageCache = [[NSCache alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)imageWithImageUrl:(NSString *)imageUrl
                cacheType:(NSInteger)cacheType
               completion:(DJXLocalDataFinishHandler)completion
{
    NSManagedObjectContext *context = [DJXCoreDataManager defaultManager].managedObjectContext;
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    [childContext performBlock:^{
        DJXImageModel *imageModel = [self imageModelWithImageUrlString:imageUrl];
        UIImage *image = imageModel.image;
        NSData *data = imageModel.data;
        [context performBlock:^{
            if (completion) {
                completion(data, image, nil);
            }
        }];
    }];
}

- (DJXImageModel *)imageModelWithImageUrlString:(NSString *)urlString
{
    DJXImageModel *imageModel = (DJXImageModel *)[self objectWithEntityName:@"ImageModel" imageUrlString:urlString];
    return imageModel;
}


- (void)insertImageModelWithAttributes:(NSDictionary *)attributes
                             cacheType:(NSInteger)cacheType
{
    NSManagedObjectContext *context = [DJXCoreDataManager defaultManager].backManagedObjectContext;
    NSString * objectIdentifier = [attributes valueForKey:@"url_str"];
    __block NSManagedObject *imageModel = (DJXImageModel *)[self objectWithEntityName:@"ImageModel" imageUrlString:objectIdentifier];
    if (!imageModel) {
        [context performBlockAndWait:^{
            imageModel = [NSEntityDescription insertNewObjectForEntityForName:@"ImageModel" inManagedObjectContext:context];
            [imageModel.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:imageModel] error:nil];
        }];
    }
    [imageModel setValue:objectIdentifier forKey:kDJXImageIncrementalStoreResourceIdentifierAttributeName];
    [imageModel setValuesForKeysWithDictionary:attributes];
    [context performBlockAndWait:^{
        [context save:nil];
    }];
}



- (NSManagedObject *)objectWithEntityName:(NSString *)entityName
                           imageUrlString:(NSString *)urlString
{
    NSString * objectIdentifier = urlString;
    
    if (!objectIdentifier) {
        return nil;
    }
    NSManagedObject *managedObject = nil;
    NSManagedObjectContext *context = [DJXCoreDataManager defaultManager].backManagedObjectContext;
    NSEntityDescription *entityDes = [NSEntityDescription entityForName:@"ImageModel" inManagedObjectContext:context];
    __block NSManagedObjectID *backingObjectID = [self objectIDForBackingObjectForEntity:entityDes withResourceIdentifier:objectIdentifier];
    if (backingObjectID) {
        managedObject = [context existingObjectWithID:backingObjectID error:nil];
    }
    return managedObject;
}


- (NSManagedObjectID *)objectIDForBackingObjectForEntity:(NSEntityDescription *)entity
                                  withResourceIdentifier:(NSString *)resourceIdentifier
{
    if (!resourceIdentifier) {
        return nil;
    }
    __block NSManagedObjectID *backingObjectID = [_backingObjectIDByObjectID objectForKey:resourceIdentifier];
    if (backingObjectID) {
        return backingObjectID;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[entity name]];
    fetchRequest.resultType = NSManagedObjectIDResultType;
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K=%@",kDJXImageIncrementalStoreResourceIdentifierAttributeName, resourceIdentifier];
    
    __block NSError *error = nil;
    NSManagedObjectContext *backingContext = [DJXCoreDataManager defaultManager].backManagedObjectContext;
    @try {
        [backingContext performBlockAndWait:^{
            backingObjectID = [[backingContext executeFetchRequest:fetchRequest error:&error] lastObject];
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"exception is %@",exception);
    }
    
    if (backingObjectID) {
        [_backingObjectIDByObjectID setObject:backingObjectID forKey:resourceIdentifier];
    }
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    return backingObjectID;
}

@end
