//
//  AppDelegate.h
//  FlyingSwallow
//
//  Created by koupoo on 12-12-23.
//  Copyright (c) 2012年 www.hexairbot.com. All rights reserved.
//

#import "FSSlider.h"
#import "Macros.h"
//#import "ARDroneTypes.h"

#define HELVETICA       @"HelveticaNeue-CondensedBold"
#define WHITE(a)        [UIColor colorWithWhite:1.f alpha:(a)]
#define BLACK(a)        [UIColor colorWithWhite:0.f alpha:(a)]
#define ORANGE(a)       [UIColor colorWithRed:255.f/255.f green:120.f/255.f blue:0.f/255.f alpha:(a)]

@interface FSSlider()
@property (nonatomic, readwrite, strong) UILabel* minLabel;
@property (nonatomic, readwrite, strong) UILabel* maxLabel;
@property (nonatomic, assign) CGFloat defaultSliderHeight;
@property (nonatomic, assign) CGFloat sliderHeight;
@property (nonatomic, assign) float minLabelBlackValue;
@property (nonatomic, assign) float maxLabelBlackValue;
@end


@implementation FSSlider

@synthesize minLabel = _minLabel;
@synthesize maxLabel = _maxLabel;

#define LABEL_OFFSET 10.f

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.defaultSliderHeight = self.frame.size.height;
        
        UIImage *scrollBarGray = nil;
        UIImage *scrollBarOrange  = nil;
        UIImage *scrollBtn = nil;
        CGFloat labelSize = 12.f;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
                scrollBarGray = [[UIImage imageNamed:@"scroll_bar_gray_iPad.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
                scrollBarOrange = [[UIImage imageNamed:@"scroll_bar_orange_iPad.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
            } else{
                scrollBarGray = [[UIImage imageNamed:@"scroll_bar_gray_iPad.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20) resizingMode:UIImageResizingModeTile];
                scrollBarOrange = [[UIImage imageNamed:@"scroll_bar_orange_iPad.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)resizingMode:UIImageResizingModeTile];
            }
            
            scrollBtn = [UIImage imageNamed:@"scroll_btn_iPad.png"];
            labelSize = 18.f;
            
        } else {
            if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
                scrollBarGray = [[UIImage imageNamed:@"scroll_bar_gray.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
                scrollBarOrange = [[UIImage imageNamed:@"scroll_bar_orange.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
            } else{
                scrollBarGray = [[UIImage imageNamed:@"scroll_bar_gray.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20) resizingMode:UIImageResizingModeTile];
                scrollBarOrange = [[UIImage imageNamed:@"scroll_bar_orange.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)resizingMode:UIImageResizingModeTile];
            }
            scrollBtn = [UIImage imageNamed:@"scroll_btn.png"];
        }
        
        
        [self setMinimumTrackImage:scrollBarOrange forState:UIControlStateNormal];
        [self setMaximumTrackImage:scrollBarGray forState:UIControlStateNormal];
        [self setThumbImage:scrollBtn forState:UIControlStateNormal];
        
        self.sliderHeight = scrollBtn.size.height;
        
        NSInteger labelValuePrecision = [self tag];
        
        char formatStr[]={"%.0f"};
        
        int precisonIdx = 0;
        
        while (precisonIdx < labelValuePrecision) {
            precisonIdx++;
            formatStr[2] = precisonIdx + '0';
        }
        
        self.minLabel = [[UILabel alloc] init];
        self.maxLabel = [[UILabel alloc] init];
        
        [self.minLabel setFont:[UIFont fontWithName:HELVETICA size:labelSize]];
        [self.minLabel setTextColor:WHITE(1.f)];
        [self.minLabel setBackgroundColor:[UIColor clearColor]];
        [self.minLabel setText:[NSString stringWithFormat:@(formatStr), self.minimumValue]];
        [self.minLabel sizeToFit];
        
        [self.maxLabel setFont:[UIFont fontWithName:HELVETICA size:labelSize]];
        [self.maxLabel setTextColor:WHITE(1.f)];
        [self.maxLabel setBackgroundColor:[UIColor clearColor]];
        [self.maxLabel setText:[NSString stringWithFormat:@(formatStr), self.maximumValue]];
        [self.maxLabel sizeToFit];
        
        CGRect frame = _minLabel.frame;
        frame.origin.x = LABEL_OFFSET;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2.f;
        [_minLabel setFrame:frame];
        
        frame = _maxLabel.frame;
        frame.origin.x = self.frame.size.width - frame.size.width - LABEL_OFFSET;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2.f;
        [_maxLabel setFrame:frame];
        
        self.minLabelBlackValue = ((self.minLabel.frame.size.width + LABEL_OFFSET) / (self.frame.size.width)) * (self.maximumValue - self.minimumValue) + self.minimumValue;
        self.maxLabelBlackValue = (1.0 - ((self.maxLabel.frame.size.width + LABEL_OFFSET) / (self.frame.size.width))) * (self.maximumValue - self.minimumValue) + self.minimumValue;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    //[self addSubview:self.minLabel];
    //[self addSubview:self.maxLabel];
    
    [self insertSubview:self.minLabel atIndex:2];
    [self insertSubview:self.maxLabel atIndex:3];
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    // Called when value changes
    if (value <= self.minLabelBlackValue) {
        [self.minLabel setTextColor:BLACK(1.f)];
    } else {
        [self.minLabel setTextColor:WHITE(1.f)];
    }
    
    if (value >= self.maxLabelBlackValue) {
        [self.maxLabel setTextColor:BLACK(1.f)];
    } else {
        [self.maxLabel setTextColor:WHITE(1.f)];
    }
    
    return [super thumbRectForBounds:bounds trackRect:rect value:value];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, 0.f, self.defaultSliderHeight - self.sliderHeight);
    return CGRectContainsPoint(bounds, point);
}

@end
