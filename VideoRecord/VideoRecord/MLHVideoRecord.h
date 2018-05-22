//
//  MLHVideoRecord.h
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/2.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class MLHVideoRecord;

typedef NS_ENUM(NSUInteger, MLHVideoRecordCompressQuality) {
    MLHVideoRecordCompressQualityLow = 0,
    MLHVideoRecordCompressQualityMedium,
    MLHVideoRecordCompressQualityHigh
};

typedef NS_ENUM(NSUInteger, MLHVideoRecordState) {
    MLHVideoRecordStateInit = 0,
    MLHVideoRecordStatePrepareRecord,
    MLHVideoRecordStateStart,
    MLHVideoRecordStatePause,
    MLHVideoRecordStateFinish
};

@protocol MLHVideoRecordDelegate <NSObject>

- (void)updateRecordState:(MLHVideoRecordState)recordState;

- (void)interruptedRecord:(MLHVideoRecord *)videoRecord;

@end

@interface MLHVideoRecord : NSObject

@property (weak, nonatomic) id<MLHVideoRecordDelegate> myDelegate;
@property (assign, nonatomic, readonly) MLHVideoRecordState recordState;
@property (strong, nonatomic, readonly) NSURL *videoUrl;
@property (assign, nonatomic, readonly) CGFloat zoomFactor;

- (instancetype)initWithSuperView:(UIView *)superView delegate:(id<MLHVideoRecordDelegate>)delegate;
- (void)compressVideoWithUrl:(NSURL *)originVideoUrl compressQuality:(MLHVideoRecordCompressQuality)compressQuality competionBlock:(void (^)(NSURL *compressVideoUrl))competionBlock;
- (BOOL)clearOriginVideos;
//- (void)reset;

/** 录制 */
- (void)setVideoZoomFactor:(CGFloat)zoomFactor;
- (void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point;
- (void)switchCameraAction;
- (void)startRecord;
- (void)stopRecord;

/** 拍照 */
- (void)takePicture:(void (^)(UIImage *))picture;

@end
