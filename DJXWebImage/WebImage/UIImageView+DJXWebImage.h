//
//  UIImageView+DJXWebImage.h
//  DJXWebImage
//
//  Created by umeng on 16/7/24.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DJXImageDownloadManager.h"

typedef enum {
    DJXImageLoadingStyle_activitive = 0,
    DJXImageLoadingStyle_circle,
    DJXImageLoadingStyle_none,
}DJXImageLoadingStyle;



@interface UIImageView (DJXWebImage)

@property (nonatomic, assign) DJXImageLoadingStyle loadingStyle;

@property (nonatomic, assign) BOOL isNeedCropImage;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                             scale:(CGFloat)scale;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                        completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder
                        completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void)djx_setImageWithUrlString:(NSString *)imageUrl
                            scale:(CGFloat)scale
                       completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder
                             scale:(CGFloat)scale completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                          progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                        completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder
                          progress:(DJXWebImageDownloaderProgressBlock)progressBlock
                        completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;

- (void) djx_setImageWithUrlString:(NSString *)imageUrl
                       placeHolder:(UIImage *)placeHolder
                             scale:(CGFloat)scale
                          progress:(DJXWebImageDownloaderProgressBlock)progressBlock completion:(DJXWebImageDownloaderCompletedBlock)completionBlock;



@end
