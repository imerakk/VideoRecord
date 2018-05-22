//
//  MLHVideoRecord.m
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/2.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import "MLHVideoRecord.h"
#import <CoreMotion/CoreMotion.h>

static NSString *const kVideoFolderOringin = @"VideoRecordFolderOringin";
static NSString *const kVideoFolderCompress = @"VideoFolder";

@interface MLHVideoRecord() <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *voiceInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutPut;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureConnection *captureConnection;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, nonatomic) AVCaptureVideoOrientation orientation;

@property (weak, nonatomic) UIView *superView;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@property (strong, nonatomic, readwrite) NSURL *videoUrl;
@property (assign, nonatomic, readwrite) MLHVideoRecordState recordState;
@property (assign, nonatomic, readwrite) CGFloat zoomFactor;

@end

@implementation MLHVideoRecord

- (instancetype)initWithSuperView:(UIView *)superView delegate:(id<MLHVideoRecordDelegate>)delegate {
    self = [super init];
    if (self) {
        self.superView = superView;
        self.myDelegate = delegate;
        self.zoomFactor = 1.0;
        
        //初始化视频录制会话
        [self initVideoSession];
        
        //添加视频预览层
        [self setUpPreviewLayer];
        
        //开始采集画面
        [self.session startRunning];
        
        //监控方向设备
        [self observeDeviceMotion];
    }
    
    return self;
}

- (void)initVideoSession {
    //创建视频会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.session = session;
    if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    //设置相片输出流
    AVCaptureStillImageOutput *imageOutPut = [[AVCaptureStillImageOutput alloc] init];
    [imageOutPut setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey]];
    if ([session canAddOutput:imageOutPut]) {
        [session addOutput:imageOutPut];
    }
    self.imageOutPut = imageOutPut;
    
    //视频输入
    AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&error];
    if ([session canAddInput:videoInput]) {
        [session addInput:videoInput];
    }
    self.videoInput = videoInput;
    
    //音频输入
    AVCaptureDevice *voiceDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error1;
    AVCaptureDeviceInput *voiceInput = [[AVCaptureDeviceInput alloc] initWithDevice:voiceDevice error:&error1];
    self.voiceInput = voiceInput;
    if ([session canAddInput:voiceInput]) {
        [session addInput:voiceInput];
    }
    
    //视频文件输出
    AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([session canAddOutput:movieOutput]) {
        [session addOutput:movieOutput];
    }
    self.movieOutput = movieOutput;
    self.captureConnection = [movieOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([self.captureConnection isVideoStabilizationSupported]) { //设置防抖模式
        self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    
    self.recordState = MLHVideoRecordStateInit;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)setUpPreviewLayer {
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.frame = [UIScreen mainScreen].bounds;
    self.previewLayer = previewLayer;
    [self.superView.layer insertSublayer:previewLayer atIndex:0];
}

#pragma mark - 懒加载
- (dispatch_queue_t)serialQueue {
    if (!_serialQueue) {
        _serialQueue = dispatch_queue_create("videoRecordQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _serialQueue;
}

#pragma mark - public method
- (void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point {
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    
    AVCaptureDevice * captureDevice = [self.videoInput device];
    NSError * error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if (![captureDevice lockForConfiguration:&error]) {
        return;
    }
    //聚焦模式
    if ([captureDevice isFocusModeSupported:focusMode]) {
        [captureDevice setFocusMode:focusMode];
    }
    //聚焦点
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:cameraPoint];
    }
    
    [captureDevice unlockForConfiguration];
}

- (void)setVideoZoomFactor:(CGFloat)zoomFactor {
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError *error = nil;
    [captureDevice lockForConfiguration:&error];
    captureDevice.videoZoomFactor = zoomFactor;
    [captureDevice unlockForConfiguration];
    
    if (!error) {
        self.zoomFactor = zoomFactor;
    }
}

- (void)switchCameraAction {
    if ([self.movieOutput isRecording]) {
        return;
    }
    
    [self.session stopRunning];
    
    //获取当前需要展示的摄像头
    AVCaptureDevicePosition position = self.videoInput.device.position;
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    }
    else {
        position = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //切换新的摄像头
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
}

- (void)startRecord {
    self.recordState = MLHVideoRecordStatePrepareRecord;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (![self.movieOutput isRecording]) {
            self.captureConnection.videoOrientation = self.orientation;
            
            NSString *filePath = [self createVideoFilePath:kVideoFolderOringin];
            self.videoUrl = [NSURL fileURLWithPath:filePath];
            [self.movieOutput startRecordingToOutputFileURL:self.videoUrl recordingDelegate:self];
        }
    });
}

- (void)stopRecord {
    dispatch_async(self.serialQueue, ^{
        if ([self.movieOutput isRecording]) {
            [self.movieOutput stopRecording];
        }
    });
}

- (void)compressVideoWithUrl:(NSURL *)originVideoUrl compressQuality:(MLHVideoRecordCompressQuality)compressQuality competionBlock:(void (^)(NSURL *))competionBlock {
    AVAsset *asset = [AVAsset assetWithURL:originVideoUrl];
    
    NSString *exportPreset = nil;
    switch (compressQuality) {
        case MLHVideoRecordCompressQualityLow:
            exportPreset = AVAssetExportPresetLowQuality;
            break;
            
        case MLHVideoRecordCompressQualityMedium:
            exportPreset = AVAssetExportPresetMediumQuality;
            break;
            
        case MLHVideoRecordCompressQualityHigh:
            exportPreset = AVAssetExportPresetHighestQuality;
            break;

    }
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:exportPreset];
    session.shouldOptimizeForNetworkUse = YES;
    session.outputFileType = AVFileTypeMPEG4;
    NSString *filePath = [self createVideoFilePath:kVideoFolderCompress];
    session.outputURL = [NSURL fileURLWithPath:filePath];
    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (session.status == AVAssetExportSessionStatusCompleted) {
                if (competionBlock) {
                    competionBlock(session.outputURL);
                }
                
                [self clearOriginVideos];
            }
            else {
                if (competionBlock) {
                    competionBlock(nil);
                }
            }
        });
    }];
}

- (BOOL)clearOriginVideos {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self createFolder:kVideoFolderOringin] error:&error];
    
    if (error) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)reset {
    self.recordState = MLHVideoRecordStateInit;
    [self setVideoZoomFactor:1.0];
}

- (void)takePicture:(void (^)(UIImage *))picture {
    AVCaptureConnection *pictureConnect = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    pictureConnect.videoOrientation = self.orientation;
    if (!pictureConnect) {
        return;
    }
    
    [self.imageOutPut captureStillImageAsynchronouslyFromConnection:pictureConnect completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (imageDataSampleBuffer == NULL) {
            return ;
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (picture) {
            picture(image);
            
            [self reset];
        }
    }];
}

#pragma mark - private method
- (NSString *)createFolder:(NSString *)folderName {
    //创建目录
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *direc = [cacheDir stringByAppendingPathComponent:folderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:direc]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:direc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return direc;
}

- (NSString *)createVideoFilePath:(NSString *)folderName {
    //创建文件路径
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self createFolder:folderName] stringByAppendingPathComponent:videoName];
    return path;
}

- (void)setRecordState:(MLHVideoRecordState)recordState {
    if (_recordState != recordState) {
        _recordState = recordState;
        if ([self.myDelegate respondsToSelector:@selector(updateRecordState:)]) {
            [self.myDelegate updateRecordState:recordState];
        }
    }
}

- (void)dealloc {
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    NSLog(@"%@dealloc", self);
}

#pragma mark - observer
- (void)audioSessionWasInterrupted:(NSNotification *)notification {
    if ([notification.userInfo[AVCaptureSessionInterruptionReasonKey] longValue] == 2) {
        [self.session removeInput:self.voiceInput];
    }
    else {
        if ([self.myDelegate respondsToSelector:@selector(interruptedRecord:)]) {
            [self.myDelegate interruptedRecord:self];
        }
    }
}

#pragma mark - 监控设备方向
- (void)observeDeviceMotion {
    self.motionManager = [[CMMotionManager alloc] init];
    // 提供设备运动数据到指定的时间间隔
    self.motionManager.deviceMotionUpdateInterval = .5;
    
    __weak typeof(self) weakSelf = self;
    if (self.motionManager.deviceMotionAvailable) {  // 确定是否使用任何可用的态度参考帧来决定设备的运动是否可用
        // 启动设备的运动更新，通过给定的队列向给定的处理程序提供数据。
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            [weakSelf performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    } else {
        self.motionManager = nil;
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x)) {
        if (y >= 0){
            // UIDeviceOrientationPortraitUpsideDown;
            self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else {
            // UIDeviceOrientationPortrait;
            self.orientation = AVCaptureVideoOrientationPortrait;
        }
    } else {
        if (x >= 0) {
            //视频拍照转向，左右和屏幕转向相反
            // UIDeviceOrientationLandscapeRight;
            self.orientation = AVCaptureVideoOrientationLandscapeLeft;
        } else {
            // UIDeviceOrientationLandscapeLeft;
            self.orientation = AVCaptureVideoOrientationLandscapeRight;
        }
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    self.recordState = MLHVideoRecordStateStart;
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    self.recordState = MLHVideoRecordStateFinish;
    [self reset];
}

#pragma mark - 获取摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

@end
