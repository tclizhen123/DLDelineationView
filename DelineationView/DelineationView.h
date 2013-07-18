//
//  DelineationView.h
//  DLCoverDemo
//
//  Created by david lee on 13-7-17.
//  Copyright (c) 2013年 david lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DelineationView;

typedef void (^DelineationCompletionBlock) (UIImage *aImage,DelineationView *aDelineationView);

@interface DelineationView : UIView

@property (retain) UIView *originView;
@property (assign) float lineWidth;
@property (retain) UIColor *lineColor;
@property (nonatomic, copy) DelineationCompletionBlock completionBlock;

+(DelineationView *) delineationnViewWithOriginView:(UIView *)aOriginView completionBlock:(DelineationCompletionBlock )aCompletionBlock;
-(id ) initWithOriginView:(UIView *)aOriginView;

@end
