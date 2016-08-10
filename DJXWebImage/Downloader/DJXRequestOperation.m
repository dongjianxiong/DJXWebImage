//
//  DJXURLConnectionOperation.m
//  DJXComNetworking
//
//  Created by umeng on 15/8/15.
//  Copyright (c) 2015年 dongjianxiong. All rights reserved.
//

#import "DJXRequestOperation.h"
#import <UIKit/UIKit.h>
#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"
#import "DJXCacheManager.h"

//OSSpinLock
//OSSpinLockLock(&_lock);
//OSSpinLockUnlock(&_lock);

static inline UIImage *SDScaledImageForKey(NSString *key, UIImage *image) {
    if (!image) {
        return nil;
    }
    
    if ([image.images count] > 0) {
        NSMutableArray *scaledImages = [NSMutableArray array];
        
        for (UIImage *tempImage in image.images) {
            [scaledImages addObject:SDScaledImageForKey(key, tempImage)];
        }
        
        return [UIImage animatedImageWithImages:scaledImages duration:image.duration];
    }
    else {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            CGFloat scale = 1;
            if (key.length >= 8) {
                NSRange range = [key rangeOfString:@"@2x."];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
                
                range = [key rangeOfString:@"@3x."];
                if (range.location != NSNotFound) {
                    scale = 3.0;
                }
            }
            
            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
        return image;
    }
}


typedef NS_ENUM(NSInteger, DJXOperationState) {
    DJXOperationPausedState      = -1,
    DJXOperationReadyState       = 1,
    DJXOperationExecutingState   = 2,
    DJXOperationFinishedState    = 3,
};

static dispatch_group_t operation_completion_group ()
{
    static dispatch_group_t operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operation_completion_group = dispatch_group_create();
    });
    return operation_completion_group;
}

static dispatch_queue_t operation_completion_queue()
{
    static dispatch_queue_t operation_completion_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operation_completion_queue = dispatch_queue_create("com.dongjianxiong.operation.queue", DISPATCH_QUEUE_CONCURRENT);
    });
    return operation_completion_queue;
}


static dispatch_group_t http_request_operation_completion_group() {
    static dispatch_group_t af_http_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_http_request_operation_completion_group = dispatch_group_create();
    });
    return af_http_request_operation_completion_group;
}


static dispatch_queue_t operation_processing_queue ()
{
    static dispatch_queue_t operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operation_processing_queue = dispatch_queue_create("com.dongjianxiong.operation.procesing", DISPATCH_QUEUE_CONCURRENT);
    });
    return operation_processing_queue;
}



static inline NSString * DJXKeyPathFromOperationState(DJXOperationState state) {
    switch (state) {
        case DJXOperationReadyState:
            return @"isReady";
        case DJXOperationExecutingState:
            return @"isExecuting";
        case DJXOperationFinishedState:
            return @"isFinished";
        case DJXOperationPausedState:
            return @"isPaused";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}


static inline BOOL DJXStateTransitionIsValid(DJXOperationState fromState, DJXOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case DJXOperationReadyState:
            switch (toState) {
                case DJXOperationPausedState:
                case DJXOperationExecutingState:
                    return YES;
                case DJXOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case DJXOperationExecutingState:
            switch (toState) {
                case DJXOperationPausedState:
                case DJXOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case DJXOperationFinishedState:
            return NO;
        case DJXOperationPausedState:
            return toState == DJXOperationReadyState;
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            switch (toState) {
                case DJXOperationPausedState:
                case DJXOperationReadyState:
                case DJXOperationExecutingState:
                case DJXOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        }
#pragma clang diagnostic pop
    }
}


@interface DJXRequestOperation ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, strong, readwrite) NSMutableData *mutableData;

@property (nonatomic, strong) NSArray *runLoopModes;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, assign) DJXOperationState state;

@property (nonatomic, assign) NSInteger totalBytesRead;

@property (nonatomic, strong) NSString *imageUrl;

@end

@implementation DJXRequestOperation

@synthesize outputStream = _outputStream;

+ (NSMutableDictionary *)cacheResponse;
{
    static NSMutableDictionary *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[NSMutableDictionary alloc] init];
        }
    });
    return instance;
}

+ (void)networkEntryPoint:(id)__unused object
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.djx.DJXNetworking"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
        [runLoop run];
    }
}

+ (NSThread *)networkManagerThread
{
    static NSThread *networkThread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!networkThread) {
            networkThread = [[NSThread alloc]initWithTarget:self selector:@selector(networkEntryPoint:) object:nil];
            [networkThread start];
        }
    });
    return networkThread;
}


- (instancetype)initWithRequest:(NSMutableURLRequest *)request
{
    self = [super init];
    if (self) {
        NSDictionary *heard = [[[self class] cacheResponse] objectForKey:[request.URL absoluteString]];
        [request setValue:[heard valueForKey:@"ETag"] forHTTPHeaderField:@"If-None-Match"];
        [request setValue:[heard valueForKey:@"Last-Modified"] forHTTPHeaderField:@"If-Modified-Since"];

        _state = DJXOperationReadyState;
        self.request = request;
        self.lock = [[NSRecursiveLock alloc]init];
        self.mutableData = [NSMutableData data];
        self.runLoopModes = @[NSRunLoopCommonModes];
    }
    return self;
}

- (instancetype)initWithImageUrlString:(NSString *)urlString
{
    self.imageUrl = urlString;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    request.HTTPShouldUsePipelining = YES;
    request.HTTPShouldHandleCookies = YES;
    self = [self initWithRequest:request];
    if (self) {
        
    }
    return self;
}

- (NSOutputStream *)outputStream
{
    if (!_outputStream) {
        _outputStream = [NSOutputStream outputStreamToMemory];
    }
    return _outputStream;
}

- (void)setOutputStream:(NSOutputStream *)outputStream
{
    [self.lock lock];
    if (outputStream != _outputStream) {
        if (_outputStream) {
            [_outputStream close];
        }
    }
    [self.lock unlock];
}

- (void)setState:(DJXOperationState)state {
    
    if (!DJXStateTransitionIsValid(self.state, state, [self isCancelled])) {
        return;
    }
    [self.lock lock];
    NSString *oldStateKey = DJXKeyPathFromOperationState(self.state);
    NSString *newStateKey = DJXKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (void)pause
{
    if ([self isPaused]||[self isFinished] || [self isCancelled]) {
        return;
    }
    [self.lock lock];
    if ([self isExecuting]) {
        [self performSelector:@selector(operationDidPause) onThread:[[self class] networkManagerThread] withObject:nil waitUntilDone:NO modes:[self runLoopModes]];
    }
    self.state = DJXOperationPausedState;
    [self.lock unlock];
}

- (void)operationDidPause {
    [self.lock lock];
    [self.connection cancel];
    [self.lock unlock];
}

- (BOOL)isPaused
{
    return self.state == DJXOperationPausedState;
}

- (void)resume
{
    if (![self isPaused]) {
        return;
    }
    [self.lock lock];
    self.state = DJXOperationReadyState;
    [self start];
    [self.lock unlock];
}

- (BOOL)isReady
{
    return self.state == DJXOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == DJXOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == DJXOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

#pragma mark - operation

- (void)setCompletionBlock:(void (^)(void))completionBlock
{
    [self.lock lock];
    if (!completionBlock) {
        [super setCompletionBlock:nil];
    }else{
        __weak typeof(self) weakSelf = self;
        [super setCompletionBlock:^(){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_group_t group = strongSelf.completionGroup ?: operation_completion_group();
            dispatch_queue_t queue = strongSelf.completionQueue ?: dispatch_get_main_queue();
            dispatch_group_async(group, queue, ^{
                completionBlock();
            });
            dispatch_group_notify(group, operation_completion_queue(), ^{
                [strongSelf setCompletionBlock:nil];
            });
        }];
    }
    [self.lock unlock];
}


- (void)setCompletionBlockWithFinishHandler:(void (^)(DJXRequestOperation *operation, id responeObject, NSError *error))completionBlock
{
    __weak typeof(self) weakSelf = self;
    self.completionBlock = ^(){
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (weakSelf.completionGroup) {
            dispatch_group_enter(strongSelf.completionGroup);
        }
        dispatch_async(operation_processing_queue(), ^{
            if (strongSelf.error) {
                if (completionBlock) {
                    dispatch_group_async(strongSelf.completionGroup ?: http_request_operation_completion_group(), strongSelf.completionQueue ?: dispatch_get_main_queue(), ^{
                        completionBlock(strongSelf, nil, strongSelf.error);
                    });
                }
            } else {
                if (completionBlock) {
                    dispatch_group_async(strongSelf.completionGroup ?: http_request_operation_completion_group(), strongSelf.completionQueue ?: dispatch_get_main_queue(), ^{
                        completionBlock(strongSelf, strongSelf.responseObject, nil);
                    });
                }
            }
            if (strongSelf.completionGroup) {
                dispatch_group_leave(strongSelf.completionGroup);
            }
        });
    };
}



- (void)start
{
    [self.lock lock];
    if ([self isCancelled]) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkManagerThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
    }else if ([self isReady]){
        self.state = DJXOperationExecutingState;
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkManagerThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
    }
    [self.lock unlock];
}


- (void)operationDidStart
{
    [self.lock lock];
    if (![self isCancelled]) {
        self.connection = [[NSURLConnection alloc]initWithRequest:self.request delegate:self startImmediately:NO];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
        }
        [self.outputStream open];
        [self.connection start];
    }
    [self.lock unlock];
}

- (void)finish {
    [self.lock lock];
    self.state = DJXOperationFinishedState;
    [self.lock unlock];
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        
        if ([self isExecuting]) {
            [self performSelector:@selector(cancelConnection) onThread:[[self class] networkManagerThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
        }
    }
    [self.lock unlock];
}

- (void)cancelConnection
{
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    if (![self isFinished]) {
        if (self.connection) {
            [self.connection cancel];
            [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:error];
        }else{
            self.error = error;
            [self finish];
        }
    }
}

#pragma mark URLConnectionDelegate Method 
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    return request;
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringCacheData) {
        return nil;
    }
    NSMutableDictionary *mutableUserInfo = [[cachedResponse userInfo] mutableCopy];
    NSMutableData *mutableData = [[cachedResponse data] mutableCopy];
    NSURLCacheStoragePolicy storagePolicy = NSURLCacheStorageAllowed;
        // ...
//    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[cachedResponse response];
//    [response.allHeaderFields setValue:@"max-age=2,max-age=2" forKey:@"Cache-Control"];
    
    return [[NSCachedURLResponse alloc] initWithResponse:[cachedResponse response]
                                                    data:mutableData
                                                userInfo:mutableUserInfo
                                           storagePolicy:storagePolicy];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
    if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        if (![[DJXRequestOperation cacheResponse] objectForKey:[urlResponse.URL absoluteString]]) {
            [[DJXRequestOperation cacheResponse] setObject:urlResponse.allHeaderFields forKey:[urlResponse.URL absoluteString]];
        }else{
            NSLog(@"response is %@", response);
        }
    }

    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger length = [data length];
    while (YES) {
        NSInteger totalNumberOfBytesWritten = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];
            
            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < (NSInteger)length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[(NSUInteger)totalNumberOfBytesWritten] maxLength:(length - (NSUInteger)totalNumberOfBytesWritten)];
                if (numberOfBytesWritten == -1) {
                    break;
                }
                totalNumberOfBytesWritten += numberOfBytesWritten;
            }
            break;
        }
        if (self.outputStream.streamError) {
            [self.connection cancel];
            [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:self.outputStream.streamError];
            return;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalBytesRead += (long long)length;
        
        if (self.downloadProgress) {
            self.downloadProgress(length, self.totalBytesRead, self.response.expectedContentLength);
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.mutableData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self.outputStream close];
    if (self.mutableData) {
        self.outputStream = nil;
        UIImage *image = [UIImage sd_imageWithData:self.mutableData];
        NSString *key = [self.request.URL absoluteString];
        image = SDScaledImageForKey(key, image);
        BOOL ifDecoder = NO;
        if (ifDecoder) {
            image = [[self class] decodedImageWithImage:image];
        }
        if (image.size.width == 0 && image.size.height == 0) {
            self.error = [NSError errorWithDomain:@"DJXWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}];
            self.responseObject = nil;
        }else{
            self.responseObject = image;
        }
        [self saveImage:image];
    }
    self.connection = nil;
    [self finish];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    
    [self.outputStream close];
    if (self.mutableData) {
        self.outputStream = nil;
    }
    self.connection = nil;
    [self finish];
}


- (void)saveImage:(UIImage *)image
{
    NSString *content_type = nil;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSDictionary *head = [(NSHTTPURLResponse *)self.response allHeaderFields];
        content_type = [head valueForKey:@"Content-Type"];
    }
    if (![content_type isKindOfClass:[NSString class]] || content_type.length == 0) {
        content_type = [NSData sd_contentTypeForImageData:self.mutableData];
    }
    if (![self.imageUrl isKindOfClass:[NSString class]] || self.imageUrl.length == 0) {
        self.imageUrl = [self.request.URL absoluteString];
    }
    [dict setValue:content_type forKey:@"format"];
    [dict setValue:self.imageUrl forKey:@"url_str"];
    [dict setValue:self.imageUrl forKey:@"image_id"];
    [dict setValue:image forKey:@"image"];
    [[DJXCacheManager manager] insertImageModelWithAttributes:dict cacheType:0];
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    // while downloading huge amount of images
    // autorelease the bitmap context
    // and all vars to help system to free memory
    // when there are memory warning.
    // on iOS7, do not forget to call
    // [[SDImageCache sharedImageCache] clearMemory];
    
    if (image == nil) { // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
        return nil;
    }
    
    @autoreleasepool{
        // do not decode animated images
        if (image.images != nil) {
            return image;
        }
        
        CGImageRef imageRef = image.CGImage;
        
        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                         alpha == kCGImageAlphaLast ||
                         alpha == kCGImageAlphaPremultipliedFirst ||
                         alpha == kCGImageAlphaPremultipliedLast);
        if (anyAlpha) {
            return image;
        }
        
        // current
        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
        
        BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                      imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                      imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                      imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace) {
            colorspaceRef = CGColorSpaceCreateDeviceRGB();
        }
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [UIImage imageWithCGImage:imageRefWithoutAlpha
                                                         scale:image.scale
                                                   orientation:image.imageOrientation];
        
        if (unsupportedColorSpace) {
            CGColorSpaceRelease(colorspaceRef);
        }
        
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
    }
}


@end
