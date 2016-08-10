//
//  UIImageView+DJXWebImage.m
//  DJXWebImage
//
//  Created by umeng on 16/7/24.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import "UIImageView+DJXWebImage.h"
#import "DJXCacheManager.h"
#import "DJXImageDownloadManager.h"


@implementation UIImageView (DJXWebImage)

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:nil];
}

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:placeHolder scale:1 progress:nil completion:nil];
}

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder scale:(CGFloat)scale
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:placeHolder scale:1 progress:nil completion:nil];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                            scale:(CGFloat)scale
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:nil scale:scale progress:nil completion:nil];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:nil scale:1 progress:nil completion:completionBlock];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                      placeHolder:(UIImage *)placeHolder
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:placeHolder scale:1 progress:nil completion:completionBlock];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                            scale:(CGFloat)scale
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:nil scale:scale progress:nil completion:completionBlock];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                      placeHolder:(UIImage *)placeHolder
                            scale:(CGFloat)scale
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:placeHolder scale:scale progress:nil completion:completionBlock];
}

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                         progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl progress:progressBlock completion:completionBlock];
}


- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                      placeHolder:(UIImage *)placeHolder
                         progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    [self djx_setImageWithUrlString:imageUrl placeHolder:placeHolder scale:1 progress:progressBlock completion:completionBlock];
}


- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                      placeHolder:(UIImage *)placeHolder
                            scale:(CGFloat)scale
                         progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    self.image = placeHolder;
    __weak typeof(self) weakSelf = self;
    [[DJXCacheManager manager] imageWithImageUrl:imageUrl cacheType:0 completion:^(NSData *imageData, UIImage *image, NSError *error) {
        __strong typeof(UIImageView *) strongSelf = weakSelf;
        if (image || imageData) {
            if ([[NSThread currentThread] isMainThread]) {
                strongSelf.image = image;
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.image = image;
                });
            }
        }else{
            [strongSelf djx_getRemoteImageWithUrlString:imageUrl placeHolder:placeHolder scale:scale progress:progressBlock completion:completionBlock];
        }
    }];

}

- (void)djx_getRemoteImageWithUrlString:(NSString *)imageUrl
                            placeHolder:(UIImage *)placeHolder
                                  scale:(CGFloat)scale
                               progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                             completion:(DJXWebImageDownloaderCompletedBlock)completionBlock
{
    __weak typeof(self) weakSelf = self;
    DJXRequestOperation *imageOperation = [[DJXImageDownloadManager manager] imageDataWithImageUrl:imageUrl progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completion:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
        if ([image isKindOfClass:[UIImage class]]) {
            weakSelf.image = image;
        }
    }];
    if (imageOperation) {
        NSLog(@"%@", imageOperation);
    }
}


@end
