//
//  MLHShortVideoPlay.m
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/5.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import "MLHShortVideoPlay.h"
#import <AVKit/AVKit.h>

@interface MLHShortVideoPlay()

@property (strong, nonatomic) NSURL *videoUrl;

@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@end

@implementation MLHShortVideoPlay

- (instancetype)initWithVideoUrl:(NSURL *)videoUrl {
    self = [super init];
    if (self) {
        self.videoUrl = videoUrl;
        self.repeatPlay = YES;
        self.backgroundColor = [UIColor blackColor];
        
        [self setUpMovieLayer];
        
        [self addNotifiction];
    }
    
    return self;
}

#pragma mark - private method
- (void)setUpMovieLayer {
    AVPlayer *player = [[AVPlayer alloc] initWithURL:self.videoUrl];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = [UIScreen mainScreen].bounds;
    [self.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
}

- (void)addNotifiction {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

/**
 循环播放

 @param notification 通知对象
 */
- (void)playFinish:(NSNotification *)notification {
    if (self.repeatPlay) {
        [self.playerLayer.player seekToTime:CMTimeMake(0, 1)];
        [self.playerLayer.player play];
    }
}

- (void)dealloc {
//    NSLog(@"%@---dealloc", self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public method
- (void)play {
    [self.playerLayer.player play];
}

- (void)pause {
    [self.playerLayer.player pause];
}

@end
