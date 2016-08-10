//
//  UMURLConnectionOperation.h
//  UMComNetworking
//
//  Created by umeng on 15/8/15.
//  Copyright (c) 2015年 dongjianxiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJXRequestOperation : NSOperation

@property (nonatomic, strong) dispatch_queue_t completionQueue;

@property (nonatomic, strong) dispatch_group_t completionGroup;

@property (nonatomic, strong) NSURLResponse *response;

@property (nonatomic, strong) id responseObject;

@property (nonatomic, strong, readonly) NSMutableData *mutableData;

@property (nonatomic, copy) void (^downloadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

- (instancetype)initWithImageUrlString:(NSString *)urlString;

- (void)setCompletionBlockWithFinishHandler:(void (^)(DJXRequestOperation *operation, id responeObject, NSError *error))completionBlock;

- (void)pause;

- (BOOL)isPaused;

- (void)resume;

@end
