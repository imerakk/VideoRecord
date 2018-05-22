//
//  MLHRecordButton.m
//  CoreAnimationPractice
//
//  Created by liuchunxi on 2018/2/28.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import "MLHRecordButton.h"

#define HEXCOLOR(c)  [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:(c&0xFF)/255.0 alpha:1.0]

@interface MLHRecordButton() <CAAnimationDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) CAShapeLayer *animationCircleLayer;

@property (strong, nonatomic) CAShapeLayer *largeCircleLayer;

@property (strong, nonatomic) CALayer *smallCircleLayer;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGest;
@end

@implementation MLHRecordButton

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.smallCircleRadius = 30.0f;
        self.animationDuration = 10.0;
        [self initSubView];
    }
    
    return self;
}

- (void)initSubView {
    //外圈圆环
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    UIBezierPath *largeCirclePath = [UIBezierPath bezierPath];
    [largeCirclePath addArcWithCenter:CGPointZero radius:self.smallCircleRadius + 20 startAngle:-M_PI / 2 endAngle:2 * M_PI - M_PI / 2  clockwise:YES];

    CAShapeLayer *largeCircleLayer = [CAShapeLayer layer];
    largeCircleLayer.backgroundColor = [UIColor blueColor].CGColor;
    largeCircleLayer.position = center;
    largeCircleLayer.shadowRadius = 2;
    largeCircleLayer.shadowColor = [UIColor grayColor].CGColor;
    largeCircleLayer.shadowOpacity = 0.6;
    largeCircleLayer.shadowOffset = CGSizeZero;
    largeCircleLayer.path = largeCirclePath.CGPath;
    largeCircleLayer.lineWidth = 5;
    largeCircleLayer.strokeColor = [UIColor whiteColor].CGColor;
    largeCircleLayer.fillColor = [UIColor clearColor].CGColor;
    largeCircleLayer.hidden = YES;
    self.largeCircleLayer = largeCircleLayer;
    [self.layer addSublayer:largeCircleLayer];

    //外圈动画圆环
    CAShapeLayer *animationCircleLayer = [CAShapeLayer layer];
    animationCircleLayer.backgroundColor = [UIColor blueColor].CGColor;
    animationCircleLayer.position = CGPointZero;
    animationCircleLayer.path = largeCirclePath.CGPath;
    animationCircleLayer.lineWidth = 5;
    animationCircleLayer.strokeColor = HEXCOLOR(0x4A90E2).CGColor;
    animationCircleLayer.fillColor = [UIColor clearColor].CGColor;
    animationCircleLayer.strokeEnd = 0;
    [largeCircleLayer addSublayer:animationCircleLayer];
    self.animationCircleLayer = animationCircleLayer;
    
    //内圈小圆
    CALayer *smallCircleLayer = [CALayer layer];
    smallCircleLayer.backgroundColor = [UIColor whiteColor].CGColor;
    smallCircleLayer.bounds = CGRectMake(0, 0, self.smallCircleRadius * 2,self.smallCircleRadius * 2);
    smallCircleLayer.position = center;
    smallCircleLayer.cornerRadius = self.smallCircleRadius;
    smallCircleLayer.shadowColor = [UIColor grayColor].CGColor;
    smallCircleLayer.shadowOffset = CGSizeZero;
    smallCircleLayer.shadowRadius = 2;
    smallCircleLayer.shadowOpacity = 0.6;
    [self.layer addSublayer:smallCircleLayer];
    self.smallCircleLayer = smallCircleLayer;
    
    self.longPressGest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    self.longPressGest.delegate = self;

    [self addGestureRecognizer:self.longPressGest];
}

- (void)setDisableLongPressGest:(BOOL)disableLongPressGest
{
    _disableLongPressGest = disableLongPressGest;
    
    [self.longPressGest removeTarget:self action:@selector(longPress:)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    self.largeCircleLayer.position = center;
    self.smallCircleLayer.position = center;
}

#pragma mark - Gesture
- (void)longPress:(UILongPressGestureRecognizer *)gest {
//    NSLog(@"LongPressGesture----%ld", gest.state);
    
    switch (gest.state) {
        case UIGestureRecognizerStateBegan:
            [self startAnimation];
            break;

        case UIGestureRecognizerStateChanged:
            break;

        case UIGestureRecognizerStateEnded:
            [self stopAnimation];
            break;

        case UIGestureRecognizerStateCancelled:
            break;

        case UIGestureRecognizerStateFailed:
            break;

        default:
            break;
    }
}

#pragma mark - public method
- (void)startAnimation {
    //外环动画
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.delegate = self;
    animation.keyPath = @"strokeEnd";
    animation.toValue = @1;
    animation.duration = self.animationDuration;
    [self.animationCircleLayer addAnimation:animation forKey:@"recordAnimation"];
    
    //内圈动画
    CABasicAnimation *smallCircleAnimation = [CABasicAnimation animation];
    smallCircleAnimation.keyPath = @"transform.scale";
    smallCircleAnimation.toValue = @0.8;
    smallCircleAnimation.duration = 0.2;
    smallCircleAnimation.removedOnCompletion = NO;
    smallCircleAnimation.fillMode = kCAFillModeForwards;
    [self.smallCircleLayer addAnimation:smallCircleAnimation forKey:@"smallCircleAnimation"];
    
    self.smallCircleLayer.backgroundColor = HEXCOLOR(0xCBCBCB).CGColor;
    
    //禁止隐士动画防止子图层动画无效
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.largeCircleLayer.hidden = NO;
    [CATransaction commit];
}

- (void)stopAnimation {
    [self resetView];
}

#pragma mark - private method
- (void)resetView {
    [self.animationCircleLayer removeAnimationForKey:@"recordAnimation"];
    [self.smallCircleLayer removeAnimationForKey:@"smallCircleAnimation"];
    
    self.smallCircleLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.largeCircleLayer.hidden = YES;
}

- (void)dealloc {
    NSLog(@"%@---delloc", self);
}

#pragma mark - Animation Delegate
- (void)animationDidStart:(CAAnimation *)anim {
    if ([self.myDelegate respondsToSelector:@selector(recordButtonStart:withTouchType:)]) {
        [self.myDelegate recordButtonStart:self withTouchType:MLHTouchTypeLongPress];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self resetView];
    
    if ([self.myDelegate respondsToSelector:@selector(recordButtonStop:withTouchType:)]) {
        [self.myDelegate recordButtonStop:self withTouchType:MLHTouchTypeLongPress];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])) {
        return YES;
    }
    return NO;
}

@end
