//
//  HudViewController.h
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

#import <UIKit/UIKit.h>
#import "SettingsMenuViewController.h"
#import "Channel.h"
#import "Settings.h"
#import "OSDView.h"

typedef enum{
	ViewBlockViewINVALID = 0,
    ViewBlockJoyStickHud,
    ViewBlockJoyStickHud2,
	ViewBlockViewMAX
}HudViewBlockView;

float accelero_rotation[3][3];

@interface HudViewController : UIViewController<SettingMenuViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *batteryLevelLabel;
    
@property (nonatomic, weak) IBOutlet UIImageView *batteryImageView;

@property (nonatomic, weak) IBOutlet UIButton *setttingButton;
@property (nonatomic, weak) IBOutlet UIButton *joystickLeftButton;
@property (nonatomic, weak) IBOutlet UIButton *joystickRightButton;
    
@property (nonatomic, weak) IBOutlet UIImageView *joystickLeftThumbImageView;
@property (nonatomic, weak) IBOutlet UIImageView *joystickLeftBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *joystickRightThumbImageView;
@property (nonatomic, weak) IBOutlet UIImageView *joystickRightBackgroundImageView;
    
@property (nonatomic, weak) IBOutlet UIView *warningView;
@property (nonatomic, weak) IBOutlet UILabel *warningLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusInfoLabel;
@property (nonatomic, weak) IBOutlet UILabel *throttleValueLabel;
@property (nonatomic, weak) IBOutlet UIButton *rudderLockButton;
    
@property (nonatomic, weak) IBOutlet UIButton *throttleUpButton;
@property (nonatomic, weak) IBOutlet UIButton *throttleDownButton;
@property (nonatomic, weak) IBOutlet UIImageView *downIndicatorImageView;
@property (nonatomic, weak) IBOutlet UIImageView *upIndicatorImageView;
    
@property (nonatomic, weak) IBOutlet OSDView *osdView;
    
    
@property (nonatomic, weak) IBOutlet UILabel *rollValueTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *pitchValueTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *altValueTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *headAngleValueTextLabel;
    
@property (nonatomic, weak) IBOutlet UIButton *altHoldSwitchButton;
    
@property (nonatomic, weak) IBOutlet UIButton *helpButton;
@property (strong, nonatomic) IBOutlet UITextView *debugTextView;

- (IBAction)switchButtonClick:(id)sender;

- (IBAction)joystickButtonDidTouchDown:(id)sender forEvent:(UIEvent *)event;
- (IBAction)josystickButtonDidTouchUp:(id)sender forEvent:(UIEvent *)event;
- (IBAction)joystickButtonDidDrag:(id)sender forEvent:(UIEvent *)event;

- (IBAction)takoffButtonDidTouchDown:(id)sender;
- (IBAction)takeoffButtonDidTouchUp:(id)sender;

- (IBAction)throttleStopButtonDidTouchDown:(id)sender;
- (IBAction)throttleStopButtonDidTouchUp:(id)sender;

- (IBAction)buttonDidTouchDown:(id)sender;
- (IBAction)buttonDidDragEnter:(id)sender;
- (IBAction)buttonDidDragExit:(id)sender;
- (IBAction)buttonDidTouchUpInside:(id)sender;
- (IBAction)buttonDidTouchUpOutside:(id)sender;
- (IBAction)buttonDidTouchCancel:(id)sender;

- (IBAction)unlockButtonDidTouchUp:(id)sender;
- (IBAction)lockButtonDidTouchUp:(id)sender;


@end
