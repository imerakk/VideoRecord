//
//  MLHShortVideoRecordView.h
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/1.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MLHVideoRecord;

@interface MLHShortVideoRecordView : UIView

@property (nonatomic, assign) CGFloat maxRecordTime; /* default 10.0 */
@property (nonatomic, copy) void (^finishBlock)(UIImage *image, NSURL *videoUrl);
@property (nonatomic, assign) BOOL disableTakePhoto;
@property (nonatomic, assign) BOOL disableVideoRecord;

- (void)presentView;
- (void)closeView;

@end
