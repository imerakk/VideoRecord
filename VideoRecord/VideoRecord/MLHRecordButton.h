//
//  MLHRecordButton.h
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/2/28.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MLHTouchType) {
    MLHTouchTypeLongPress = 0,
    MLHTouchTypeTap
};

@class MLHRecordButton;

@protocol MLHRecordButtonDelegate <NSObject>

- (void)recordButtonStart:(MLHRecordButton *)recordButton withTouchType:(MLHTouchType)touchType;
- (void)recordButtonStop:(MLHRecordButton *)recordButton withTouchType:(MLHTouchType)touchType;

@end

@interface MLHRecordButton : UIView

@property (weak, nonatomic) id<MLHRecordButtonDelegate> myDelegate;
@property (assign, nonatomic) CGFloat animationDuration;
/** 内圈半径,default 30.0 **/
@property (assign, nonatomic) CGFloat smallCircleRadius;
@property (nonatomic, assign) BOOL disableLongPressGest;

- (void)startAnimation;
- (void)stopAnimation;

@end
