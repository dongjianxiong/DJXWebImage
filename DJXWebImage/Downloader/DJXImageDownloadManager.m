//
//  DJXImageDownloadManager.m
//  DJXWebImage
//
//  Created by umeng on 16/8/10.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "DJXImageDownloadManager.h"
#import "DJXCoreDataManager.h"
#import "DJXRequestOperation.h"
#import "DJXImageModel.h"

@interface DJXImageDownloadManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSCache *backingObjectIDByObjectID;

@property (nonatomic, strong) NSCache *imageCache;

@end
@implementation DJXImageDownloadManager


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
}

+ (DJXImageDownloadManager *)manager
{
    return [[self alloc]init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc]init];
        self.backingObjectIDByObjectID = [[NSCache alloc] init];
        self.imageCache = [[NSCache alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}


- (DJXRequestOperation *)imageDataWithImageUrl:(NSString *)imageUrl
                                      progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                                    completion:(DJXWebImageDownloaderCompletedBlock)completion
{

    DJXRequestOperation *operation = [[DJXRequestOperation alloc] initWithImageUrlString:imageUrl];
    operation.completionQueue = self.completionQueue;
    operation.completionGroup = self.completionGroup;
    operation.downloadProgress = ^(NSUInteger bytes, long long totalBytes, long long totalBytesExpected){
        if (progressBlock) {
            progressBlock(totalBytes,totalBytesExpected);
        }
    };
    [operation setCompletionBlockWithFinishHandler:^(DJXRequestOperation *operation, id responeObject, NSError *error) {
        if (completion) {
            completion(responeObject, operation.mutableData, error, YES);
        }
    }];
    [self.operationQueue addOperation:operation];
    return operation;
}

- (NSString *)djx_contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"image/webp";
            }
            
            return nil;
    }
    return nil;
}


- (DJXImageModel *)imageModelWithImageUrlString:(NSString *)urlString
{
    DJXImageModel *imageModel = (DJXImageModel *)[self objectWithEntityName:@"ImageModel" imageUrlString:urlString];
    return imageModel;
}

- (void)insertImageModelWithAttributes:(NSDictionary *)attributes
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



- (NSManagedObject *)objectWithEntityName:(NSString *)entityName imageUrlString:(NSString *)urlString
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