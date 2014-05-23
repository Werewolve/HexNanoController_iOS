//
//  ChannelSettingsViewController.h
//  FlyingSwallow
//
//  Created by koupoo on 12-12-24.
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
#import "Channel.h"
#import "FSSlider.h"

#define kNotificationDismissChannelSettingsView @"NotificationDissmissChannelSettingsView"

@interface ChannelSettingsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *channelSettingsTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *isReversedTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *trimValueTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *outputAdjustableRangeTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *outputPpmRangeTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *defaultOuputValueTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *isReversedSwitchButton;
@property (nonatomic, weak) IBOutlet FSSlider *trimValueSlider;
@property (nonatomic, weak) IBOutlet UILabel *trimValueLabel;
@property (nonatomic, weak) IBOutlet FSSlider *outputAdjustableRangeSlider;
@property (nonatomic, weak) IBOutlet UILabel *outputAdjustableRangeLabel;
@property (nonatomic, weak) IBOutlet UILabel *outputPpmRangeLabel;
@property (nonatomic, weak) IBOutlet UITextField *defaultOutputValueTextField;
@property (nonatomic, weak) IBOutlet FSSlider *defaultOutputValueSlider;
@property (nonatomic, weak) IBOutlet UILabel *defaultOutputValueLabel;
@property (nonatomic, weak) IBOutlet UIView *defaultOutputValueView;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *defaultButton;

@property(nonatomic, strong) Channel *channel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil channel:(Channel *)channel;
- (IBAction)buttonClick:(id)sender;
- (IBAction)switchButtonClick:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)sliderRelease:(id)sender;

@end
