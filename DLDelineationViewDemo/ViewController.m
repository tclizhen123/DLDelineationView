//
//  ViewController.m
//  DLDelineationViewDemo
//
//  Created by david lee on 13-7-18.
//  Copyright (c) 2013年 david lee. All rights reserved.
//

#import "ViewController.h"
#import "DelineationView.h"

@interface ViewController () {
    UIImageView *image;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    image = [[UIImageView alloc] initWithFrame:self.view.bounds];
    image.image = [UIImage imageNamed:@"test.jpg"];
    image.userInteractionEnabled = YES;
    [self.view addSubview:image];
    [image release];
    
    [DelineationView delineationnViewWithOriginView:image completionBlock:^(UIImage *aImage,DelineationView *aDelineationView) {
        image.image = aImage;
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
