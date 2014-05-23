//
//  BasicInfo.h
//  EMagazine
//
//  Created by koupoo on 11-7-5.
//  Copyright 2011 emotioncg.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDView.h"
#import <CoreMotion/CMMotionManager.h>

@interface BasicInfoManager : NSObject

@property (nonatomic, strong) UITextView *debugTextView;
@property (nonatomic, strong) OSDView *osdView;
@property (nonatomic, readonly, strong)  CMMotionManager *motionManager;

+ (id)sharedManager;

@end
