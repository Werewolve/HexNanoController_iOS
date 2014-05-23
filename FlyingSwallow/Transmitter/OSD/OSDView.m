//
//  OSDView.m
//  OSD
//
//  Created by koupoo on 13-3-13.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import "OSDView.h"

#define kAltitudeTraceLen                0.8
#define kAltitudeTraceX                  0.85
#define kAltitudeTraceY                  0.1
#define kAltitudeTraceRange              35      //以分米为单位
#define kAltitudeTraceInterval           5
#define kAltitudeTraceTicksPerInterval   5
#define kAltitudeTraceIntervalMarkLen    10
#define kAltitudeTraceTickMarkLen        5

#define kOrientationTraceLen                0.96
#define kOrientationTraceX                  0.02
#define kOrientationTraceY                  0.98
#define kOrientationTraceRange              120      //以度为单位
#define kOrientationTraceInterval           15
#define kOrientationTraceTicksPerInterval   15
#define kOrientationTraceNeesDrawTicks      FALSE
#define kOrientationTraceIntervalMarkLen    6
#define kOrientationTraceTickMarkLen        5

#define kAttitudeTraceLen                0.6
#define kAttitudeTraceX                  0.5
#define kAttitudeTraceRange              50      //以度为单位
#define kAttitudeTraceInterval           5
#define kAttitudeTraceTicksPerInterval   5
#define kAttitudeTraceNeesDrawTicks      FALSE
#define kAttitudeTraceIntervalMarkLen    120
#define kAttitudeTraceTickMarkLen        10

#define kDroneWidth 0.2
#define kWorldRefreshFreq  5

@interface OSDView()

@property (nonatomic, assign) CGContextRef context;
@property (nonatomic, strong) UIImage *worldImage;
@property (nonatomic, strong) UIImage *droneImage;

@end

@implementation OSDView

- (void)setupImages {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"world.jpg" ofType:nil];
    self.worldImage = [UIImage imageWithContentsOfFile:imagePath];
    imagePath = [[NSBundle mainBundle] pathForResource:@"drone.png" ofType:nil];
    self.droneImage = [UIImage imageWithContentsOfFile:imagePath];
}

- (id)initWithOsdData:(OSDData *)data {
    self = [super init];
    if (self) {
        self.osdData = data;
        [self setupImages];
    }
    return self;
}

- (void)setOsdData:(OSDData *)osdData {
    _osdData = osdData;
    [self setNeedsDisplay];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupImages];
}

- (void)update {
    [self setNeedsDisplay];
}

- (void)drawWorldWithRoll:(float)roll pitch:(float)pitch {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"world.jpg" ofType:nil];
    UIImage *uiImage = [UIImage imageWithContentsOfFile:imagePath];
    CGImageRef image = uiImage.CGImage;
    
    CGRect imageRect = CGRectZero;
	imageRect.size = CGSizeMake(uiImage.size.width * 3.0f, uiImage.size.height * 3.0f);
    imageRect.origin = CGPointMake((self.frame.size.width - imageRect.size.width) * 0.5f, (self.frame.size.height- imageRect.size.height) * 0.5f);
    
    CGContextSaveGState(self.context);
    CGContextScaleCTM(self.context, 1.0, -1.0);//2
    CGContextTranslateCTM(self.context, 0, -self.frame.size.height);//4
    
    float lenPerPitchDegree = kAttitudeTraceLen * self.frame.size.height / 50.0;
    if (pitch > 90.0f) {
        imageRect.origin.y -= lenPerPitchDegree * (90.0f - (pitch - 90.0f));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * (90.0f - (pitch - 90.0f)));
        
        float refinedRoll;
        
        if (roll > 0) {
            refinedRoll = 180.0f - roll;
        } else {
            refinedRoll = -180.0f - roll;
        }
        
        CGContextRotateCTM(self.context, refinedRoll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * (90.0f - (pitch - 90.0f))));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f) ;
        CGContextRotateCTM(self.context, M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
    } else if (pitch < -90.0f) {
        imageRect.origin.y -= lenPerPitchDegree * (-90.0f - (pitch - (-90.0f)));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * (-90.0f - (pitch - (-90.0f)))) ;
        float refinedRoll;
        if (roll > 0.0f) {
            refinedRoll = 180.0f - roll;
        } else {
            refinedRoll = -180.0f - roll;
        }
        CGContextRotateCTM(self.context, refinedRoll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * (-90.0f - (pitch - (-90.0f)))));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f) ;
        CGContextRotateCTM(self.context, M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
    } else {
        imageRect.origin.y -= lenPerPitchDegree * pitch;
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * pitch) ;
        CGContextRotateCTM(self.context, roll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * pitch));
    }
    CGContextDrawImage(self.context, imageRect, image);
    CGContextRestoreGState(self.context);
}

- (void)drawWorldWithRoll2:(float)roll pitch:(float)pitch {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"world.jpg" ofType:nil];
    UIImage *uiImage = [UIImage imageWithContentsOfFile:imagePath];
    CGImageRef image = uiImage.CGImage;
    CGRect imageRect = CGRectZero;
	imageRect.size = CGSizeMake(uiImage.size.width * 2.2f, uiImage.size.height * 2.2f);
    imageRect.origin = CGPointMake((self.frame.size.width - imageRect.size.width) * 0.5f, (self.frame.size.height- imageRect.size.height) * 0.5f);
    CGContextSaveGState(self.context);
    CGContextScaleCTM(self.context, 1.0f, -1.0f);
    CGContextTranslateCTM(self.context, 0.0f, -self.frame.size.height);
    
    float lenPerPitchDegree = kAttitudeTraceLen * self.frame.size.height / 50.0f;
    if (pitch > 90.0f) {
        imageRect.origin.y -= lenPerPitchDegree * (90.0f - (pitch - 90.0f));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * (90.0f - (pitch - 90.0f))) ;
        CGContextRotateCTM(self.context, (180.0f - roll) / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * (90.0f - (pitch - 90.0f))));
    } else if (pitch < -90.0f) {
        imageRect.origin.y -= lenPerPitchDegree * (-90.0f - (pitch - (-90.0f)));
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * (-90.0f - (pitch - (-90.0f))));
        CGContextRotateCTM(self.context, roll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * (-90.0f - (pitch - (-90.0f)))));
    } else {
        imageRect.origin.y -= lenPerPitchDegree * pitch;
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f - lenPerPitchDegree * pitch) ;
        CGContextRotateCTM(self.context, roll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, - (self.frame.size.height * 0.5f - lenPerPitchDegree * pitch));
    }
    
    CGContextDrawImage(self.context, imageRect, image);
    CGContextRestoreGState(self.context);
}

- (void)drawAttitudeTraceWithRoll:(float)roll picth:(float)pitch {
    CGContextSetRGBStrokeColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(self.context, 2.0f);
    CGContextSaveGState(self.context);
    
    int traceMiddleValue, traceStartValue, traceEndValue, tickStepValue;
    
    if (pitch > 90.0f) {
        if (fabsf(180.0f - pitch) < 1e-4) {
            traceMiddleValue = 0.0f;
        } else {
            traceMiddleValue = 90.0f - (int)pitch % 90;
        }
        float refinedRoll;
        if (roll > 0.0f) {
            refinedRoll = 180.0f - roll;
        } else {
            refinedRoll = -180.0f - roll;
        }
        
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f);
        CGContextRotateCTM(self.context, -refinedRoll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f, self.frame.size.height * 0.5f);
        CGContextRotateCTM(self.context, M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
    } else if (pitch < -90.0f) {
        if (fabsf(180 + pitch) < 1e-4) {
            traceMiddleValue = 0.0f;
        } else {
            traceMiddleValue = -90.0f - (int)pitch % 90;
        }
        float refinedRoll;
        if (roll > 0.0f) {
            refinedRoll = 180.0f - roll;
        } else {
            refinedRoll = -180.0f - roll;
        }
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f);
        CGContextRotateCTM(self.context, -refinedRoll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f );
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f) ;
        CGContextRotateCTM(self.context, M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
    } else {
        traceMiddleValue = pitch;
        CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f);
        CGContextRotateCTM(self.context, - roll / 180.0f * M_PI);
        CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f );
    }
    
    traceStartValue = MIN(90, traceMiddleValue + (int)(kAttitudeTraceRange * 0.5f));
    traceEndValue = MAX(-90, traceMiddleValue - (int)(kAttitudeTraceRange * 0.5f));
    tickStepValue = (int)(kAttitudeTraceInterval / kAttitudeTraceTicksPerInterval);
    
    CGPoint traceStartPos = CGPointMake(self.frame.size.width * kAttitudeTraceX,  self.frame.size.height * 0.5f -  self.frame.size.height * kAttitudeTraceLen * 0.5f);
    CGContextMoveToPoint(self.context, traceStartPos.x, traceStartPos.y);
    CGPoint tickStartPos,tickEndPos;
    float tickLen =  (kAttitudeTraceInterval / (float)kAttitudeTraceTicksPerInterval / (float)kAttitudeTraceRange) * (self.frame.size.height * kAttitudeTraceLen);
    CGContextSetRGBFillColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
    
    CGContextSelectFont(self.context, "Helvetica", 14.0, kCGEncodingMacRoman);
    CGContextSetTextMatrix(self.context, CGAffineTransformMakeScale(1.0, -1.0));
    CGContextSetTextDrawingMode(self.context, kCGTextFill);
    
    float yOffset = (kAttitudeTraceRange * 0.5f - (traceStartValue - traceMiddleValue)) / (float)kAttitudeTraceRange * self.frame.size.height * kAttitudeTraceLen;
    for (int traceValue = traceStartValue, tickIdx = 0; traceValue >= traceEndValue; traceValue -= tickStepValue) {
        if (traceValue % (kAttitudeTraceTicksPerInterval * 2) == 0) {
            tickStartPos = CGPointMake(traceStartPos.x - kAttitudeTraceIntervalMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceIntervalMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            NSString *traceValueStr = [NSString stringWithFormat:@"%d", traceValue];
            CGPoint traceValueStrPos = CGPointMake(tickEndPos.x + 5.0f, tickEndPos.y + 4.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
            traceValueStrPos = CGPointMake(tickStartPos.x - 25.0f, tickEndPos.y + 4.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        } else if (traceValue % kAttitudeTraceTicksPerInterval == 0) {
            tickStartPos = CGPointMake(traceStartPos.x - kAttitudeTraceIntervalMarkLen / 3.0f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceIntervalMarkLen / 3.0f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        } else {
            if (kOrientationTraceNeesDrawTicks) {
                tickStartPos = CGPointMake(traceStartPos.x -  kAttitudeTraceTickMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
                tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceTickMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
                CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
                CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
            }
        }
        tickIdx++;
    }
    CGContextStrokePath(self.context);
    CGContextRestoreGState(self.context);
}

- (void)drawAttitudeTraceWithRoll2:(float)roll picth:(float)pitch {
    CGContextSetRGBStrokeColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(self.context, 2.0f);
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context,self.frame.size.width * 0.5f , self.frame.size.height * 0.5f);
    CGContextRotateCTM(self.context, - roll / 180.0f * M_PI);
    CGContextTranslateCTM(self.context, -self.frame.size.width * 0.5f, -self.frame.size.height * 0.5f);
    
    int traceMiddleValue, traceStartValue, traceEndValue, tickStepValue;
    
    if (pitch > 90.0f) {
        if (fabsf(180.0f - pitch) < 1e-4) {
            traceMiddleValue = 0.0f;
        } else {
            traceMiddleValue = 90.0f - (int)pitch % 90;
        }
    } else if (pitch < -90.0f) {
        if (fabsf(180.0f + pitch) < 1e-4) {
            traceMiddleValue = 0.0f;
        } else {
            traceMiddleValue = -90.0f - (int)pitch % 90;
        }
    } else {
        traceMiddleValue = pitch;
    }
    
    traceStartValue = MIN(90, traceMiddleValue + (int)(kAttitudeTraceRange * 0.5f));
    traceEndValue = MAX(-90, traceMiddleValue - (int)(kAttitudeTraceRange * 0.5f));
    tickStepValue = (int)(kAttitudeTraceInterval / kAttitudeTraceTicksPerInterval);
    
    CGPoint traceStartPos = CGPointMake(self.frame.size.width * kAttitudeTraceX,  self.frame.size.height * 0.5f -  self.frame.size.height * kAttitudeTraceLen * 0.5f);
    CGPoint traceEndPos = CGPointMake(traceStartPos.x, traceStartPos.y + self.frame.size.height * kAttitudeTraceLen);
    CGContextMoveToPoint(self.context, traceStartPos.x, traceStartPos.y);
    CGContextAddLineToPoint(self.context, traceEndPos.x, traceEndPos.y);
    
    CGPoint tickStartPos,tickEndPos;
    float tickLen =  (kAttitudeTraceInterval / (float)kAttitudeTraceTicksPerInterval / (float)kAttitudeTraceRange) * (self.frame.size.height * kAttitudeTraceLen);
    CGContextSetRGBFillColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
    
    CGContextSelectFont(self.context, "Helvetica", 14.0f, kCGEncodingMacRoman);
    CGContextSetTextMatrix(self.context, CGAffineTransformMakeScale(1.0f, -1.0f));
    CGContextSetTextDrawingMode(self.context, kCGTextFill);
    
    float yOffset = (kAttitudeTraceRange * 0.5f - (traceStartValue - traceMiddleValue)) / (float)kAttitudeTraceRange * self.frame.size.height * kAttitudeTraceLen;
    for (int traceValue = traceStartValue, tickIdx = 0; traceValue >= traceEndValue; traceValue -= tickStepValue) {
        if (traceValue % (kAttitudeTraceTicksPerInterval * 2) == 0) {
            tickStartPos = CGPointMake(traceStartPos.x - kAttitudeTraceIntervalMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceIntervalMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            NSString *traceValueStr = [NSString stringWithFormat:@"%d", traceValue];
            CGPoint traceValueStrPos = CGPointMake(tickEndPos.x + 5.0f, tickEndPos.y + 4.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
            traceValueStrPos = CGPointMake(tickStartPos.x - 25.0f, tickEndPos.y + 4.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        } else if (traceValue % kAttitudeTraceTicksPerInterval == 0) {
            tickStartPos = CGPointMake(traceStartPos.x - kAttitudeTraceIntervalMarkLen / 3.0f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceIntervalMarkLen / 3.0f, (traceStartPos.y + yOffset + tickIdx * tickLen));
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        } else {
            if (kOrientationTraceNeesDrawTicks) {
                tickStartPos = CGPointMake(traceStartPos.x -  kAttitudeTraceTickMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
                tickEndPos = CGPointMake(traceStartPos.x + kAttitudeTraceTickMarkLen * 0.5f, (traceStartPos.y + yOffset + tickIdx * tickLen));
                CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
                CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
            }
        }
        tickIdx++;
    }
    
    CGContextStrokePath(self.context);
    CGContextRestoreGState(self.context);
}

- (void)drawAltitudeTrace:(float)altitude {
    CGContextSetRGBStrokeColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(self.context, 2.0f);
    CGContextSetRGBFillColor(self.context, 1.0, 1.0f, 1.0f, 1.0f);
    CGContextSelectFont(self.context, "Helvetica", 14.0f, kCGEncodingMacRoman);
    CGContextSetTextMatrix(self.context, CGAffineTransformMakeScale(1.0f, -1.0f));
    
    CGContextSetTextDrawingMode(self.context, kCGTextFill);
    CGPoint traceStartPos = CGPointMake(self.frame.size.width * kAltitudeTraceX, self.frame.size.height * kAltitudeTraceY);
    CGPoint traceEndPos = CGPointMake(traceStartPos.x, traceStartPos.y + self.frame.size.height * kAltitudeTraceLen);
    CGContextShowTextAtPoint(self.context, traceStartPos.x, traceStartPos.y - 5.0f, "m", 1.0f);
    CGPoint middlePoint = CGPointMake(traceStartPos.x, traceStartPos.y + (traceEndPos.y - traceStartPos.y) * 0.5f);
    NSString *altitudeValueStr = [NSString stringWithFormat:@"%.1f", altitude / 10.0f];
    CGContextShowTextAtPoint(self.context, middlePoint.x -30.0f, middlePoint.y + 2.0f, [altitudeValueStr UTF8String], altitudeValueStr.length);
    CGContextMoveToPoint(self.context, traceStartPos.x, traceStartPos.y);
    CGContextAddLineToPoint(self.context, traceEndPos.x, traceEndPos.y);
    
    int traceMiddleValue = (int)(altitude * 10);
    int traceStartValue = traceMiddleValue + (int)(kAltitudeTraceRange * 0.5f);
    int traceEndValue = traceMiddleValue - (int)(kAltitudeTraceRange * 0.5f);
    int tickStepValue = (int)(kAltitudeTraceInterval / kAltitudeTraceTicksPerInterval);
    
    CGPoint tickStartPos,tickEndPos;
    float tickLen =  (kAltitudeTraceInterval / (float)kAltitudeTraceTicksPerInterval / (float)kAltitudeTraceRange) * (self.frame.size.height * kAltitudeTraceLen);
    for (int traceValue = traceStartValue - tickStepValue, tickIdx = 1; traceValue >= traceEndValue; traceValue -= tickStepValue) {
        tickStartPos = CGPointMake(traceStartPos.x, (traceStartPos.y + tickIdx * tickLen));
        if (traceValue % kAltitudeTraceTicksPerInterval == 0) {
            tickEndPos = CGPointMake(traceStartPos.x + kAltitudeTraceIntervalMarkLen, (traceStartPos.y + tickIdx * tickLen));
            NSString *traceValueStr = [NSString stringWithFormat:@"%.1f", traceValue / 10.0f];
            CGPoint traceValueStrPos = CGPointMake(tickEndPos.x + 5.0f, tickEndPos.y + 4.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
        } else {
            tickEndPos = CGPointMake(traceStartPos.x + kAltitudeTraceTickMarkLen, (traceStartPos.y + tickIdx * tickLen));
        }
        CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
        CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        tickIdx++;
    }
    CGContextStrokePath(self.context);
}

- (void)drawDrone {
    CGImageRef image = self.droneImage.CGImage;
    CGRect imageRect = CGRectZero;
	imageRect.size = CGSizeMake(self.frame.size.width * kDroneWidth, self.droneImage.size.height / self.droneImage.size.width * self.frame.size.width * kDroneWidth);
    imageRect.origin = CGPointMake(self.frame.size.width * 0.5f - imageRect.size.width * 0.5f, self.frame.size.height * 0.5f - imageRect.size.height);
    CGContextSaveGState(self.context);
    CGContextScaleCTM(self.context, 1.0f, -1.0f);
    CGContextTranslateCTM(self.context, 0.0f, -self.frame.size.height);
    CGContextDrawImage(self.context, imageRect, image);
    CGContextRestoreGState(self.context);
}

- (void)drawOrientationTrace:(float)orientation{
    CGContextSetRGBStrokeColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(self.context, 2.0f);
    CGPoint traceStartPos = CGPointMake(self.frame.size.width * kOrientationTraceX, self.frame.size.height * kOrientationTraceY);
    CGPoint traceEndPos = CGPointMake(traceStartPos.x+ self.frame.size.width * kOrientationTraceLen, traceStartPos.y);
    CGContextMoveToPoint(self.context, traceStartPos.x, traceStartPos.y);
    CGContextAddLineToPoint(self.context, traceEndPos.x, traceEndPos.y);
    
    int traceMiddleValue = (int)(orientation) + rand() % 30;
    int traceStartValue = traceMiddleValue - (int)(kOrientationTraceRange * 0.5f);
    int traceEndValue = traceMiddleValue + (int)(kOrientationTraceRange * 0.5f);
    int tickStepValue = (int)(kOrientationTraceInterval / kOrientationTraceTicksPerInterval);
    CGPoint tickStartPos,tickEndPos;
    float tickLen = (kOrientationTraceInterval / (float)kOrientationTraceTicksPerInterval / (float)kOrientationTraceRange) * (self.frame.size.width * kOrientationTraceLen);
    
    CGContextSetRGBFillColor(self.context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextSelectFont(self.context, "Helvetica", 13.0f, kCGEncodingMacRoman);
    CGContextSetTextMatrix(self.context, CGAffineTransformMakeScale(1.0f, -1.0f));
    CGContextSetTextDrawingMode(self.context, kCGTextFill);
    
    for (int traceValue = traceStartValue, tickIdx = 0; traceValue <= traceEndValue; traceValue += tickStepValue, tickIdx++) {
        tickStartPos = CGPointMake(traceStartPos.x  + tickIdx * tickLen, traceStartPos.y);
        if (traceValue % kOrientationTraceTicksPerInterval == 0) {
            tickEndPos = CGPointMake(traceStartPos.x + tickIdx * tickLen, traceStartPos.y -  kOrientationTraceIntervalMarkLen);
            NSString *traceValueStr = [NSString stringWithFormat:@"%d", traceValue % 360];
            
            switch (traceValue % 360) {
                case 0:
                    traceValueStr = @"N";
                    break;
                case 45:
                    traceValueStr = @"NE";
                    break;
                case 90:
                    traceValueStr = @"E";
                    break;
                case 125:
                    traceValueStr = @"SE";
                    break;
                case 180:
                    traceValueStr = @"S";
                    break;
                case 225:
                    traceValueStr = @"SW";
                    break;
                case 270:
                    traceValueStr = @"W";
                    break;
                case 315:
                    traceValueStr = @"NW";
                    break;
                    
                default:
                    break;
            }
            
            CGPoint traceValueStrPos = CGPointMake(tickEndPos.x - 4.0f, tickEndPos.y - 2.0f);
            CGContextShowTextAtPoint(self.context, traceValueStrPos.x, traceValueStrPos.y,[traceValueStr UTF8String], traceValueStr.length);
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
            CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
            CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
        } else {
            if (kOrientationTraceNeesDrawTicks) {
                tickEndPos = CGPointMake(traceStartPos.x + tickIdx * tickLen, traceStartPos.y -  kOrientationTraceTickMarkLen);
                CGContextMoveToPoint(self.context, tickStartPos.x, tickStartPos.y);
                CGContextAddLineToPoint(self.context, tickEndPos.x, tickEndPos.y);
            }
        }
    }
    CGContextStrokePath(self.context);
}

- (void)drawSpeedTrace:(float)spee{
}

- (void)drawRect:(CGRect)rect{
    self.context= UIGraphicsGetCurrentContext();
    NSLog(@"***Roll:%f, ***Pitch:%f ***Alt:%f",_osdData.angleX, -_osdData.angleY, -_osdData.altitude);
    [self drawWorldWithRoll:_osdData.angleX pitch:-_osdData.angleY];
    [self drawAttitudeTraceWithRoll:_osdData.angleX picth:-_osdData.angleY];
    [self drawAltitudeTrace:_osdData.altitude];
    if (_osdData.head < 0) {
        [self drawOrientationTrace:360 + _osdData.head];
    } else {
        [self drawOrientationTrace:_osdData.head];
    }
    [self drawDrone];
}

@end
