//
//  MLHShortVideoRecordView.m
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/1.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import "MLHShortVideoRecordView.h"
#import "MLHRecordButton.h"
#import "MLHVideoRecord.h"
#import "MLHShortVideoPlay.h"

@interface MLHShortVideoRecordView() <CAAnimationDelegate, MLHVideoRecordDelegate, MLHRecordButtonDelegate>

@property (weak, nonatomic) MLHRecordButton *recordButton;
@property (weak, nonatomic) UIButton *closeButton;
@property (weak, nonatomic) MLHShortVideoPlay *videoPlayer;
@property (weak, nonatomic) UIImageView *focusCursorImageView;
@property (weak, nonatomic) UIImageView *photoImageView;
@property (weak, nonatomic) UIButton *backButton;
@property (weak, nonatomic) UIButton *confirmButton;
@property (weak, nonatomic) UILabel *remindLabel;

@property (assign, nonatomic) BOOL dragStart;

@property (strong, nonatomic) MLHVideoRecord *videoRecord;

@end

@implementation MLHShortVideoRecordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //检查是否有摄像头和麦克风权限
        [self checkVideoAuthority];
        
        self.maxRecordTime = 10.0;
        self.backgroundColor = [UIColor blackColor];
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        self.frame = CGRectMake(0, screenSize.height, screenSize.width, screenSize.height);
        
        //初始化UI
        [self initSubView];

        //添加视频录制
        [self addRecordView];
        
        [self addGest];
    }
    
    return self;
}

- (void)initSubView {
    //切换摄像头按钮
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame = CGRectMake(self.bounds.size.width - 50, 20, 35, 35);
    [cameraButton setBackgroundImage:[UIImage imageNamed:@"video_record_camera"] forState:UIControlStateNormal];
    [cameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [cameraButton addTarget:self action:@selector(turnCamera) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cameraButton];

    //退出按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(60, self.bounds.size.height - 100, 35, 35);
    closeButton.contentMode = UIViewContentModeScaleAspectFit;
    closeButton.imageView.contentMode = UIViewContentModeTop;
    [closeButton setBackgroundImage:[UIImage imageNamed:@"video_record_pageClose"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton = closeButton;
    [self addSubview:closeButton];
    
    //录制按钮
    MLHRecordButton *recordButton = [[MLHRecordButton alloc] init];
    recordButton.bounds = CGRectMake(0, 0, 100, 100);
    recordButton.center = CGPointMake(self.bounds.size.width / 2, closeButton.center.y);
    recordButton.myDelegate = self;
    self.recordButton = recordButton;
    [self addSubview:recordButton];
    
    CGFloat marginLeft = 60;
    CGFloat marginBottom = 50;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    //撤销按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(marginLeft, screenSize.height - marginBottom - 60, 60, 60);
    backButton.tag = 0;
    backButton.hidden = YES;
    [backButton setBackgroundImage:[UIImage imageNamed:@"video_record_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(operationFinish:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:backButton];
    self.backButton = backButton;
    
    //确认按钮
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.frame = CGRectMake(screenSize.width - marginLeft - 60, backButton.frame.origin.y, 60, 60);
    confirmButton.tag = 1;
    confirmButton.hidden = YES;
    [confirmButton addTarget:self action:@selector(operationFinish:) forControlEvents:UIControlEventTouchUpInside];
    [confirmButton setBackgroundImage:[UIImage imageNamed:@"video_record_confirm"] forState:UIControlStateNormal];
    [self addSubview:confirmButton];
    self.confirmButton = confirmButton;
    
}

- (void)addRecordView {
    MLHVideoRecord *videoRecord = [[MLHVideoRecord alloc] initWithSuperView:self delegate:self];
    self.videoRecord = videoRecord;
}

#pragma mark - lazy load
- (UIImageView *)focusCursorImageView {
    if (!_focusCursorImageView) {
        UIImageView *focusCursorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_record_focus"]];
        focusCursorImageView.contentMode = UIViewContentModeScaleAspectFit;
        focusCursorImageView.frame = CGRectMake(0, 0, 80, 80);
        focusCursorImageView.alpha = 0;
        [self addSubview:focusCursorImageView];
        _focusCursorImageView = focusCursorImageView;
    }
    
    return _focusCursorImageView;
}

- (UIImageView *)photoImageView {
    if (!_photoImageView) {
        UIImageView *photoImageView = [[UIImageView alloc] init];
        photoImageView.backgroundColor = [UIColor blackColor];
        photoImageView.contentMode = UIViewContentModeScaleAspectFit;
        photoImageView.frame = self.bounds;
        photoImageView.hidden = YES;
        [self insertSubview:photoImageView belowSubview:self.backButton];
        _photoImageView = photoImageView;
    }
    return _photoImageView;
}

#pragma mark - public method
- (void)presentView {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.delegate = self;
    animation.keyPath = @"position.y";
    animation.toValue = @(self.bounds.size.height / 2);
    animation.duration = 0.3;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [self.layer addAnimation:animation forKey:@"presentAnimation"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].statusBarHidden = YES;
    });
}

/**
 退出界面
 */
- (void)closeView {
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.delegate = self;
        animation.keyPath = @"position.y";
        animation.toValue = @(self.bounds.size.height * 3 / 2);
        animation.duration = 0.3;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeBoth;
        //    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [self.layer addAnimation:animation forKey:nil];
    });

}

- (void)setMaxRecordTime:(CGFloat)maxRecordTime {
    _maxRecordTime = maxRecordTime;
    
    self.recordButton.animationDuration = maxRecordTime;
}

- (void)setDisableVideoRecord:(BOOL)disableVideoRecord
{
    _disableVideoRecord = disableVideoRecord;
    
    self.recordButton.disableLongPressGest = disableVideoRecord;
}

#pragma mark - private method
/**
 切换前后摄像头
 */
- (void)turnCamera {
    [self.videoRecord switchCameraAction];
}

- (void)takePhoto {
    [self.remindLabel removeFromSuperview];
    
    __weak typeof(self) weakSelf = self;
    [self.videoRecord takePicture:^(UIImage *image) {
        weakSelf.photoImageView.image = image;
        weakSelf.photoImageView.hidden = NO;
        [weakSelf operationVideoUI];
    }];
}

- (void)operationFinish:(UIButton *)button {
    [self.videoPlayer removeFromSuperview];
    [self.photoImageView removeFromSuperview];
    
    //设置提醒文字
    if (!self.disableVideoRecord && !self.disableTakePhoto) {
        [self showRemindText];
    }
    
    if (button.tag == 0) {
        [self recordVideoUI];
    }
    else {
        if (self.finishBlock) {
            self.finishBlock(self.photoImageView.image, self.videoRecord.videoUrl);
            self.finishBlock = nil;
        }
        
        [self closeView];
    }
}

- (void)recordVideoUI {
    self.closeButton.hidden = NO;
    self.recordButton.hidden = NO;
    self.backButton.hidden = YES;
    self.confirmButton.hidden = YES;
}

- (void)operationVideoUI {
    self.closeButton.hidden = YES;
    self.recordButton.hidden = YES;
    self.backButton.hidden = NO;
    self.confirmButton.hidden = NO;
}

- (void)showRemindText {
    UILabel *remindLabel = [[UILabel alloc] init];
    remindLabel.text = @"轻触拍照，按住摄像";
    [remindLabel sizeToFit];
    remindLabel.center = CGPointMake(self.recordButton.center.x, self.recordButton.center.y - 65);
    remindLabel.font = [UIFont systemFontOfSize:13];
    remindLabel.textAlignment = NSTextAlignmentCenter;
    remindLabel.textColor = [UIColor whiteColor];
    remindLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    remindLabel.layer.shadowRadius = 4.0f;
    remindLabel.layer.shadowOpacity = 0.8;
    remindLabel.layer.shadowOffset = CGSizeZero;
    self.remindLabel = remindLabel;
    [self addSubview:remindLabel];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [remindLabel removeFromSuperview];
    });
}

- (void)checkVideoAuthority {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeView];
                    });
                }
                else {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self closeView];
            });
        }
    }];
}

- (void)willResignActive {
    [self closeView];
}

- (void)dealloc {
//    NSLog(@"%@---dealloc", self);
}

#pragma mark - add Gest
/**
 添加手势
 */
- (void)addGest {
    //添加录制和调整焦距手势(单手滑动调整)
    UIPanGestureRecognizer *panGest = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestAdjustCameraFocus:)];
    [self addGestureRecognizer:panGest];
    
    //添加调整焦距手势(捏合调整)
    UIPinchGestureRecognizer *pinGest = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinGestAdjustFoucs:)];
    [self addGestureRecognizer:pinGest];
    
    //设置光标位置和拍照
    UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestHandle:)];
    [self addGestureRecognizer:tapGest];
}

- (void)panGestAdjustCameraFocus:(UIPanGestureRecognizer *)tapGest {
    CGPoint point = [tapGest locationInView:self];
    
    if (tapGest.state == UIGestureRecognizerStateBegan) {
        if (!CGRectContainsPoint(self.recordButton.frame, point)) {
            return;
        }
        
        self.dragStart = YES;
        if (self.videoRecord.recordState == MLHVideoRecordStateInit && !self.disableVideoRecord) {
            [self.videoRecord startRecord];
            [self.recordButton startAnimation];
        }
    }
    else if (tapGest.state == UIGestureRecognizerStateChanged) {
        if (!self.dragStart) {
            return;
        }
        
        CGFloat zoomFactor = (CGRectGetMidY(self.recordButton.frame)-point.y)/CGRectGetMidY(self.recordButton.frame) * 10;
        
        [self.videoRecord setVideoZoomFactor:MIN(MAX(zoomFactor, 1), 8.0)];
    }
    else if (tapGest.state == UIGestureRecognizerStateCancelled || tapGest.state == UIGestureRecognizerStateEnded) {
        if (!self.dragStart) {
            return;
        }
        
        self.dragStart = NO;
        [self.recordButton stopAnimation];
    }
}

- (void)pinGestAdjustFoucs:(UIPinchGestureRecognizer *)pinGest {
    CGFloat zoomFactor = MAX(MIN(self.videoRecord.zoomFactor + pinGest.velocity * 0.1, 8.0), 1.0);
    [self.videoRecord setVideoZoomFactor:zoomFactor];
}

- (void)tapGestHandle:(UITapGestureRecognizer *)tapGest {
    if (self.videoPlayer || _photoImageView) {
        return;
    }
    
    CGPoint point = [tapGest locationInView:self];
    if (CGRectContainsPoint(self.recordButton.frame, point) && !self.disableTakePhoto) {
        [self takePhoto];
        return;
    }
    
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.alpha = 1;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha = 0;
    }];
    
    [self.videoRecord focusWithMode:AVCaptureFocusModeAutoFocus atPoint:point];
}

#pragma mark - Animation Delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (anim == [self.layer animationForKey:@"presentAnimation"]) { //弹出动画完成
        self.frame = [UIScreen mainScreen].bounds;
        [self.layer removeAllAnimations];
        
        //设置提醒文字
        if (!self.disableVideoRecord && !self.disableTakePhoto) {
            [self showRemindText];
        }
    }
    else { //退出动画完成
        [self.layer removeAllAnimations];
        [self removeFromSuperview];
        
        if (self.finishBlock) {
            self.finishBlock(nil, nil);
            self.finishBlock = nil;
        }
    }
}

#pragma mark - MLHRecordButtonDelegate
- (void)recordButtonStart:(MLHRecordButton *)recordButton withTouchType:(MLHTouchType)touchType {
    if (touchType == MLHTouchTypeLongPress) {
        if (!self.disableVideoRecord) {
            if (self.videoRecord.recordState == MLHVideoRecordStateInit) {
                [self.videoRecord startRecord];
            }
        }
    }
}

- (void)recordButtonStop:(MLHRecordButton *)recordButton withTouchType:(MLHTouchType)touchType {
    if (touchType == MLHTouchTypeLongPress) {
        if (!self.disableVideoRecord) {
            //防止录制完成后迅速再次点击录制bug
            self.recordButton.hidden = YES;
            
            [self.videoRecord stopRecord];
        }
    }
}

#pragma mark - MLHVideoRecordDelegate
- (void)updateRecordState:(MLHVideoRecordState)recordState {
    switch (recordState) {
        case MLHVideoRecordStateInit:
        case MLHVideoRecordStatePrepareRecord:
        case MLHVideoRecordStatePause:
            break;
            
        case MLHVideoRecordStateStart:
            self.closeButton.hidden = YES;
            [self.remindLabel removeFromSuperview];
            
            break;
            
        case MLHVideoRecordStateFinish:
        {
            MLHShortVideoPlay *videoPlayer = [[MLHShortVideoPlay alloc] initWithVideoUrl:self.videoRecord.videoUrl];
            videoPlayer.frame = [UIScreen mainScreen].bounds;
            self.videoPlayer = videoPlayer;
            [self insertSubview:videoPlayer belowSubview:self.backButton];
            [videoPlayer play];
            
            [self operationVideoUI];
        }
            break;
            
    }
}

- (void)interruptedRecord:(MLHVideoRecord *)videoRecord {
    [self closeView];
    
//    [MBProgressHUD showError:@"您的麦克风或摄像头被占用，无法录制" toView:[UIApplication sharedApplication].keyWindow];
    NSLog(@"视频录制中断");
}

@end
