//
//  HudViewController.m
//  FlyingSwallow
//
//  Created by koupoo on 12-12-21. Email: koupoo@126.com
//  Copyright (c) 2012年 www.hexairbot.com. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License V2
//  as published by the Free Software Foundation.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "HudViewController.h"
#import <mach/mach_time.h>
#import "Macros.h"
#import "util.h"
#import "BlockViewStyle1.h"
#import "Transmitter.h"
#import "BasicInfoManager.h"
#import "OSDCommon.h"
#import "HelpViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMotion/CoreMotion.h>

#define UDP_SERVER_HOST @"192.168.0.1"
#define UDP_SERVER_PORT 6000

#define kThrottleFineTuningStep 0.03f
#define kBeginnerElevatorChannelRatio  0.5f
#define kBeginnerAileronChannelRatio   0.5f
#define kBeginnerRudderChannelRatio    0.0f
#define kBeginnerThrottleChannelRatio  0.8f

static inline float sign(float value) {
	float result = 1.0f;
	if (value < 0.0f) {
		result = -1.0f;
    }
	return result;
}

@interface HudViewController ()

@property (nonatomic, assign) CGPoint joystickRightCurrentPosition, joystickLeftCurrentPosition;
@property (nonatomic, assign) CGPoint joystickRightInitialPosition, joystickLeftInitialPosition;
@property (nonatomic, assign) BOOL buttonRightPressed, buttonLeftPressed;
@property (nonatomic, assign) CGPoint rightCenter, leftCenter;

@property (nonatomic, assign) float joystickAlpha;

@property (nonatomic, assign) BOOL isLeftHanded;
@property (nonatomic, assign) BOOL accModeEnabled;
@property (nonatomic, assign) BOOL accModeReady;

@property (nonatomic, assign) float rightJoyStickOperableRadius;
@property (nonatomic, assign) float leftJoyStickOperableRadius;

@property (nonatomic, assign) BOOL isTransmitting;

@property (nonatomic, assign) BOOL rudderIsLocked;
@property (nonatomic, assign) BOOL throttleIsLocked;

@property (nonatomic, assign) CGPoint rudderLockButtonCenter;
@property (nonatomic, assign) CGPoint throttleUpButtonCenter;
@property (nonatomic, assign) CGPoint throttleDownButtonCenter;
@property (nonatomic, assign) CGPoint upIndicatorImageViewCenter;
@property (nonatomic, assign) CGPoint downIndicatorImageViewCenter;

@property (nonatomic, assign) CGPoint leftHandedRudderLockButtonCenter;
@property (nonatomic, assign) CGPoint leftHandedThrottleUpButtonCenter;
@property (nonatomic, assign) CGPoint leftHandedThrottleDownButtonCenter;
@property (nonatomic, assign) CGPoint leftHandedUpIndicatorImageViewCenter;
@property (nonatomic, assign) CGPoint leftHandedDownIndicatorImageViewCenter;

@property (nonatomic, strong) NSMutableDictionary *blockViewDict;

@property(nonatomic, strong) Channel *aileronChannel;
@property(nonatomic, strong) Channel *elevatorChannel;
@property(nonatomic, strong) Channel *rudderChannel;
@property(nonatomic, strong) Channel *throttleChannel;
@property(nonatomic, strong) Channel *aux1Channel;
@property(nonatomic, strong) Channel *aux2Channel;
@property(nonatomic, strong) Channel *aux3Channel;
@property(nonatomic, strong) Channel *aux4Channel;

@property(nonatomic, strong) Settings *settings;

@property(nonatomic, strong) SettingsMenuViewController *settingMenuVC;
@property(nonatomic, strong) HelpViewController *helpVC;

@end


@implementation HudViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissSettingsMenuView) name:kNotificationDismissSettingsMenuView object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissHelpView) name:kNotificationDismissHelpView object:nil];
        
        NSString *documentsDir= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *userSettingsFilePath = [documentsDir stringByAppendingPathComponent:@"Settings.plist"];
        
        self.settings = [[Settings alloc] initWithSettingsFile:userSettingsFilePath];
        UIDevice *device = [UIDevice currentDevice];
        device.batteryMonitoringEnabled = YES;
        [device addObserver:self forKeyPath:@"batteryLevel" options:NSKeyValueObservingOptionNew context:nil];
        
        CMMotionManager *motionManager = [[BasicInfoManager sharedManager] motionManager];
        if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
            motionManager.accelerometerUpdateInterval = 1.0 / 40;
            [motionManager startAccelerometerUpdates];
            NSLog(@"ACCELERO     [OK]");
        } else if (motionManager.deviceMotionAvailable == 1) {
            motionManager.deviceMotionUpdateInterval = 1.0 / 40;
            [motionManager startDeviceMotionUpdates];
            NSLog(@"ACCELERO     [OK]");
            NSLog(@"GYRO         [OK]");
        } else {
            NSLog(@"DEVICE MOTION ERROR - DISABLE");
            self.accModeEnabled = FALSE;
        }
        [self setAcceleroRotationWithPhi:0.0f withTheta:0.0f withPsi:0.0f];
        [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0 / 40) target:self selector:@selector(motionDataHandler) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.rudderLockButtonCenter = self.rudderLockButton.center;
    self.throttleUpButtonCenter = self.throttleUpButton.center;
    self.throttleDownButtonCenter = self.throttleDownButton.center;
    self.upIndicatorImageViewCenter = self.upIndicatorImageView.center;
    self.downIndicatorImageViewCenter = self.downIndicatorImageView.center;
    
    float hudFrameWidth = [[UIScreen mainScreen] bounds].size.height;
    
    self.leftHandedRudderLockButtonCenter = CGPointMake(hudFrameWidth - self.rudderLockButtonCenter.x, self.rudderLockButtonCenter.y);
    self.leftHandedThrottleUpButtonCenter = CGPointMake(hudFrameWidth - self.throttleUpButtonCenter.x, self.throttleUpButtonCenter.y);
    self.leftHandedThrottleDownButtonCenter = CGPointMake(hudFrameWidth - self.throttleDownButtonCenter.x, self.throttleDownButtonCenter.y);
    self.leftHandedUpIndicatorImageViewCenter = CGPointMake(hudFrameWidth - self.upIndicatorImageViewCenter.x, self.upIndicatorImageViewCenter.y);
    self.leftHandedDownIndicatorImageViewCenter = CGPointMake(hudFrameWidth - self.downIndicatorImageViewCenter.x, self.downIndicatorImageViewCenter.y);
    
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        self.rightJoyStickOperableRadius =  115.0f;
        self.leftJoyStickOperableRadius  =  115.0f;
    } else {
        self.rightJoyStickOperableRadius =  70.0f;
        self.leftJoyStickOperableRadius  =  70.0f;
    }
    
    self.aileronChannel = [self.settings channelByName:kChannelNameAileron];
    self.elevatorChannel = [self.settings channelByName:kChannelNameElevator];
    self.rudderChannel = [self.settings channelByName:kChannelNameRudder];
    self.throttleChannel = [self.settings channelByName:kChannelNameThrottle];
    self.aux1Channel = [self.settings channelByName:kChannelNameAUX1];
    self.aux2Channel = [self.settings channelByName:kChannelNameAUX2];
    self.aux3Channel = [self.settings channelByName:kChannelNameAUX3];
    self.aux4Channel = [self.settings channelByName:kChannelNameAUX4];
    
	self.rightCenter = CGPointMake(self.joystickRightThumbImageView.frame.origin.x + (self.joystickRightThumbImageView.frame.size.width * 0.5f), self.joystickRightThumbImageView.frame.origin.y + (self.joystickRightThumbImageView.frame.size.height * 0.5f));
	self.joystickRightInitialPosition = CGPointMake(self.rightCenter.x - (self.joystickRightBackgroundImageView.frame.size.width * 0.5f), self.rightCenter.y - (self.joystickRightBackgroundImageView.frame.size.height * 0.5f));
	self.leftCenter = CGPointMake(self.joystickLeftThumbImageView.frame.origin.x + (self.joystickLeftThumbImageView.frame.size.width * 0.5f), self.joystickLeftThumbImageView.frame.origin.y + (self.joystickLeftThumbImageView.frame.size.height * 0.5f));
	self.joystickLeftInitialPosition = CGPointMake(self.leftCenter.x - (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.leftCenter.y - (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f));
    
	self.joystickLeftCurrentPosition = self.joystickLeftInitialPosition;
	self.joystickRightCurrentPosition = self.joystickRightInitialPosition;
	
    self.joystickAlpha = self.settings.interfaceOpacity;
    
	self.joystickRightBackgroundImageView.alpha = self.joystickRightThumbImageView.alpha = self.joystickAlpha;
	self.joystickLeftBackgroundImageView.alpha = self.joystickLeftThumbImageView.alpha = self.joystickAlpha;
	
	[self setBattery:(int)([UIDevice currentDevice].batteryLevel * 100)];
    
    [self updateJoystickCenter];
    [self updateStatusInfoLabel];
    [self updateThrottleValueLabel];
    
    [self settingsMenuViewController:nil leftHandedValueDidChange:_settings.isLeftHanded];
    [self settingsMenuViewController:nil accModeValueDidChange:_settings.isAccMode];
    
    [self updateJoysticksForAccModeChanged];
    
    if (self.isTransmitting == NO) {
        [self startTransmission];
    }
    
    if (self.blockViewDict == nil) {
        self.blockViewDict = [[NSMutableDictionary alloc] init];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkTransmitterState) name:kNotificationTransmitterStateDidChange object:nil];
    
    //[[BasicInfoManager sharedManager] setDebugTextView:debugTextView];
    [[BasicInfoManager sharedManager] setOsdView:self.osdView];
    
    self.warningLabel.text = NSLocalizedString(@"not connected", nil);
    
    [self setSwitchButton:self.altHoldSwitchButton withValue:self.settings.isAltHoldMode];
    
    if (self.settings.isHeadFreeMode) {
        [self.aux1Channel setValue:1];
    } else {
        [self.aux1Channel setValue:-1];
    }
    
    if (self.settings.isAltHoldMode) {
        [self.aux2Channel setValue:1];
    } else {
        [self.aux2Channel setValue:-1];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    
    if (self.settings.isBeginnerMode) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Beginner Mode", nil) message:NSLocalizedString(@"Beginner Mode Info", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.settingMenuVC = nil;
    self.helpVC = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationDismissSettingsMenuView object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationDismissHelpView object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationTransmitterStateDidChange object:nil];
    
    [self stopTransmission];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"batteryLevel"] || [object isEqual:[UIDevice currentDevice]]) {
        [self setBattery:(int)([UIDevice currentDevice].batteryLevel * 100)];
    }
}

#pragma mark SettingsMenuViewControllerDelegate Methods

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl interfaceOpacityValueDidChange:(float)newValue {
    self.joystickAlpha = newValue;
    self.joystickLeftBackgroundImageView.alpha = self.joystickAlpha;
    self.joystickLeftThumbImageView.alpha = self.joystickAlpha;
    self.joystickRightBackgroundImageView.alpha = self.joystickAlpha;
    self.joystickRightThumbImageView.alpha = self.joystickAlpha;
}

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl leftHandedValueDidChange:(BOOL)enabled {
    self.isLeftHanded = enabled;
    
    [self josystickButtonDidTouchUp:self.joystickLeftButton forEvent:nil];
    [self josystickButtonDidTouchUp:self.joystickRightButton forEvent:nil];
    
    if (self.isLeftHanded) {
        self.joystickLeftThumbImageView.image = [UIImage imageNamed:@"Joystick_Manuel_RETINA.png"];
        self.joystickRightThumbImageView.image = [UIImage imageNamed:@"Joystick_Gyro_RETINA.png"];
        
        self.rudderLockButton.center = self.leftHandedRudderLockButtonCenter;
        self.throttleUpButton.center = self.leftHandedThrottleUpButtonCenter;
        self.throttleDownButton.center  = self.leftHandedThrottleDownButtonCenter;
        self.upIndicatorImageView.center = self.leftHandedUpIndicatorImageViewCenter;
        self.downIndicatorImageView.center = self.leftHandedDownIndicatorImageViewCenter;
    } else {
        self.joystickLeftThumbImageView.image = [UIImage imageNamed:@"Joystick_Gyro_RETINA.png"];
        self.joystickRightThumbImageView.image = [UIImage imageNamed:@"Joystick_Manuel_RETINA.png"];
        
        self.rudderLockButton.center = self.rudderLockButtonCenter;
        self.throttleUpButton.center = self.throttleUpButtonCenter;
        self.throttleDownButton.center = self.throttleDownButtonCenter;
        self.upIndicatorImageView.center = self.upIndicatorImageViewCenter;
        self.downIndicatorImageView.center = self.downIndicatorImageViewCenter;
    }
    [self updateJoysticksForAccModeChanged];
}

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl accModeValueDidChange:(BOOL)enabled{
    CMMotionManager *motionManager = [[BasicInfoManager sharedManager] motionManager];
    if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
        self.accModeEnabled = enabled;
    } else if (motionManager.deviceMotionAvailable == 1) {
        self.accModeEnabled = enabled;
    } else {
        self.accModeEnabled = NO;
    }
    [self updateJoysticksForAccModeChanged];
}

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl beginnerModeValueDidChange:(BOOL)enabled {
}

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl headfreeModeValueDidChange:(BOOL)enabled {
    if (self.settings.isHeadFreeMode) {
        [self.aux1Channel setValue:1];
    } else {
        [self.aux1Channel setValue:-1];
    }
}

- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl ppmPolarityReversed:(BOOL)enabled {
    [self stopTransmission];
    [self startTransmission];
}

#pragma mark SettingsMenuViewControllerDelegate Methods end

- (void)blockJoystickHudForTakingOff {
	NSString *blockViewIdentifier = [NSString stringWithFormat:@"%d",  ViewBlockJoyStickHud];
	
	if ([self.blockViewDict valueForKey:blockViewIdentifier] != nil) {
		return;
    }
    
    CGRect blockViewPart1Frame = self.view.frame;
    blockViewPart1Frame.origin.x = 0.0f;
    blockViewPart1Frame.origin.y = 0.0f;
    blockViewPart1Frame.size.width = [[UIScreen mainScreen] bounds].size.height;
    blockViewPart1Frame.size.height = self.joystickLeftButton.frame.origin.y + self.joystickLeftButton.frame.size.height;
    
	BlockViewStyle1 *blockViewPart1 = [[BlockViewStyle1 alloc] initWithFrame:blockViewPart1Frame];
	blockViewPart1.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
	blockViewPart1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	UIView *blockView = blockViewPart1;
    
	[self.view addSubview:blockView];
	[self.blockViewDict setValue:blockView forKey:[NSString stringWithFormat:@"%d",  ViewBlockJoyStickHud]];
}

- (void)unblockJoystickHudForTakingOff:(BOOL)animated {
	NSString *blockViewIdentifier = [NSString stringWithFormat:@"%d", ViewBlockJoyStickHud];
	UIView *blockView = [self.blockViewDict valueForKey:blockViewIdentifier];
	
	if (!blockView) {
		return;
    }
	
	if (animated) {
		[UIView animateWithDuration:1 animations:^{
            blockView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [blockView removeFromSuperview];
            [self.blockViewDict removeObjectForKey:blockViewIdentifier];
        }];
	} else {
		[blockView removeFromSuperview];
		[self.blockViewDict removeObjectForKey:blockViewIdentifier];
	}
}

- (void)blockJoystickHudForStopping {
	NSString *blockViewIdentifier = [NSString stringWithFormat:@"%d", ViewBlockJoyStickHud2];
	
	if ([self.blockViewDict valueForKey:blockViewIdentifier] != nil) {
		return;
    }
    
    CGRect blockViewPart1Frame = self.view.frame;
    blockViewPart1Frame.origin.x = 0.0f;
    blockViewPart1Frame.origin.y = self.joystickLeftButton.frame.origin.y;
    blockViewPart1Frame.size.width = [[UIScreen mainScreen] bounds].size.height;
    blockViewPart1Frame.size.height = self.joystickLeftButton.frame.origin.y + self.joystickLeftButton.frame.size.height - self.joystickLeftButton.frame.origin.y;
    
	BlockViewStyle1 *blockViewPart1 = [[BlockViewStyle1 alloc] initWithFrame:blockViewPart1Frame];
	blockViewPart1.backgroundColor = [UIColor whiteColor];
	blockViewPart1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	UIView *blockView = blockViewPart1;
    
	[self.view addSubview:blockView];
	[self.blockViewDict setValue:blockView forKey:[NSString stringWithFormat:@"%d",  ViewBlockJoyStickHud2]];
}

- (void)unblockJoystickHudForStopping:(BOOL)animated {
	NSString *blockViewIdentifier = [NSString stringWithFormat:@"%d", ViewBlockJoyStickHud2];
	UIView *blockView = [self.blockViewDict valueForKey:blockViewIdentifier];
	
	if (!blockView) {
		return;
    }
	
	if (animated) {
		[UIView animateWithDuration:1 animations:^{
            blockView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [blockView removeFromSuperview];
            [self.blockViewDict removeObjectForKey:blockViewIdentifier];
        }];
	} else {
		[blockView removeFromSuperview];
		[self.blockViewDict removeObjectForKey:blockViewIdentifier];
	}
}

- (void)updateStatusInfoLabel {
    if (self.throttleIsLocked) {
        if (self.rudderIsLocked) {
            self.statusInfoLabel.text = NSLocalizedString(@"Throttle Rudder Locked", nil);
        } else {
            self.statusInfoLabel.text = NSLocalizedString(@"Throttle Locked", nil);
        }
    } else {
        if (self.rudderIsLocked) {
            self.statusInfoLabel.text = NSLocalizedString(@"Rudder Locked", nil);
        } else {
            self.statusInfoLabel.text = @"";
        }
    }
}

- (void)updateJoystickCenter {
    self.rightCenter = CGPointMake(self.joystickRightInitialPosition.x + (self.joystickRightBackgroundImageView.frame.size.width * 0.5f), self.joystickRightInitialPosition.y +  (self.joystickRightBackgroundImageView.frame.size.height * 0.5f));
    self.leftCenter = CGPointMake(self.joystickLeftInitialPosition.x + (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.joystickLeftInitialPosition.y +  (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f));
    
    if (self.isLeftHanded) {
        self.joystickLeftThumbImageView.center = CGPointMake(self.leftCenter.x, self.leftCenter.y - self.throttleChannel.value * self.leftJoyStickOperableRadius);
    } else {
        self.joystickRightThumbImageView.center = CGPointMake(self.rightCenter.x, self.rightCenter.y - self.throttleChannel.value * self.rightJoyStickOperableRadius);
    }
}

- (void)updateUI {
    OSDData *osdData = [Transmitter sharedTransmitter].osdData;
    self.rollValueTextLabel.text = [NSString stringWithFormat:@"%.1f", osdData.angleX];
    self.pitchValueTextLabel.text = [NSString stringWithFormat:@"%.1f", osdData.angleY];
    self.headAngleValueTextLabel.text = [NSString stringWithFormat:@"%.1f", osdData.head];
    self.altValueTextLabel.text = [NSString stringWithFormat:@"%.1f", osdData.altitude];
}

- (void)checkTransmitterState {
    NSLog(@"checkTransmitterState", nil);
    
    TransmitterState inputState = [[Transmitter sharedTransmitter] inputState];
    TransmitterState outputState = [[Transmitter sharedTransmitter] outputState];
    
    if ((inputState == TransmitterStateOk) && (outputState == TransmitterStateOk)) {
        self.warningLabel.text = NSLocalizedString(@"connected", nil);
        [self.warningLabel setTextColor:[self.batteryLevelLabel textColor]];
        self.warningView.hidden = YES;
    } else if ((inputState == TransmitterStateOk) && (outputState != TransmitterStateOk)) {
        self.warningLabel.text = NSLocalizedString(@"not connected", nil);
        [self.warningLabel setTextColor:[UIColor redColor]];
        self.warningView.hidden = NO;
    } else if ((inputState != TransmitterStateOk) && (outputState == TransmitterStateOk)) {
        self.warningLabel.text = NSLocalizedString(@"not connected", nil);
        [self.warningLabel setTextColor:[UIColor redColor]];
        self.warningView.hidden = NO;
    } else {
        self.warningLabel.text = @"not connected";
        [self.warningLabel setTextColor:[UIColor redColor]];
        self.warningView.hidden = NO;
    }
}

- (OSStatus)startTransmission {
    enum PpmPolarity polarity = PPM_POLARITY_POSITIVE;
    if (_settings.ppmPolarityIsNegative) {
        polarity = PPM_POLARITY_NEGATIVE;
    }
    BOOL s = [[Transmitter sharedTransmitter] start];
    self.isTransmitting = s;
    self.osdView.osdData = [Transmitter sharedTransmitter].osdData;
    return s;
}

- (OSStatus)stopTransmission {
    if (self.isTransmitting) {
        BOOL s = [[Transmitter sharedTransmitter] stop];
        self.isTransmitting = !s;
        return !s;
    } else {
        return 0;
    }
}

- (void)dismissSettingsMenuView {
    if (self.settingMenuVC.view != nil)
        [self.settingMenuVC.view removeFromSuperview];
}

- (void)dismissHelpView {
    if (self.helpVC.view != nil) {
        [self.helpVC.view removeFromSuperview];
        self.helpVC = nil;
    }
}

- (void)hideBatteryLevelUI {
	self.batteryLevelLabel.hidden = YES;
	self.batteryImageView.hidden = YES;
}

- (void)showBatteryLevelUI {
	self.batteryLevelLabel.hidden = NO;
	self.batteryImageView.hidden = NO;
}

- (void)setBattery:(int)percent {
    static NSInteger prevImage = -1;
    static NSInteger prevPercent = -1;
    static BOOL wasHidden = NO;
	if (percent < 0 && !wasHidden) {
		[self performSelectorOnMainThread:@selector(hideBatteryLevelUI) withObject:nil waitUntilDone:YES];
        wasHidden = YES;
	} else if (percent >= 0) {
        if (wasHidden) {
            [self performSelectorOnMainThread:@selector(showBatteryLevelUI) withObject:nil waitUntilDone:YES];
            wasHidden = NO;
        }
        NSInteger imageNumber = ((percent < 10) ? 0 : (int)((percent / 33.4f) + 1));
        if (prevImage != imageNumber) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"Btn_Battery_%ld_RETINA.png", (long)imageNumber]];
            [self.batteryImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
            prevImage = imageNumber;
        }
        if (prevPercent != percent) {
            prevPercent = percent;
            [self.batteryLevelLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%d%%", percent] waitUntilDone:YES];
        }
	}
}

- (void)refreshJoystickRight {
	CGRect frame = self.joystickRightBackgroundImageView.frame;
	frame.origin = self.joystickRightCurrentPosition;
	self.joystickRightBackgroundImageView.frame = frame;
}

- (void)refreshJoystickLeft {
	CGRect frame = self.joystickLeftBackgroundImageView.frame;
	frame.origin = self.joystickLeftCurrentPosition;
	self.joystickLeftBackgroundImageView.frame = frame;
}

- (void)updateVelocity:(CGPoint)point isRight:(BOOL)isRight {
    static BOOL _runOnce = YES;
    static float leftThumbWidth = 0.0f;
    static float rightThumbWidth = 0.0f;
    static float leftThumbHeight = 0.0f;
    static float rightThumbHeight = 0.0f;
    static float leftRadius = 0.0f;
    static float rightRadius = 0.0f;
    
    if (_runOnce) {
        leftThumbWidth = self.joystickLeftThumbImageView.frame.size.width;
        rightThumbWidth = self.joystickRightThumbImageView.frame.size.width;
        leftThumbHeight = self.joystickLeftThumbImageView.frame.size.height;
        rightThumbHeight = self.joystickRightThumbImageView.frame.size.height;
        leftRadius = self.joystickLeftBackgroundImageView.frame.size.width * 0.5f;
        rightRadius = self.joystickRightBackgroundImageView.frame.size.width * 0.5f;
        _runOnce = NO;
    }
    
	CGPoint nextpoint = CGPointMake(point.x, point.y);
	CGPoint center = (isRight ? self.rightCenter : self.leftCenter);
	UIImageView *thumbImage = (isRight ? self.joystickRightThumbImageView : self.joystickLeftThumbImageView);
	
	float dx = nextpoint.x - center.x;
	float dy = nextpoint.y - center.y;
    
    float thumb_radius = isRight ? self.rightJoyStickOperableRadius : self.leftJoyStickOperableRadius;
	
    if (fabsf(dx) > thumb_radius) {
        if (dx > 0.0f) {
            nextpoint.x = center.x + self.rightJoyStickOperableRadius;
        } else {
            nextpoint.x = center.x - self.rightJoyStickOperableRadius;
        }
    }
    
    if (fabsf(dy) > thumb_radius) {
        if (dy > 0.0f) {
            nextpoint.y = center.y + self.rightJoyStickOperableRadius;
        } else {
            nextpoint.y = center.y - self.rightJoyStickOperableRadius;
        }
    }
    
	CGRect frame = thumbImage.frame;
	frame.origin.x = nextpoint.x - (thumbImage.frame.size.width * 0.5f);
	frame.origin.y = nextpoint.y - (thumbImage.frame.size.height * 0.5f);
	thumbImage.frame = frame;
}

- (void)updateThrottleValueLabel {
    float takeOffValue = clip(-1.0f + _settings.takeOffThrottle * 2.0f + _throttleChannel.trimValue, -1.0f, 1.0f);
    if (_throttleChannel.isReversing) {
        takeOffValue = -takeOffValue;
    }
    self.throttleValueLabel.text = [NSString stringWithFormat:@"%d", (int)(1500 + 500 * _throttleChannel.value)];
}

- (void)setSwitchButton:(UIButton *)switchButton withValue:(BOOL)active {
    if (active) {
        switchButton.tag = SWITCH_BUTTON_CHECKED;
        [switchButton setImage:[UIImage imageNamed:@"Btn_ON.png"] forState:UIControlStateNormal];
    } else {
        switchButton.tag = SWITCH_BUTTON_UNCHECKED;
        [switchButton setImage:[UIImage imageNamed:@"Btn_OFF.png"] forState:UIControlStateNormal];
    }
}

- (void)toggleSwitchButton:(UIButton *)switchButton {
    [self setSwitchButton:switchButton withValue:(SWITCH_BUTTON_UNCHECKED == switchButton.tag) ? YES : NO];
}

- (IBAction)switchButtonClick:(id)sender {
    [self toggleSwitchButton:sender];
    
    if (sender == self.altHoldSwitchButton) {
        self.settings.isAltHoldMode = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if (self.settings.isAltHoldMode) {
            [self.aux2Channel setValue:1];
        } else {
            [self.aux2Channel setValue:-1];
        }
    }
}

- (IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:sender] anyObject];
	CGPoint current_location = [touch locationInView:self.view];
    static CGPoint previous_location;
    previous_location = current_location;
    
	if (sender == self.joystickRightButton) {
        static uint64_t right_press_previous_time = 0;
        if (right_press_previous_time == 0) {
            right_press_previous_time = mach_absolute_time();
        }
        
        uint64_t current_time = mach_absolute_time();
        static mach_timebase_info_data_t sRightPressTimebaseInfo;
        uint64_t elapsedNano;
        float dt = 0.0f;
        
        if (sRightPressTimebaseInfo.denom == 0) {
            (void)mach_timebase_info(&sRightPressTimebaseInfo);
        }
        elapsedNano = (current_time-right_press_previous_time)*(sRightPressTimebaseInfo.numer / sRightPressTimebaseInfo.denom);
        dt = elapsedNano/1000000000.0f;
        
        right_press_previous_time = current_time;
        
        if (dt > 0.1 && dt < 0.3) {
            if (_settings.isBeginnerMode) {
                if (self.throttleChannel.value + kThrottleFineTuningStep > 1.0f + (kBeginnerThrottleChannelRatio - 1.0f)) {
                    self.throttleChannel.value = 1.0f;
                } else {
                    self.throttleChannel.value += kThrottleFineTuningStep;
                }
            } else {
                if (self.throttleChannel.value + kThrottleFineTuningStep > 1.0f) {
                    self.throttleChannel.value = 1.0f;
                } else {
                    self.throttleChannel.value += kThrottleFineTuningStep;
                }
            }
            [self updateJoystickCenter];
        }
        
		self.buttonRightPressed = YES;
		self.joystickRightBackgroundImageView.alpha = self.joystickRightThumbImageView.alpha = 1.0f;
        CGPoint xjoystickRightCurrentPosition = self.joystickRightCurrentPosition;
        xjoystickRightCurrentPosition.x = current_location.x - (self.joystickRightBackgroundImageView.frame.size.width * 0.5f);
        self.joystickRightCurrentPosition = xjoystickRightCurrentPosition;
        
        CGPoint thumbCurrentLocation = CGPointZero;
        if (self.isLeftHanded) {
            xjoystickRightCurrentPosition.y = current_location.y - (self.joystickRightBackgroundImageView.frame.size.height * 0.5f);
            self.joystickRightCurrentPosition = xjoystickRightCurrentPosition;
            [self refreshJoystickRight];
            self.rightCenter = CGPointMake(self.joystickRightBackgroundImageView.frame.origin.x + (self.joystickRightBackgroundImageView.frame.size.width * 0.5f),self. joystickRightBackgroundImageView.frame.origin.y + (self.joystickRightBackgroundImageView.frame.size.height * 0.5f));
            thumbCurrentLocation = self.rightCenter;
        } else {
            float throttleValue = [_throttleChannel value];
            xjoystickRightCurrentPosition.y = current_location.y - (self.joystickRightBackgroundImageView.frame.size.height * 0.5f) + throttleValue * self.rightJoyStickOperableRadius;
            self.joystickRightCurrentPosition = xjoystickRightCurrentPosition;
            [self refreshJoystickRight];
            self.rightCenter = CGPointMake(self.joystickRightBackgroundImageView.frame.origin.x + (self.joystickRightBackgroundImageView.frame.size.width * 0.5f), self.joystickRightBackgroundImageView.frame.origin.y + (self.joystickRightBackgroundImageView.frame.size.height * 0.5f));
            thumbCurrentLocation = CGPointMake(self.rightCenter.x, current_location.y);
        }
        [self updateVelocity:thumbCurrentLocation isRight:YES];
	} else if (sender == self.joystickLeftButton) {
        static uint64_t left_press_previous_time = 0;
        if (left_press_previous_time == 0) {
            left_press_previous_time = mach_absolute_time();
        }
        
        uint64_t current_time = mach_absolute_time();
        static mach_timebase_info_data_t sLeftPressTimebaseInfo;
        uint64_t elapsedNano;
        float dt = 0;
        
        if (sLeftPressTimebaseInfo.denom == 0) {
            (void) mach_timebase_info(&sLeftPressTimebaseInfo);
        }
        elapsedNano = (current_time-left_press_previous_time)*(sLeftPressTimebaseInfo.numer / sLeftPressTimebaseInfo.denom);
        dt = elapsedNano/1000000000.0f;
        left_press_previous_time = current_time;
        
        if (dt > 0.1f && dt < 0.3f) {
            if (_throttleChannel.value - kThrottleFineTuningStep < -1.0f) {
                _throttleChannel.value = -1.0f;
            } else {
                _throttleChannel.value -= kThrottleFineTuningStep;
            }
            [self updateJoystickCenter];
        }
        
		self.buttonLeftPressed = YES;
        self.joystickLeftBackgroundImageView.alpha = self.joystickLeftThumbImageView.alpha = 1.0f;
		
        CGPoint xjoystickLeftCurrentPosition = current_location;
		xjoystickLeftCurrentPosition.x = current_location.x - (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f);
        self.joystickLeftCurrentPosition = xjoystickLeftCurrentPosition;
        CGPoint thumbCurrentLocation = CGPointZero;
        
        if (self.isLeftHanded) {
            float throttleValue = [_throttleChannel value];
            xjoystickLeftCurrentPosition.y = current_location.y - (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f) + throttleValue * self.leftJoyStickOperableRadius;
            self.joystickLeftCurrentPosition = xjoystickLeftCurrentPosition;
            [self refreshJoystickLeft];
            self.leftCenter = CGPointMake(self.joystickLeftBackgroundImageView.frame.origin.x + (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.joystickLeftBackgroundImageView.frame.origin.y + (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f));
            thumbCurrentLocation = CGPointMake(self.leftCenter.x, current_location.y);
        } else {
            xjoystickLeftCurrentPosition.y = current_location.y - (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f);
            self.joystickLeftCurrentPosition = xjoystickLeftCurrentPosition;
            [self refreshJoystickLeft];
            self.leftCenter = CGPointMake(self.joystickLeftBackgroundImageView.frame.origin.x + (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.joystickLeftBackgroundImageView.frame.origin.y + (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f));
            thumbCurrentLocation = self.leftCenter;
        }
		[self updateVelocity:thumbCurrentLocation isRight:NO];
	}
    
    if (self.accModeEnabled) {
        if (self.isLeftHanded) {
            if (sender == self.joystickRightButton) {
                self.accModeReady = YES;
            }
        } else {
            if (sender == self.joystickLeftButton) {
                self.accModeReady = YES;
            }
        }
    }
    
    if (self.accModeEnabled && self.accModeReady) {
        CMMotionManager *motionManager = [[BasicInfoManager sharedManager] motionManager];
        CMAcceleration current_acceleration;
        float phi, theta;
        
        if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
            current_acceleration.x = motionManager.accelerometerData.acceleration.x;
            current_acceleration.y = motionManager.accelerometerData.acceleration.y;
            current_acceleration.z = motionManager.accelerometerData.acceleration.z;
        } else if (motionManager.deviceMotionAvailable == 1) {
            current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
            current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
            current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
        }
        theta = atan2f(current_acceleration.x, sqrtf(current_acceleration.y * current_acceleration.y + current_acceleration.z * current_acceleration.z));
        phi = -atan2f(current_acceleration.y, sqrtf(current_acceleration.x * current_acceleration.x + current_acceleration.z * current_acceleration.z));
        [self setAcceleroRotationWithPhi:phi withTheta:theta withPsi:0];
    }
}

- (IBAction)josystickButtonDidTouchUp:(id)sender forEvent:(UIEvent *)event {
	if (sender == self.joystickRightButton) {
		self.buttonRightPressed = NO;
		self.joystickRightCurrentPosition = self.joystickRightInitialPosition;
		self.joystickRightBackgroundImageView.alpha = self.joystickRightThumbImageView.alpha = self.joystickAlpha;
		[self refreshJoystickRight];
        
        if (self.isLeftHanded) {
            [self.aileronChannel setValue:0.0f];
            [self.elevatorChannel setValue:0.0f];
            self.rightCenter = CGPointMake(self.joystickRightBackgroundImageView.frame.origin.x + (self.joystickRightBackgroundImageView.frame.size.width * 0.5f), self.joystickRightBackgroundImageView.frame.origin.y + (self.joystickRightBackgroundImageView.frame.size.height * 0.5f));
            self.accModeReady = NO;
            if (self.accModeEnabled) {
                [self setAcceleroRotationWithPhi:0.0f withTheta:0.0f withPsi:0.0f];
            }
        } else {
            [self.rudderChannel setValue:0.0f];
            float throttleValue = [self.throttleChannel value];
            self.rightCenter = CGPointMake(self.joystickRightBackgroundImageView.frame.origin.x + (self.joystickRightBackgroundImageView.frame.size.width * 0.5f), self.joystickRightBackgroundImageView.frame.origin.y + (self.joystickRightBackgroundImageView.frame.size.height * 0.5f) - throttleValue * self.rightJoyStickOperableRadius);
        }
		[self updateVelocity:self.rightCenter isRight:YES];
	} else if (sender == self.joystickLeftButton) {
		self.buttonLeftPressed = NO;
		self.joystickLeftCurrentPosition = self.joystickLeftInitialPosition;
		self.joystickLeftBackgroundImageView.alpha = self.joystickLeftThumbImageView.alpha = self.joystickAlpha;
		[self refreshJoystickLeft];
        
        if (self.isLeftHanded) {
            [self.rudderChannel setValue:0.0f];
            float throttleValue = [self.throttleChannel value];
            self.leftCenter = CGPointMake(self.joystickLeftBackgroundImageView.frame.origin.x + (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.joystickLeftBackgroundImageView.frame.origin.y + (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f) - throttleValue * self.rightJoyStickOperableRadius);
        } else {
            [self.aileronChannel setValue:0.0];
            [self.elevatorChannel setValue:0.0];
            self.leftCenter = CGPointMake(self.joystickLeftBackgroundImageView.frame.origin.x + (self.joystickLeftBackgroundImageView.frame.size.width * 0.5f), self.joystickLeftBackgroundImageView.frame.origin.y + (self.joystickLeftBackgroundImageView.frame.size.height * 0.5f));
            self.accModeReady = NO;
            if (self.accModeEnabled) {
                [self setAcceleroRotationWithPhi:0.0f withTheta:0.0f withPsi:0.0f];
            }
        }
		[self updateVelocity:self.leftCenter isRight:NO];
	}
}

- (IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event {
    BOOL _runOnce = YES;
    static float rightBackgoundWidth = 0.0f;
    static float rightBackgoundHeight = 0.0f;
    static float leftBackgoundWidth = 0.0f;
    static float leftBackgoundHeight = 0.0f;
    if (_runOnce) {
        rightBackgoundWidth = self.joystickRightBackgroundImageView.frame.size.width;
        rightBackgoundHeight = self.joystickRightBackgroundImageView.frame.size.height;
        leftBackgoundWidth = self.joystickLeftBackgroundImageView.frame.size.width;
        leftBackgoundHeight = self.joystickLeftBackgroundImageView.frame.size.height;
        _runOnce = NO;
    }
    
	UITouch *touch = [[event touchesForView:sender] anyObject];
	CGPoint point = [touch locationInView:self.view];
    float aileronElevatorValidBandRatio = 0.5f - self.settings.aileronDeadBand * 0.5f;
    float rudderValidBandRatio = 0.5f - self.settings.rudderDeadBand * 0.5f;
	
	if (sender == self.joystickRightButton && self.buttonRightPressed) {
        float rightJoystickXInput;
        float rightJoystickYInput;
        float rightJoystickXValidBand;
        float rightJoystickYValidBand;
        
        if (self.isLeftHanded) {
            rightJoystickXValidBand = aileronElevatorValidBandRatio;
            rightJoystickYValidBand = aileronElevatorValidBandRatio;
        } else {
            rightJoystickXValidBand = rudderValidBandRatio;
            rightJoystickYValidBand = 0.5f;
        }
        
        if (!self.isLeftHanded && self.rudderIsLocked) {
            rightJoystickXInput = 0.0f;
        } else if ((self.rightCenter.x - point.x) > ((rightBackgoundWidth * 0.5f) - (rightJoystickXValidBand * rightBackgoundWidth))) {
            float percent = ((self.rightCenter.x - point.x) - ((rightBackgoundWidth * 0.5f) - (rightJoystickXValidBand * rightBackgoundWidth))) / ((rightJoystickXValidBand * rightBackgoundWidth));
            if (percent > 1.0f) {
                percent = 1.0f;
            }
            rightJoystickXInput = -percent;
        } else if ((point.x - self.rightCenter.x) > ((rightBackgoundWidth * 0.5f) - (rightJoystickXValidBand * rightBackgoundWidth))) {
            float percent = ((point.x - self.rightCenter.x) - ((rightBackgoundWidth * 0.5f) - (rightJoystickXValidBand * rightBackgoundWidth))) / ((rightJoystickXValidBand * rightBackgoundWidth));
            if (percent > 1.0f) {
                percent = 1.0f;
            }
            rightJoystickXInput = percent;
        } else {
            rightJoystickXInput = 0.0f;
        }
        
        if (self.isLeftHanded) {
            if (self.accModeEnabled == NO) {
                if (self.settings.isBeginnerMode) {
                    [self.aileronChannel setValue:rightJoystickXInput * kBeginnerAileronChannelRatio];
                } else {
                    [self.aileronChannel setValue:rightJoystickXInput];
                }
            }
        } else {
            if (self.settings.isBeginnerMode) {
                [self.rudderChannel setValue:rightJoystickXInput * kBeginnerRudderChannelRatio];
            } else {
                [self.rudderChannel setValue:rightJoystickXInput];
            }
        }
        
        if (self.throttleIsLocked && !self.isLeftHanded) {
            rightJoystickYInput = self.throttleChannel.value;
        } else if ((point.y - self.rightCenter.y) > ((rightBackgoundHeight * 0.5f) - (rightJoystickYValidBand * rightBackgoundHeight))) {
            float percent = ((point.y - self.rightCenter.y) - ((rightBackgoundHeight * 0.5f) - (rightJoystickYValidBand * rightBackgoundHeight))) / ((rightJoystickYValidBand * rightBackgoundHeight));
            if (percent > 1.0f) {
                percent = 1.0f;
            }
            rightJoystickYInput = -percent;
        } else if ((self.rightCenter.y - point.y) > ((rightBackgoundHeight * 0.5f) - (rightJoystickYValidBand * rightBackgoundHeight))) {
            float percent = ((self.rightCenter.y - point.y) - ((rightBackgoundHeight * 0.5f) - (rightJoystickYValidBand * rightBackgoundHeight))) / ((rightJoystickYValidBand * rightBackgoundHeight));
            if (percent > 1.0f) {
                percent = 1.0f;
            }
            rightJoystickYInput = percent;
        } else {
            rightJoystickYInput = 0.0f;
        }
        
        if (self.isLeftHanded) {
            if (self.accModeEnabled == NO) {
                if (self.settings.isBeginnerMode) {
                    [self.elevatorChannel setValue:rightJoystickYInput * kBeginnerElevatorChannelRatio];
                } else {
                    [self.elevatorChannel setValue:rightJoystickYInput];
                }
            }
        } else {
            if (self.settings.isBeginnerMode) {
                [self.throttleChannel setValue:(kBeginnerThrottleChannelRatio - 1) + rightJoystickYInput * kBeginnerThrottleChannelRatio];
            } else {
                [self.throttleChannel setValue:rightJoystickYInput];
            }
            [self updateThrottleValueLabel];
        }
	} else if (sender == self.joystickLeftButton && self.buttonLeftPressed) {
        float leftJoystickXInput;
        float leftJoystickYInput;
        float leftJoystickXValidBand;
        float leftJoystickYValidBand;
        
        if (self.isLeftHanded) {
            leftJoystickXValidBand = rudderValidBandRatio;
            leftJoystickYValidBand = 0.5f;
        } else {
            leftJoystickXValidBand = aileronElevatorValidBandRatio;
            leftJoystickYValidBand = aileronElevatorValidBandRatio;
        }
        
        if (self.isLeftHanded && self.rudderIsLocked) {
            leftJoystickXInput = 0.0f;
        } else if ((self.leftCenter.x - point.x) > ((leftBackgoundWidth * 0.5f) - (leftJoystickXValidBand * leftBackgoundWidth))) {
			float percent = ((self.leftCenter.x - point.x) - ((leftBackgoundWidth * 0.5f) - (leftJoystickXValidBand * leftBackgoundWidth))) / ((leftJoystickXValidBand * leftBackgoundWidth));
			if (percent > 1.0f) {
				percent = 1.0f;
            }
            leftJoystickXInput = -percent;
		} else if ((point.x - self.leftCenter.x) > ((leftBackgoundWidth * 0.5f) - (leftJoystickXValidBand * leftBackgoundWidth))) {
			float percent = ((point.x - self.leftCenter.x) - ((leftBackgoundWidth * 0.5f) - (leftJoystickXValidBand * leftBackgoundWidth))) / ((leftJoystickXValidBand * leftBackgoundWidth));
			if (percent > 1.0f) {
				percent = 1.0f;
            }
            leftJoystickXInput = percent;
		} else {
            leftJoystickXInput = 0.0f;
		}
        
        if (self.isLeftHanded) {
            if (self.settings.isBeginnerMode) {
                [self.rudderChannel setValue:leftJoystickXInput * kBeginnerRudderChannelRatio];
            } else {
                [self.rudderChannel setValue:leftJoystickXInput];
            }
        } else {
            if (self.accModeEnabled == NO) {
                if (self.settings.isBeginnerMode) {
                    [self.aileronChannel setValue:leftJoystickXInput * kBeginnerAileronChannelRatio];
                } else {
                    [self.aileronChannel setValue:leftJoystickXInput];
                }
            }
        }
        
        if (self.throttleIsLocked && self.isLeftHanded) {
            leftJoystickYInput = self.throttleChannel.value;
        } else if ((point.y - self.leftCenter.y) > ((leftBackgoundHeight * 0.5f) - (leftJoystickYValidBand * leftBackgoundHeight))) {
			float percent = ((point.y - self.leftCenter.y) - ((leftBackgoundHeight * 0.5f) - (leftJoystickYValidBand * leftBackgoundHeight))) / ((leftJoystickYValidBand * leftBackgoundHeight));
			if (percent > 1.0f) {
				percent = 1.0f;
            }
            
            leftJoystickYInput = -percent;
		} else if ((self.leftCenter.y - point.y) > ((leftBackgoundHeight * 0.5f) - (leftJoystickYValidBand * leftBackgoundHeight))) {
			float percent = ((self.leftCenter.y - point.y) - ((leftBackgoundHeight * 0.5f) - (leftJoystickYValidBand * leftBackgoundHeight))) / ((leftJoystickYValidBand * leftBackgoundHeight));
			if (percent > 1.0f) {
				percent = 1.0f;
            }
            leftJoystickYInput = percent;
		} else {
            leftJoystickYInput = 0.0f;
		}
        
        if (self.isLeftHanded) {
            if (self.settings.isBeginnerMode) {
                [self.throttleChannel setValue:(kBeginnerThrottleChannelRatio - 1.0f) + leftJoystickYInput * kBeginnerThrottleChannelRatio];
            } else {
                [self.throttleChannel setValue:leftJoystickYInput];
            }
            
            [self updateThrottleValueLabel];
        } else {
            if (self.accModeEnabled == NO) {
                if (self.settings.isBeginnerMode) {
                    [self.elevatorChannel setValue:leftJoystickYInput * kBeginnerElevatorChannelRatio];
                } else {
                    [self.elevatorChannel setValue:leftJoystickYInput];
                }
            }
        }
	}
    
    BOOL isRight = (sender == self.joystickRightButton);
    if (self.isLeftHanded) {
        if (isRight && self.buttonRightPressed && self.accModeEnabled) {
        } else {
            [self updateVelocity:point isRight:isRight];
        }
    } else {
        if ((isRight == NO) && self.buttonLeftPressed && self.accModeEnabled) {
        } else {
            [self updateVelocity:point isRight:isRight];
        }
    }
}

- (void)showHelpView {
    _helpVC = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    } else {
        if (isIphone5()) {
            _helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController_iPhone_tall" bundle:nil];
        } else {
            _helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController_iPhone" bundle:nil];
        }
    }
    [self.view addSubview:_helpVC.view];
}

- (void)showSettingsMenuView {
    _settingMenuVC = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _settingMenuVC = [[SettingsMenuViewController alloc] initWithNibName:@"SettingsMenuViewController" bundle:nil settings:_settings];
    } else {
        if (isIphone5()) {
            _settingMenuVC = [[SettingsMenuViewController alloc] initWithNibName:@"SettingsMenuViewController_iPhone_tall" bundle:nil settings:_settings];
        } else {
            _settingMenuVC = [[SettingsMenuViewController alloc] initWithNibName:@"SettingsMenuViewController_iPhone" bundle:nil settings:_settings];
        }
    }
    _settingMenuVC.delegate = self;
    [self.view addSubview:_settingMenuVC.view];
}

- (IBAction)takoffButtonDidTouchDown:(id)sender {
    [self blockJoystickHudForTakingOff];
    
    _aileronChannel.value = 0.0f;
    _elevatorChannel.value = 0.0f;
    _rudderChannel.value = 0.0f;
    
    float takeOffValue = clip(-1.0f + _settings.takeOffThrottle * 2.0f + _throttleChannel.trimValue, -1.0f, 1.0f);
    if (_throttleChannel.isReversing) {
        takeOffValue = -takeOffValue;
    }
    _throttleChannel.value = takeOffValue;
    
    [self updateThrottleValueLabel];
    [self updateJoystickCenter];
}

- (IBAction)takeoffButtonDidTouchUp:(id)sender {
    [self unblockJoystickHudForTakingOff:NO];
}

- (IBAction)throttleStopButtonDidTouchDown:(id)sender {
    [self blockJoystickHudForStopping];
    
    _aileronChannel.value = 0.0f;
    _elevatorChannel.value = 0.0f;
    _rudderChannel.value = 0.0f;
    _throttleChannel.value = -1.0f;
    
    [self updateThrottleValueLabel];
    [self updateJoystickCenter];
}

- (IBAction)throttleStopButtonDidTouchUp:(id)sender {
    [self unblockJoystickHudForStopping:NO];
}

- (void)setView:(UIView *)view hidden:(BOOL)hidden{
}

- (IBAction)buttonDidTouchDown:(id)sender {
    if (sender == self.throttleUpButton) {
        self.upIndicatorImageView.hidden = NO;
    } else if (sender == self.throttleDownButton) {
        self.downIndicatorImageView.hidden = NO;
    }
}

- (IBAction)buttonDidDragEnter:(id)sender {
    if (sender == self.throttleUpButton || sender == self.throttleDownButton) {
        [self buttonDidTouchDown:sender];
    }
}

- (IBAction)buttonDidDragExit:(id)sender {
    if (sender == self.throttleUpButton || sender == self.throttleDownButton) {
        [self buttonDidTouchUpOutside:sender];
    }
}

- (IBAction)buttonDidTouchUpInside:(id)sender {
    if (sender == self.setttingButton) {
        [self showSettingsMenuView];
    } else if (sender == self.rudderLockButton) {
        self.rudderIsLocked = !self.rudderIsLocked;
        if (self.rudderIsLocked) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [self.rudderLockButton setImage:[UIImage imageNamed:@"Switch_On_IPAD.png"] forState:UIControlStateNormal];
            } else {
                [self.rudderLockButton setImage:[UIImage imageNamed:@"Switch_On_RETINA.png"] forState:UIControlStateNormal];
            }
        } else {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [self.rudderLockButton setImage:[UIImage imageNamed:@"Switch_Off_IPAD.png"] forState:UIControlStateNormal];
            } else {
                [self.rudderLockButton setImage:[UIImage imageNamed:@"Switch_Off_RETINA.png"] forState:UIControlStateNormal];
            }
        }
        [self updateStatusInfoLabel];
    } else if (sender == self.throttleUpButton) {
        if (self.throttleChannel.value + kThrottleFineTuningStep > 1.0f) {
            self.throttleChannel.value = 1.0f;
        } else {
            self.throttleChannel.value += kThrottleFineTuningStep;
        }
        [self updateJoystickCenter];
        if (self.isLeftHanded) {
            self.joystickLeftThumbImageView.center = CGPointMake(self.joystickLeftThumbImageView.center.x, self.leftCenter.y - self.throttleChannel.value * self.leftJoyStickOperableRadius);
        } else {
            self.joystickRightThumbImageView.center = CGPointMake(self.joystickRightThumbImageView.center.x, self.rightCenter.y - self.throttleChannel.value * self.rightJoyStickOperableRadius);
        }
        self.upIndicatorImageView.hidden = YES;
        [self updateThrottleValueLabel];
    } else if (sender == self.throttleDownButton) {
        if (self.throttleChannel.value - kThrottleFineTuningStep < -1.0f) {
            self.throttleChannel.value = -1.0f;
        } else {
            self.throttleChannel.value -= kThrottleFineTuningStep;
        }
        [self updateJoystickCenter];
        self.downIndicatorImageView.hidden = YES;
        [self updateThrottleValueLabel];
    } else if (sender == self.helpButton) {
        [self showHelpView];
    }
}

- (IBAction)buttonDidTouchUpOutside:(id)sender {
    if (sender == self.throttleUpButton) {
        self.upIndicatorImageView.hidden = YES;
    } else if (sender == self.throttleDownButton) {
        self.downIndicatorImageView.hidden = YES;
    }
}

- (IBAction)buttonDidTouchCancel:(id)sender {
    if (sender == self.throttleUpButton || sender == self.throttleDownButton) {
        [self buttonDidTouchUpOutside:sender];
    }
}

- (IBAction)unlockButtonDidTouchUp:(id)sender {
    self.aileronChannel.value = 0.0f;
    self.elevatorChannel.value = 0.0f;
    self.rudderChannel.value = 0.0f;
    self.throttleChannel.value = -1.0f;
    
    [self updateThrottleValueLabel];
    [self updateJoystickCenter];
    
    [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_ARM];
}

- (IBAction)lockButtonDidTouchUp:(id)sender {
    [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_DISARM];
}

- (void) setAcceleroRotationWithPhi:(float)phi withTheta:(float)theta withPsi:(float)psi {
	accelero_rotation[0][0] = cosf(psi)*cosf(theta);
	accelero_rotation[0][1] = -sinf(psi)*cosf(phi) + cosf(psi)*sinf(theta)*sinf(phi);
	accelero_rotation[0][2] = sinf(psi)*sinf(phi) + cosf(psi)*sinf(theta)*cosf(phi);
	accelero_rotation[1][0] = sinf(psi)*cosf(theta);
	accelero_rotation[1][1] = cosf(psi)*cosf(phi) + sinf(psi)*sinf(theta)*sinf(phi);
	accelero_rotation[1][2] = -cosf(psi)*sinf(phi) + sinf(psi)*sinf(theta)*cosf(phi);
	accelero_rotation[2][0] = -sinf(theta);
	accelero_rotation[2][1] = cosf(theta)*sinf(phi);
	accelero_rotation[2][2] = cosf(theta)*cosf(phi);
    
#ifdef WRITE_DEBUG_ACCELERO
	NSLog(@"Accelero rotation matrix changed :");
	NSLog(@"%0.1f %0.1f %0.1f", accelero_rotation[0][0], accelero_rotation[0][1], accelero_rotation[0][2]);
	NSLog(@"%0.1f %0.1f %0.1f", accelero_rotation[1][0], accelero_rotation[1][1], accelero_rotation[1][2]);
	NSLog(@"%0.1f %0.1f %0.1f", accelero_rotation[2][0], accelero_rotation[2][1], accelero_rotation[2][2]);
#endif
}

- (void)motionDataHandler {
    static uint64_t previous_time = 0;
    if (previous_time == 0) {
        previous_time = mach_absolute_time();
    }
    
    uint64_t current_time = mach_absolute_time();
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t elapsedNano;
    float dt = 0;
    
    static float highPassFilterX = 0.0f, highPassFilterY = 0.0f, highPassFilterZ = 0.0f;
    CMAcceleration current_acceleration = { 0.0f, 0.0f, 0.0f };
    static CMAcceleration last_acceleration = { 0.0f, 0.0f, 0.0f };
    
    static bool first_time_accelero = TRUE;
    static bool first_time_gyro = TRUE;
    
    static float angle_gyro_x, angle_gyro_y, angle_gyro_z;
    float current_angular_rate_x, current_angular_rate_y, current_angular_rate_z;
    
    static float hpf_gyro_x, hpf_gyro_y, hpf_gyro_z;
    static float last_angle_gyro_x, last_angle_gyro_y, last_angle_gyro_z;
    
    float phi = 0.0f, theta = 0.0f;
    
    if (sTimebaseInfo.denom == 0) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    elapsedNano = (current_time-previous_time)*(sTimebaseInfo.numer / sTimebaseInfo.denom);
    previous_time = current_time;
    dt = elapsedNano/1000000000.0f;
    
    CMMotionManager *motionManager = [[BasicInfoManager sharedManager] motionManager];
    if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
        current_acceleration.x = motionManager.accelerometerData.acceleration.x;
        current_acceleration.y = motionManager.accelerometerData.acceleration.y;
        current_acceleration.z = motionManager.accelerometerData.acceleration.z;
    } else if (motionManager.deviceMotionAvailable == 1) {
        current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
        current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
        current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
    }
    
    if (isnan(current_acceleration.x) || isnan(current_acceleration.y) || isnan(current_acceleration.z) || fabs(current_acceleration.x) > 10 || fabs(current_acceleration.y) > 10 || fabs(current_acceleration.z) > 10) {
        static uint32_t count = 0;
        NSLog (@"Accelero errors : %f, %f, %f (count = %d)", current_acceleration.x, current_acceleration.y, current_acceleration.z, count);
        NSLog (@"Accelero raw : %f/%f, %f/%f, %f/%f", motionManager.deviceMotion.gravity.x, motionManager.deviceMotion.userAcceleration.x, motionManager.deviceMotion.gravity.y, motionManager.deviceMotion.userAcceleration.y, motionManager.deviceMotion.gravity.z, motionManager.deviceMotion.userAcceleration.z);
        NSLog (@"Attitude : %f / %f / %f", motionManager.deviceMotion.attitude.roll, motionManager.deviceMotion.attitude.pitch, motionManager.deviceMotion.attitude.yaw);
        return;
    }
    
    if (first_time_accelero) {
        first_time_accelero = FALSE;
        last_acceleration.x = current_acceleration.x;
        last_acceleration.y = current_acceleration.y;
        last_acceleration.z = current_acceleration.z;
    }
    
    float highPassFilterConstant = (1.0f / 5.0f) / ((1.0f / 40.0f) + (1.0f / 5.0f));
    highPassFilterX = highPassFilterConstant * (highPassFilterX + current_acceleration.x - last_acceleration.x);
    highPassFilterY = highPassFilterConstant * (highPassFilterY + current_acceleration.y - last_acceleration.y);
    highPassFilterZ = highPassFilterConstant * (highPassFilterZ + current_acceleration.z - last_acceleration.z);
    
    last_acceleration.x = current_acceleration.x;
    last_acceleration.y = current_acceleration.y;
    last_acceleration.z = current_acceleration.z;
    
#define ACCELERO_THRESHOLD          0.2f
#define ACCELERO_FASTMOVE_THRESHOLD	1.3f
    
    if (fabs(highPassFilterX) > ACCELERO_FASTMOVE_THRESHOLD || fabs(highPassFilterY) > ACCELERO_FASTMOVE_THRESHOLD || fabs(highPassFilterZ) > ACCELERO_FASTMOVE_THRESHOLD) {
    } else {
        if (self.accModeEnabled) {
            if (!self.accModeReady) {
                [self.aileronChannel setValue:0];
                [self.elevatorChannel setValue:0];
            } else {
                CMAcceleration current_acceleration_rotate;
                float angle_acc_x;
                float angle_acc_y;
                
                current_acceleration.x = 0.9f * last_acceleration.x + 0.1f * current_acceleration.x;
                current_acceleration.y = 0.9f * last_acceleration.y + 0.1f * current_acceleration.y;
                current_acceleration.z = 0.9f * last_acceleration.z + 0.1f * current_acceleration.z;
                
                last_acceleration.x = current_acceleration.x;
                last_acceleration.y = current_acceleration.y;
                last_acceleration.z = current_acceleration.z;
                
                current_acceleration_rotate.x =
                (accelero_rotation[0][0] * current_acceleration.x)
                + (accelero_rotation[0][1] * current_acceleration.y)
                + (accelero_rotation[0][2] * current_acceleration.z);
                current_acceleration_rotate.y =
                (accelero_rotation[1][0] * current_acceleration.x)
                + (accelero_rotation[1][1] * current_acceleration.y)
                + (accelero_rotation[1][2] * current_acceleration.z);
                current_acceleration_rotate.z =
                (accelero_rotation[2][0] * current_acceleration.x)
                + (accelero_rotation[2][1] * current_acceleration.y)
                + (accelero_rotation[2][2] * current_acceleration.z);
                
                if (current_acceleration_rotate.y > -ACCELERO_THRESHOLD && current_acceleration_rotate.y < ACCELERO_THRESHOLD) {
                    angle_acc_x = atan2f(current_acceleration_rotate.x, sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                } else {
                    angle_acc_x = atan2f(current_acceleration_rotate.x, sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                if (current_acceleration_rotate.x > -ACCELERO_THRESHOLD && current_acceleration_rotate.x < ACCELERO_THRESHOLD) {
                    angle_acc_y = atan2f(current_acceleration_rotate.y, sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                } else {
                    angle_acc_y = atan2f(current_acceleration_rotate.y, sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                if (motionManager.deviceMotionAvailable == 1) {
                    current_angular_rate_x = motionManager.deviceMotion.rotationRate.x;
                    current_angular_rate_y = motionManager.deviceMotion.rotationRate.y;
                    current_angular_rate_z = motionManager.deviceMotion.rotationRate.z;
                    
                    angle_gyro_x += -current_angular_rate_x * dt;
                    angle_gyro_y += current_angular_rate_y * dt;
                    angle_gyro_z += current_angular_rate_z * dt;
                    
                    if (first_time_gyro) {
                        first_time_gyro = FALSE;
                        
                        angle_gyro_x = 0.0f;
                        angle_gyro_y = 0.0f;
                        angle_gyro_z = 0.0f;
                        
                        hpf_gyro_x = angle_gyro_x;
                        hpf_gyro_y = angle_gyro_y;
                        hpf_gyro_z = angle_gyro_z;
                        
                        last_angle_gyro_x = 0.0f;
                        last_angle_gyro_y = 0.0f;
                        last_angle_gyro_z = 0.0f;
                    }
                    
                    hpf_gyro_x = 0.9f * hpf_gyro_x + 0.9f * (angle_gyro_x - last_angle_gyro_x);
                    hpf_gyro_y = 0.9f * hpf_gyro_y + 0.9f * (angle_gyro_y - last_angle_gyro_y);
                    hpf_gyro_z = 0.9f * hpf_gyro_z + 0.9f * (angle_gyro_z - last_angle_gyro_z);
                    
                    last_angle_gyro_x = angle_gyro_x;
                    last_angle_gyro_y = angle_gyro_y;
                    last_angle_gyro_z = angle_gyro_z;
                }
                
                float fusion_x = hpf_gyro_y + angle_acc_x;
                float fusion_y = hpf_gyro_x + angle_acc_y;
                
                if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
                    if (1) {
                        theta = -angle_acc_x;
                        phi = -angle_acc_y;
                    } else {
                        theta = angle_acc_x;
                        phi = angle_acc_y;
                    }
                } else if (motionManager.deviceMotionAvailable == 1) {
                    theta = -fusion_x;
                    phi = fusion_y;
                }
                
                theta = theta / M_PI_2;
                phi   = phi / M_PI_2;
                if (theta > 1.0f) {
                    theta = 1.0f;
                }
                if (theta < -1.0f) {
                    theta = -1.0f;
                }
                if (phi > 1.0f) {
                    phi = 1.0f;
                }
                if (phi < -1.0f) {
                    phi = -1.0f;
                }
                
                if (_settings.isBeginnerMode) {
                    [_aileronChannel setValue:phi * kBeginnerAileronChannelRatio];
                    [_elevatorChannel setValue:theta * kBeginnerElevatorChannelRatio];
                } else {
                    [_aileronChannel setValue:phi];
                    [_elevatorChannel setValue:theta];
                }
            }
        } else {
            if (self.accModeReady) {
            }
        }
    }
}

- (void)updateJoysticksForAccModeChanged {
    if (self.accModeEnabled) {
        if (self.isLeftHanded) {
            self.joystickLeftBackgroundImageView.hidden = NO;
            self.joystickRightBackgroundImageView.hidden = YES;
        } else {
            self.joystickLeftBackgroundImageView.hidden = YES;
            self.joystickRightBackgroundImageView.hidden = NO;
        }
    } else {
        self.joystickLeftBackgroundImageView.hidden = NO;
        self.joystickRightBackgroundImageView.hidden = NO;
    }
}

@end