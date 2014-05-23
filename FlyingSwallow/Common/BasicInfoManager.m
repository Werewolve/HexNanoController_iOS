//
//  BasicInfo.m
//  EMagazine
//
//  Created by koupoo on 11-7-5.
//  Copyright 2011 emotioncg.com. All rights reserved.
//

#import "BasicInfoManager.h"

@interface BasicInfoManager ()
@property (nonatomic, readwrite, strong) CMMotionManager *motionManager;
@end

@implementation BasicInfoManager

+ (id)sharedManager {
    static BasicInfoManager* sharedManager = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[BasicInfoManager alloc] init];
	});
	return sharedManager;
}

- (CMMotionManager *)motionManager{
    if (!_motionManager) {
        self.motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

@end
