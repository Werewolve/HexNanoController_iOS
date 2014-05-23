//
//  ChannelSettingsViewController.m
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

#import "ChannelSettingsViewController.h"
#import "Macros.h"
#import "Settings.h"
#import "util.h"

@interface ChannelSettingsViewController ()

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end

@implementation ChannelSettingsViewController

- (void)updateIsReversedSwitchButton{
    [self setSwitchButton:self.isReversedSwitchButton withValue:self.channel.isReversing];
}

- (void)updateTrimValueSlider{
    self.trimValueSlider.value = self.channel.trimValue;
}

- (void)updateTrimValueLabel{
    self.trimValueLabel.text = [NSString stringWithFormat:@"%.2f", self.channel.trimValue];
}

- (void)updateOutputAdjustableRangeSlider{
    self.outputAdjustableRangeSlider.value = self.channel.outputAdjustabledRange;
}

- (void)updateOutputAdjustableRangeLabel{
    self.outputAdjustableRangeLabel.text = [NSString stringWithFormat:@"%.2f", self.channel.outputAdjustabledRange];
}

- (void)updateoOtputPpmRangeLabel{
    int minOutputPpm = (int)(1500 + 500 * clip(-1 + self.channel.trimValue, -1, 1) * self.channel.outputAdjustabledRange);
    int maxOutputPpm = (int)(1500 + 500 * clip(1 + self.channel.trimValue, -1, 1) * self.channel.outputAdjustabledRange);
    
    self.outputPpmRangeLabel.text = [NSString stringWithFormat:@"%d~%dus", minOutputPpm, maxOutputPpm];
}

- (void)updateDefaultOutputValueLabel{
    float outputValue = clip(self.channel.defaultOutputValue+ self.channel.trimValue, -1.0, 1.0); 
    if (self.channel.isReversing) {
        outputValue = -outputValue;
    }
    
    float defaultPpmValue = 1500 + 500 * (outputValue * self.channel.outputAdjustabledRange);
    
    self.defaultOutputValueLabel.text = [NSString stringWithFormat:@"%.2f, %dus", self.channel.defaultOutputValue, (int)defaultPpmValue];
}

- (void)updateDefaultOutputValueSlider{
    self.defaultOutputValueSlider.value = self.channel.defaultOutputValue;
}

- (void)updateAllValueUI{
    [self updateIsReversedSwitchButton];
    [self updateTrimValueSlider];
    [self updateTrimValueLabel];
    [self updateOutputAdjustableRangeSlider];
    [self updateOutputAdjustableRangeLabel];
    [self updateoOtputPpmRangeLabel];
    [self updateDefaultOutputValueSlider];
    [self updateDefaultOutputValueLabel];
    
    if([self.channel.name isEqualToString:kChannelNameAileron] 
       || [self.channel.name isEqualToString:kChannelNameElevator]
       || [self.channel.name isEqualToString:kChannelNameRudder]
       || [self.channel.name isEqualToString:kChannelNameThrottle]){
        self.defaultOutputValueView.hidden = YES;
    } else {
        self.defaultOutputValueView.hidden = NO;
    }
}

- (void)udpateChannelSettingsTitleLabel{
    self.channelSettingsTitleLabel.text = self.channel.name;
}

- (void)setChannel:(Channel *)channel{
    self.channel = channel;
    [self updateAllValueUI];
    [self udpateChannelSettingsTitleLabel];
}

- (void)setSwitchButton:(UIButton *)switchButton withValue:(BOOL)active {
    if (active) {
        switchButton.tag = 1;
        [switchButton setImage:[UIImage imageNamed:@"Btn_ON.png"] forState:UIControlStateNormal];
    } else {
        switchButton.tag = 0;
        [switchButton setImage:[UIImage imageNamed:@"Btn_OFF.png"] forState:UIControlStateNormal];
    }
}

- (void)toggleSwitchButton:(UIButton *)switchButton {
    [self setSwitchButton:switchButton withValue:(0 == switchButton.tag) ? YES : NO];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil channel:(Channel *)channel{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.channel = channel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isReversedTitleLabel.text            = NSLocalizedString(@"IS REVERSING",nil);
    self.trimValueTitleLabel.text             = NSLocalizedString(@"TRIM VALUE",nil);
    self.outputAdjustableRangeTitleLabel.text = NSLocalizedString(@"OUTPUT ADJUSTABLE RANGE",nil);
    self.outputPpmRangeTitleLabel.text        = NSLocalizedString(@"OUTPUT PPM RANGE",nil);
    self.defaultOuputValueTitleLabel.text     = NSLocalizedString(@"DEFAULT OUTPUT VALUE",nil);
    [self.defaultButton setTitle:NSLocalizedString(@"Default",nil) forState:UIControlStateNormal];
    
    [self updateAllValueUI];
    [self udpateChannelSettingsTitleLabel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)resetToDefault{
    self.channel.isReversing = NO;
    self.channel.trimValue = 0;
    self.channel.outputAdjustabledRange = 1;
    self.channel.defaultOutputValue = 0;
    
    if([self.channel.name isEqualToString:kChannelNameThrottle])
        self.channel.value = 0;
    else
        self.channel.value = 0;
    
    [self.channel.ownerSettings save];
    
    [self updateAllValueUI];
}

- (IBAction)buttonClick:(id)sender {
    if(sender == self.dismissButton){
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDismissChannelSettingsView object:self userInfo:nil];
    } else if(sender == self.defaultButton) {
        [self resetToDefault];
    } else {
        ;
    }
}

- (IBAction)switchButtonClick:(id)sender {
    if(sender == self.isReversedSwitchButton){
        self.channel.isReversing = self.isReversedSwitchButton.tag == 1 ? NO : YES;
        
        [self.channel.ownerSettings save];
        
        [self updateIsReversedSwitchButton];
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    if(sender == self.trimValueSlider) {
        self.channel.trimValue = self.trimValueSlider.value;
        [self updateTrimValueLabel];
        [self updateoOtputPpmRangeLabel];
        [self updateDefaultOutputValueLabel];
        self.channel.value = self.channel.defaultOutputValue;
    } else if(sender == self.outputAdjustableRangeSlider) {
        self.channel.outputAdjustabledRange = self.outputAdjustableRangeSlider.value;
        [self updateOutputAdjustableRangeLabel];
        [self updateoOtputPpmRangeLabel];
        [self updateDefaultOutputValueLabel];
        self.channel.value = self.channel.defaultOutputValue;
    } else if(sender == self.defaultOutputValueSlider){
        if(![self.channel.name isEqualToString:kChannelNameAileron] 
           && ![self.channel.name isEqualToString:kChannelNameElevator]
           && ![self.channel.name isEqualToString:kChannelNameRudder]
           && ![self.channel.name isEqualToString:kChannelNameThrottle]){
            self.channel.defaultOutputValue = self.defaultOutputValueSlider.value;
            self.channel.value = self.channel.defaultOutputValue;
            [self updateDefaultOutputValueLabel];
        }
    } else{

    }
}

- (IBAction)sliderRelease:(id)sender {
    [self.channel.ownerSettings save];
}

@end
