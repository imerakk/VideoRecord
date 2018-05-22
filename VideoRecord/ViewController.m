//
//  ViewController.m
//  VideoRecord
//
//  Created by liuchunxi on 2018/5/22.
//  Copyright © 2018年 liuchunxi. All rights reserved.
//

#import "ViewController.h"
#import "MLHShortVideoRecordView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)videoRecordAction:(id)sender
{
    MLHShortVideoRecordView *recordView = [[MLHShortVideoRecordView alloc] init];
    recordView.finishBlock = ^(UIImage *image, NSURL *videoUrl) {
        NSLog(@"image:%@---videoUrl:%@", image, videoUrl);
    };
    [recordView presentView];
}


@end
