//
//  DelineationView.m
//  DLCoverDemo
//
//  Created by david lee on 13-7-17.
//  Copyright (c) 2013年 david lee. All rights reserved.
//

#import "DelineationView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

@interface DelineationView () {
    BOOL _isMoving;
    dispatch_queue_t _bgSerialQueue;
    NSMutableArray *_points;
}

@property (retain)  UIImage *originViewImage;
@property (retain)  UIImage *gaussianBlurImage;
@property (retain)  UIImage *resultImage;

@end

@implementation DelineationView

#pragma mark generator

+(DelineationView *) delineationnViewWithOriginView:(UIView *)aOriginView completionBlock:(DelineationCompletionBlock )aCompletionBlock{
    DelineationView *view = [[[DelineationView alloc] initWithOriginView:aOriginView] autorelease];
    view.completionBlock = aCompletionBlock;
    [aOriginView addSubview:view];
    return view;
}

#pragma mark life cycle

-(id ) initWithOriginView:(UIView *)aOriginView{
    
    if (self = [super initWithFrame:aOriginView.bounds]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.originView = aOriginView;
        
        self.lineWidth = 8.;
        self.lineColor = [UIColor whiteColor];
        
        _points = [[NSMutableArray alloc] initWithCapacity:100];
        
        _bgSerialQueue = dispatch_queue_create("bgSerialQueue", NULL);
        dispatch_set_target_queue(_bgSerialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        [self coverOriginViewToImage:_originView];
        [self getGaussianBlurImage:_originViewImage];
        
    }
    return self;
}

- (void)dealloc
{
    [_originView release];
    [_originViewImage release];
    [_gaussianBlurImage release];
    [_resultImage release];
    
    dispatch_release(_bgSerialQueue);
    
    if (_completionBlock) {
        [_completionBlock release];
        _completionBlock = nil;
    }
    
    [super dealloc];
}

#pragma mark draw functions

- (void)drawRect:(CGRect)rect
{
    
    if (_isMoving && _points.count > 0) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, _lineWidth);
        
        for (int i = 1; i < _points.count; i++) {
            CGPoint beginPoint = [(NSValue *)_points[i - 1] CGPointValue];
            CGPoint endPoint = [(NSValue *)_points[i] CGPointValue];
            
            CGPoint linePoints[2] = {beginPoint,endPoint};
            CGContextAddLines(context,linePoints, 2);
        }
        
        CGContextStrokePath(context);
    }

}

-(void ) generateResultImageWithOriginImage:(UIImage *)aOriginImage gaussianBlurImage:(UIImage *)aGaussianBlurImage points:(NSMutableArray *)aPoints{
    
     dispatch_async(_bgSerialQueue, ^{
         
         UIGraphicsBeginImageContext(self.bounds.size);
         CGContextRef context = UIGraphicsGetCurrentContext();
         
         [aGaussianBlurImage drawInRect:(CGRect){-_lineWidth,-_lineWidth,CGRectGetWidth(self.bounds) + _lineWidth * 2,CGRectGetHeight(self.bounds) + _lineWidth * 2}];
//         [aGaussianBlurImage drawInRect:(CGRect){CGPointZero,self.bounds.size}];
         CGMutablePathRef delineationPath = CGPathCreateMutable();
         CGPathMoveToPoint(delineationPath, NULL, [_points[0] CGPointValue].x, [_points[0] CGPointValue].y);
         for (int i = 1; i < _points.count; i ++) {
             CGPoint endPoint = [(NSValue *)_points[i] CGPointValue];
             CGPathAddLineToPoint(delineationPath, NULL, endPoint.x, endPoint.y);
         }
         CGContextAddPath(context, delineationPath);
         CGContextClip(context);
         [aOriginImage drawInRect:(CGRect){CGPointZero,self.bounds.size}];
         
         CGContextSaveGState(context);
         
         CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);
         CGContextSetLineCap(context, kCGLineCapRound);
         CGContextSetLineWidth(context, _lineWidth * 2);
         
//         CGContextSetShadowWithColor(context, (CGSize){1,1}, 10, [UIColor blackColor].CGColor);
         
         CGContextAddPath(context, delineationPath);
         CGContextStrokePath(context);
         
         CGContextRestoreGState(context);
         
         self.resultImage = UIGraphicsGetImageFromCurrentImageContext();
         
         UIGraphicsEndImageContext();
         
         __block DelineationView *block_self = self;
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             [_points removeAllObjects];
             [self setNeedsDisplay];
             
             if (_completionBlock) _completionBlock(_resultImage,block_self);
             
             [block_self removeFromSuperview];
             block_self = nil;
         });
         
     });
}

-(void ) coverOriginViewToImage:(UIView *)aOriginView{
    
    UIGraphicsBeginImageContext(self.bounds.size);
    [aOriginView.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(), YES);
    CGContextSetShouldSmoothFonts(UIGraphicsGetCurrentContext(),YES);
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.originViewImage = viewImage;
}

-(void ) getGaussianBlurImage:(UIImage *)aViewImage{
    
    dispatch_async(_bgSerialQueue, ^{
        
        CIImage *imageToBlur = [CIImage imageWithCGImage:aViewImage.CGImage];
        CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [gaussianBlurFilter setValue:imageToBlur forKey:@"inputImage"];
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat:3] forKey:@"inputRadius"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
        self.gaussianBlurImage = [[[UIImage alloc] initWithCIImage:resultImage] autorelease];
        
    });
}


#pragma mark helpers

-(CGMutablePathRef ) delineationPath{
    
    CGMutablePathRef delineationPath = CGPathCreateMutable();
    CGPathMoveToPoint(delineationPath, NULL, [_points[0] CGPointValue].x, [_points[0] CGPointValue].y);
    
    for (int i = 1; i < _points.count; i ++) {
        CGPoint endPoint = [(NSValue *)_points[i] CGPointValue];
        CGPathMoveToPoint(delineationPath, NULL, endPoint.x, endPoint.y);
    }
    
    return delineationPath;
}

#pragma mark touch delegates

-(void ) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    _isMoving = YES;
    
    CGPoint beginPoint = [((UITouch *)[touches anyObject]) locationInView:self];
    [_points addObject:[NSValue valueWithCGPoint:beginPoint]];
    
    [self setNeedsDisplay];
}

-(void ) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGPoint currentPoint = [((UITouch *)[touches anyObject]) locationInView:self];    
    [_points addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    [self setNeedsDisplay];
    
}

-(void ) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    _isMoving = NO;
    
    [self generateResultImageWithOriginImage:_originViewImage gaussianBlurImage:_gaussianBlurImage points:_points];
}


@end
