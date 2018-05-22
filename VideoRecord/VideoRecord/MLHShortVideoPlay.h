//
//  MLHShortVideoPlay.h
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/3/5.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MLHShortVideoPlay : UIView

@property (assign, nonatomic) BOOL repeatPlay; /* default YES*/

- (instancetype)initWithVideoUrl:(NSURL *)videoUrl;

- (void)play;
- (void)pause;

@end
