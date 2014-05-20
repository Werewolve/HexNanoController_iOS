//
//  SettingsMenuViewController.h
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
#import "FSSlider.h"
#import "Settings.h"
#import "ChannelSettingsViewController.h"

#define kNotificationDismissSettingsMenuView @"NotificationDissmissSettingsView"

@class SettingsMenuViewController;

@protocol SettingMenuViewControllerDelegate <NSObject>
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl interfaceOpacityValueDidChange:(float)newValue;
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl leftHandedValueDidChange:(BOOL)enabled;
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl accModeValueDidChange:(BOOL)enabled;
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl beginnerModeValueDidChange:(BOOL)enabled;
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl headfreeModeValueDidChange:(BOOL)enabled;
- (void)settingsMenuViewController:(SettingsMenuViewController *)ctrl ppmPolarityReversed:(BOOL)enabled;
@end

enum SwitchButtonStatus{
    SWITCH_BUTTON_UNCHECKED = 0,
    SWITCH_BUTTON_CHECKED,
};

enum ChannelListTableViewSection {
    ChannelListTableViewSectionChannels = 0,
};

@interface SettingsMenuViewController : UIViewController <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *pageTitleLabel;
    
@property (nonatomic, weak) IBOutlet UIView *peripheralView;
@property (nonatomic, weak) IBOutlet UIView *personalSettingsPageView;
@property (nonatomic, weak) IBOutlet UIView *channelSetttingsPageView;
@property (nonatomic, weak) IBOutlet UIView *modeSettingsPageView;
@property (nonatomic, weak) IBOutlet UIView *aboutPageView;
@property (nonatomic, weak) IBOutlet UIView *trimSettingsView;
    
    
@property (nonatomic, weak) IBOutlet UIScrollView *settingsPageScrollView;
    
@property (nonatomic, weak) IBOutlet UIButton *previousPageButton;
@property (nonatomic, weak) IBOutlet UIButton *nextPageButton;
    
@property (nonatomic, weak) IBOutlet UIButton *okButton;
    
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
    
@property (nonatomic, weak) IBOutlet UILabel *leftHandedTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *leftHandedSwitchButton;
    
@property (nonatomic, weak) IBOutlet UILabel *accModeTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *accModeSwitchButton;
    
@property (nonatomic, weak) IBOutlet UILabel *interfaceOpacityTitleLabel;
@property (nonatomic, weak) IBOutlet FSSlider *interfaceOpacitySlider;
@property (nonatomic, weak) IBOutlet UILabel *interfaceOpacityLabel;
    
@property (nonatomic, weak) IBOutlet UITableView *channelListTableView;
    
@property (nonatomic, weak) IBOutlet UILabel *ppmPolarityReversedTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *ppmPolarityReversedSwitchButton;
    
@property (nonatomic, weak) IBOutlet UIButton *defaultSettingsButton;
    
@property (nonatomic, weak) IBOutlet UILabel *takeOffThrottleTitleLabel;
@property (nonatomic, weak) IBOutlet FSSlider *takeOffThrottleSlider;
@property (nonatomic, weak) IBOutlet UILabel *takeOffThrottleLabel;
    
@property (nonatomic, weak) IBOutlet UILabel *aileronElevatorDeadBandTitleLabel;
@property (nonatomic, weak) IBOutlet FSSlider *aileronElevatorDeadBandSlider;
@property (nonatomic, weak) IBOutlet UILabel *aileronElevatorDeadBandLabel;
    
@property (nonatomic, weak) IBOutlet UILabel *rudderDeadBandTitleLabel;
@property (nonatomic, weak) IBOutlet FSSlider *rudderDeadBandSlider;
@property (nonatomic, weak) IBOutlet UILabel *rudderDeadBandLabel;
@property (nonatomic, weak) IBOutlet UIWebView *aboutWebView;

@property (nonatomic, weak) IBOutlet UITableView *peripheralListTableView;
@property (nonatomic, weak) IBOutlet UIButton *peripheralListScanButton;
    
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *connectionActivityIndicatorView;
@property (nonatomic, weak) IBOutlet UILabel *connectionStateTextLabel;
    
@property (nonatomic, weak) IBOutlet UILabel *isScanningTextLabel;

@property (nonatomic, weak) IBOutlet UIButton *accCalibrateButton;
@property (nonatomic, weak) IBOutlet UIButton *magCalibrateButton;
    
    
@property (nonatomic, weak) IBOutlet UIButton *upTrimButton;
@property (nonatomic, weak) IBOutlet UIButton *downTrimButton;
@property (nonatomic, weak) IBOutlet UIButton *rightTrimButton;
@property (nonatomic, weak) IBOutlet UIButton *leftTrimButton;
    
@property (nonatomic, weak) IBOutlet UILabel *beginnerModeTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *beginnerModeSwitchButton;
    
@property (nonatomic, weak) IBOutlet UILabel *headfreeModeTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *headfreeModeSwitchButton;

@property (nonatomic, weak) NSObject<SettingMenuViewControllerDelegate> *delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil settings:(Settings *)settings;
- (IBAction)buttonClick:(id)sender;
- (IBAction)switchButtonClick:(id)sender;
- (IBAction)sliderRelease:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
@end



