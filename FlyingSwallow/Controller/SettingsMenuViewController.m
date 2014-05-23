//
//  SettingsMenuViewController.m
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

#import "SettingsMenuViewController.h"
#import "Macros.h"
#import "Channel.h"
#import "ChannelSettingsViewController.h"
#import "util.h"
#import "BleSerialManager.h"
#import "Transmitter.h"
#import "OSDCommon.h"

#define kAileronElevatorMaxDeadBandRatio 0.2f
#define kRudderMaxDeadBandRatio 0.2f

#define kChannelListTableView 0
#define kPeripheralDeviceListTabelView 1

typedef enum settings_alert_dialog {
    settings_alert_dialog_connect,
    settings_alert_dialog_disconnect,
    settings_alert_dialog_default,
    settings_alert_dialog_calibrate_mag,
    settings_alert_dialog_calibrate_acc
} settings_alert_dialog;

@interface SettingsMenuViewController ()

@property (nonatomic, strong) NSMutableArray *pageViewArray;
@property (nonatomic, strong) NSMutableArray *pageTitleArray;
@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, strong) Settings *settings;
@property (nonatomic, strong) ChannelSettingsViewController *channelSettingsVC;
@property (nonatomic, strong) NSArray *peripheralList;
@property (nonatomic, strong) CBPeripheral *selectedPeripheral;
@property (nonatomic, assign) BOOL isTryingConnect;
@property (nonatomic, assign) BOOL isTryingDisconnect;

@end

@implementation SettingsMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil settings:(Settings *)settings {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pageViewArray = [[NSMutableArray alloc] initWithCapacity:5];
        self.pageTitleArray = [[NSMutableArray alloc] initWithCapacity:5];
        self.settings = settings;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissChannelSetttingsView) name:kNotificationDismissChannelSettingsView object:nil];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.channelListTableView.tag = kChannelListTableView;
    self.peripheralListTableView.tag = kPeripheralDeviceListTabelView;
}

- (void)updateSettingsUI {
    [self setSwitchButton:self.leftHandedSwitchButton withValue:self.settings.isLeftHanded];
    [self setSwitchButton:self.accModeSwitchButton withValue:self.settings.isAccMode];
    [self setSwitchButton:self.beginnerModeSwitchButton withValue:self.settings.isBeginnerMode];
    [self setSwitchButton:self.headfreeModeSwitchButton withValue:self.settings.isHeadFreeMode];
    
    self.interfaceOpacitySlider.value = self.settings.interfaceOpacity * 100.0f;
    self.interfaceOpacityLabel.text = [NSString stringWithFormat:@"%d%%", (int)(self.settings.interfaceOpacity * 100.0f)];
    [self setSwitchButton:self.ppmPolarityReversedSwitchButton withValue:self.settings.ppmPolarityIsNegative];
    self.takeOffThrottleSlider.value = self.settings.takeOffThrottle;
    [self updateTakeOffThrottleLabel];
    
    [self updateAileronElevatorDeadBandLabel];
    [self updateAileronElevatorDeadBandSlider];
    [self updateRudderDeadBandLabel];
    [self updateRudderDeadBandSlider];
    
    [self.channelListTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftHandedTitleLabel.text = NSLocalizedString(@"LEFT HANDED", nil);
    self.interfaceOpacityTitleLabel.text = NSLocalizedString(@"INTERFACE OPACITY", nil);
    self.accModeTitleLabel.text = NSLocalizedString(@"Acc Mode", nil);
    
    [self.pageViewArray addObject:self.peripheralView];
    [self.pageTitleArray addObject:NSLocalizedString(@"BLE DEVICES", nil)];
    
    [self.pageViewArray addObject:self.personalSettingsPageView];
    [self.pageTitleArray addObject:NSLocalizedString(@"PERSONAL SETTINGS", nil)];
    
    [self.pageViewArray addObject:self.trimSettingsView];
    [self.pageTitleArray addObject:NSLocalizedString(@"TRIM SETTINGS", nil)];
    
    [self.pageViewArray addObject:self.modeSettingsPageView];
    [self.pageTitleArray addObject:NSLocalizedString(@"MODE SETTINGS", nil)];
    
    [self.pageViewArray addObject:self.aboutPageView];
    [self.pageTitleArray addObject:NSLocalizedString(@"ABOUT", nil)];
    
    self.pageCount = self.pageViewArray.count;
    
    CGFloat x = 0.0f;
    for (UIView *pageView in self.pageViewArray) {
        CGRect frame = pageView.frame;
        frame.origin.x = x;
        [pageView setFrame:frame];
        [self.settingsPageScrollView addSubview:pageView];
        x += pageView.frame.size.width;
    }
    [self.settingsPageScrollView  setContentSize:CGSizeMake(x, self.settingsPageScrollView.frame.size.height)];
    
    [self.pageControl setNumberOfPages:self.pageCount];
    [self.pageControl setCurrentPage:0];
    
    self.pageTitleLabel.text = NSLocalizedString(@"BLE DEVICES", nil);
    self.ppmPolarityReversedTitleLabel.text = NSLocalizedString(@"PPM POLARITY REVERSED", nil);
    self.takeOffThrottleTitleLabel.text = NSLocalizedString(@"Take Off Throttle", nil);
    self.aileronElevatorDeadBandTitleLabel.text = NSLocalizedString(@"Aileron/Elevator Dead Band", nil);
    self.rudderDeadBandTitleLabel.text = NSLocalizedString(@"Rudder Dead Band", nil);
    self.beginnerModeTitleLabel.text = NSLocalizedString(@"Beginner Mode", nil);
    self.headfreeModeTitleLabel.text = NSLocalizedString(@"Headfree Mode", nil);
    
    [self.defaultSettingsButton setTitle:NSLocalizedString(@"Default Settings", nil) forState:UIControlStateNormal];
    [self.peripheralListScanButton setTitle:NSLocalizedString(@"Scan", nil) forState:UIControlStateNormal];
    
    self.isScanningTextLabel.text = NSLocalizedString(@"Scanning Flexbot...", nil);
    
    [self.magCalibrateButton setTitle:NSLocalizedString(@"Calibrate Mag", nil) forState:UIControlStateNormal];
    [self.accCalibrateButton setTitle:NSLocalizedString(@"Calibrate Acc", nil) forState:UIControlStateNormal];
    
    self.channelListTableView.backgroundColor = [UIColor clearColor];
    self.channelListTableView.backgroundView.hidden = YES;
    
    NSString *currentLan = [NSLocale preferredLanguages][0];
    NSURL *aboutFileURL = nil;
    if (![currentLan isEqual:@"en"] && ![currentLan isEqual:@"zh-Hans"] && ![currentLan isEqual:@"zh-Hant"]) {
        NSBundle *enBundle =[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"]];
        aboutFileURL = [NSURL fileURLWithPath:[enBundle pathForResource:@"About" ofType:@"html"]];
    } else {
        aboutFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"]];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:aboutFileURL];
    [self.aboutWebView loadRequest:request];
    [self updateSettingsUI];
    if (self.peripheralList == nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotificationPeripheralListDidChange) name:kNotificationPeripheralListDidChange object:nil];
        self.peripheralList =  [[[Transmitter sharedTransmitter] bleSerialManager] bleSerialList];
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateConnectionState) userInfo:nil repeats:YES];
        [self.connectionActivityIndicatorView stopAnimating];
        self.connectionActivityIndicatorView.hidden = YES;
    }
    self.selectedPeripheral = [[Transmitter sharedTransmitter] bleSerialManager].currentBleSerial;
}

- (void)updateConnectionState {
    CBPeripheral *peripheral = [[[Transmitter sharedTransmitter] bleSerialManager] currentBleSerial];
    
    if (self.isTryingConnect && ![peripheral isConnected]) {
        return;
    } else {
        if ([peripheral isConnected]) {
            if (self.isTryingConnect) {
                NSInteger i = [self.peripheralList indexOfObject:self.selectedPeripheral];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                if (indexPath) {
                    [self.peripheralListTableView beginUpdates];
                    [self.peripheralListTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [self.peripheralListTableView endUpdates];
                }
                self.isTryingConnect = NO;
            }
        } else {
            if (self.isTryingDisconnect) {
                NSInteger i = [self.peripheralList indexOfObject:self.selectedPeripheral];
                self.selectedPeripheral = nil;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                if (indexPath) {
                    [self.peripheralListTableView beginUpdates];
                    [self.peripheralListTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [self.peripheralListTableView endUpdates];
                }
                self.isTryingDisconnect = NO;
            }
        }
        
        TransmitterState inputState = [[Transmitter sharedTransmitter] inputState];
        TransmitterState outputState = [[Transmitter sharedTransmitter] outputState];
        
        if ((inputState == TransmitterStateOk) && (outputState == TransmitterStateOk)) {
            self.connectionStateTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"connected", nil)];
            self.connectionActivityIndicatorView.hidden = YES;
        } else if ((inputState == TransmitterStateOk) && (outputState != TransmitterStateOk)) {
            self.connectionStateTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"not connected", nil)];
        } else if ((inputState != TransmitterStateOk) && (outputState == TransmitterStateOk)) {
            self.connectionStateTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"not connected", nil)];
        } else {
            self.connectionStateTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"not connected", nil)];
        }
    }
    
    self.peripheralListTableView.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (![self.channelSettingsVC.view superview]) {
        self.channelSettingsVC = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationDismissChannelSettingsView object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationPeripheralListDidChange object:nil];
}

- (void)dismissChannelSetttingsView {
    [self.channelSettingsVC.view removeFromSuperview];
    [self.channelListTableView reloadData];
}

- (void)updateTakeOffThrottleLabel {
    Channel *throttleChannel = [self.settings channelByName:kChannelNameThrottle];
    
    float outputValue = clip(-1 + self.settings.takeOffThrottle * 2.0f + throttleChannel.trimValue, -1.0f, 1.0f);
    
    if (throttleChannel.isReversing) {
        outputValue = -outputValue;
    }
    
    float takeOffThrottle = 1500.0f + 500.0f * (outputValue * throttleChannel.outputAdjustabledRange);
    self.takeOffThrottleLabel.text = [NSString stringWithFormat:@"%.2f, %dus", self.settings.takeOffThrottle, (int)takeOffThrottle];
}

- (void)updateRudderDeadBandLabel {
    self.rudderDeadBandLabel.text = [NSString stringWithFormat:@"%.2f%%", self.settings.rudderDeadBand * 100.0f];
}

- (void)updateRudderDeadBandSlider {
    self.rudderDeadBandSlider.value = self.settings.rudderDeadBand / (float)kRudderMaxDeadBandRatio;
}

- (void)updateAileronElevatorDeadBandLabel {
    self.aileronElevatorDeadBandLabel.text = [NSString stringWithFormat:@"%.2f%%", self.settings.aileronDeadBand * 100.0f];
}

- (void)updateAileronElevatorDeadBandSlider {
    self.aileronElevatorDeadBandSlider.value = self.settings.aileronDeadBand / (float)kAileronElevatorMaxDeadBandRatio;
}

#pragma mark UIWebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	} else {
		return YES;
	}
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == kChannelListTableView) {
        if ([indexPath section] == ChannelListTableViewSectionChannels) {
            Channel *channel = [self.settings channelAtIndex:[indexPath row]];
            if (self.channelSettingsVC == nil) {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    self.channelSettingsVC  = [[ChannelSettingsViewController alloc] initWithNibName:@"ChannelSettingsViewController" bundle:nil channel:channel];
                } else {
                    self.channelSettingsVC  = [[ChannelSettingsViewController alloc] initWithNibName:@"ChannelSettingsViewController_iPhone" bundle:nil channel:channel];
                }
            }
            self.channelSettingsVC.channel = channel;
            [self.view addSubview:self.channelSettingsVC.view];
        }
    } else if (tableView.tag == kPeripheralDeviceListTabelView) {
        CBPeripheral *peripheral = self.peripheralList[[indexPath row]];
        NSString *deviceName = peripheral.name;
        self.selectedPeripheral = peripheral;
        NSString *title = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Connection", nil), deviceName];
        if ([[[Transmitter sharedTransmitter] bleSerialManager] currentBleSerial] == peripheral) {
            if ([[Transmitter sharedTransmitter] isConnected]) {
                NSString *msg = NSLocalizedString(@"Disconnect to Flexbot?", nil);
                [self showAlertViewWithTitle:title cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Disconnect", nil) message:msg tag:settings_alert_dialog_disconnect];
            } else {
                NSString *msg = NSLocalizedString(@"Connect to Flexbot?", nil);
                [self showAlertViewWithTitle:title cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Connect", nil) message:msg tag:settings_alert_dialog_connect];
            }
        } else {
            NSString *msg = NSLocalizedString(@"Connect to Flexbot?", nil);
            [self showAlertViewWithTitle:title cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Connect", nil) message:msg tag:settings_alert_dialog_connect];
        }
    }
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView.tag == kChannelListTableView) {
        switch (section) {
            case ChannelListTableViewSectionChannels:
                return 8;
            default:
                return 0;
        }
    } else {
        return self.peripheralList.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView.tag == kChannelListTableView) {
        switch (section) {
            case ChannelListTableViewSectionChannels:
                return NSLocalizedString(@"CHANNELS", nil);
            default:
                return @"";
        }
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == kChannelListTableView) {
        switch ([indexPath section]) {
            case ChannelListTableViewSectionChannels: {
                NSString *cellId = [NSString stringWithFormat:@"CellType%d", kChannelListTableView];
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
                    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                }
                Channel *channel = [self.settings channelAtIndex:[indexPath row]];
                cell.textLabel.text = [NSString stringWithFormat:@"%u: %@", [channel idx] + 1, [channel name]];
                int minOutputPpm = (int)(1500 + 500 * clip(-1 + channel.trimValue, -1, 1) * channel.outputAdjustabledRange);
                int maxOutputPpm = (int)(1500 + 500 * clip(1 + channel.trimValue, -1, 1) * channel.outputAdjustabledRange);
                NSString *ppmRangeText = [NSString stringWithFormat:@"%d~%dus", minOutputPpm, maxOutputPpm];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@:%.2f %@:%.2f %@", [channel isReversing] ? NSLocalizedString(@"Reversed", nil):NSLocalizedString(@"Normal", nil), NSLocalizedString(@"Trim", nil), [channel trimValue], NSLocalizedString(@"Adjustable", nil), [channel outputAdjustabledRange], ppmRangeText];
                return cell;
            }
            default:
                return nil;
        }
    } else {
        NSString *cellId = [NSString stringWithFormat:@"CellType%d", kPeripheralDeviceListTabelView];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
        CBPeripheral *peripheral = self.peripheralList[[indexPath row]];
        cell.textLabel.text = peripheral.name;
        cell.detailTextLabel.text = [peripheral.identifier UUIDString];
        if ([peripheral isConnected] && [self.selectedPeripheral isEqual:peripheral]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
}

#pragma mark UITableViewDataSource Methods end

- (void)setSwitchButton:(UIButton *)switchButton withValue:(BOOL)active {
    if (active) {
        switchButton.tag = SWITCH_BUTTON_CHECKED;
        [switchButton setImage:[UIImage imageNamed:@"Btn_ON"] forState:UIControlStateNormal];
    } else {
        switchButton.tag = SWITCH_BUTTON_UNCHECKED;
        [switchButton setImage:[UIImage imageNamed:@"Btn_OFF"] forState:UIControlStateNormal];
    }
}

- (void)toggleSwitchButton:(UIButton *)switchButton {
    [self setSwitchButton:switchButton withValue:(SWITCH_BUTTON_UNCHECKED == switchButton.tag) ? YES : NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	NSUInteger currentPage = (int) (self.settingsPageScrollView.contentOffset.x + 0.5f * self.settingsPageScrollView.frame.size.width) / self.settingsPageScrollView.frame.size.width;
    
    if (currentPage == 0) {
        [self.previousPageButton setHidden:YES];
        [self.nextPageButton setHidden:NO];
    } else if (currentPage == (self.pageCount - 1)) {
        [self.previousPageButton setHidden:NO];
        [self.nextPageButton setHidden:YES];
    } else if (currentPage >= self.pageCount) {
        currentPage = self.pageCount - 1;
        [self.previousPageButton setHidden:NO];
        [self.nextPageButton setHidden:YES];
    } else {
        [self.previousPageButton setHidden:NO];
        [self.nextPageButton setHidden:NO];
    }
    [self.pageControl setCurrentPage:currentPage];
    [self.pageTitleLabel setText:self.pageTitleArray[currentPage]];
}

- (void)showPreviousPageView {
    int nextPage = ((int)(self.settingsPageScrollView.contentOffset.x + 0.5f * self.settingsPageScrollView.frame.size.width) / self.settingsPageScrollView.frame.size.width) - 1;
    if (0 > nextPage) {
        nextPage = 0;
    }
    CGFloat nextOffset = nextPage * self.settingsPageScrollView.frame.size.width;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3f];
    [self.settingsPageScrollView setContentOffset:CGPointMake(nextOffset, 0.0f) animated:NO];
    [UIView commitAnimations];
}

- (void)showNextPageView {
    NSUInteger nextPage = ((int)(self.settingsPageScrollView.contentOffset.x + 0.5f * self.settingsPageScrollView.frame.size.width) / self.settingsPageScrollView.frame.size.width) + 1;
    if (self.pageCount <= nextPage) {
        nextPage = self.pageCount - 1;
    }
    CGFloat nextOffset = nextPage * self.settingsPageScrollView.frame.size.width;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3f];
    [self.settingsPageScrollView setContentOffset:CGPointMake(nextOffset, 0.0f) animated:NO];
    [UIView commitAnimations];
}

- (void)resetToDefaultSettings {
    [self.settings resetToDefault];
    [self.settings save];
    [self updateSettingsUI];
    
    if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:leftHandedValueDidChange:)]) {
        [self.delegate settingsMenuViewController:self leftHandedValueDidChange:self.settings.isLeftHanded];
    }
    if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:accModeValueDidChange:)]) {
        [self.delegate settingsMenuViewController:self accModeValueDidChange:self.settings.isAccMode];
    }
    if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:ppmPolarityReversed:)]) {
        [self.delegate settingsMenuViewController:self ppmPolarityReversed:self.settings.ppmPolarityIsNegative];
    }
    if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:interfaceOpacityValueDidChange:)]) {
        [self.delegate settingsMenuViewController:self interfaceOpacityValueDidChange:self.settings.interfaceOpacity];
    }
}

- (void)startConnect {
    self.isTryingConnect = YES;
    self.isTryingDisconnect = NO;
    self.connectionStateTextLabel.text = NSLocalizedString(@"Connecting...", nil);
    [self.connectionActivityIndicatorView startAnimating];
    self.connectionActivityIndicatorView.hidden = NO;
    self.isScanningTextLabel.hidden = YES;
}

- (void)switchScan {
    BleSerialManager *manager = [[Transmitter sharedTransmitter] bleSerialManager];
    if ([manager isScanning]) {
        [self.peripheralListScanButton setTitle:NSLocalizedString(@"Scan", nil) forState:UIControlStateNormal];
        self.isScanningTextLabel.hidden = YES;
        self.connectionActivityIndicatorView.hidden = YES;
        [manager stopScan];
    } else {
        [[[Transmitter sharedTransmitter] bleSerialManager] disconnect];
        [manager scan];
        if ([manager isScanning]) {
            [self.peripheralListScanButton setTitle:NSLocalizedString(@"Stop Scan", nil) forState:UIControlStateNormal];
            self.isScanningTextLabel.hidden = NO;
            self.connectionActivityIndicatorView.hidden = NO;
            [self.connectionActivityIndicatorView startAnimating];
        }
    }
}

- (NSData *)getSimpleSetCmd:(int)cmdName {
    unsigned char cmd[6];
    cmd[0] = '$';
    cmd[1] = 'M';
    cmd[2] = '<';
    cmd[3] = 0;
    cmd[4] = cmdName;
    unsigned char checkSum = 0;
    checkSum ^= (cmd[3] & 0xFF);
    checkSum ^= (cmd[4] & 0xFF);
    cmd[5] = checkSum;
    return [NSData dataWithBytes:cmd length:6];
}

- (IBAction)buttonClick:(id)sender {
    if (sender == self.okButton) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDismissSettingsMenuView object:self userInfo:nil];
    } else if (sender == self.previousPageButton) {
        [self showPreviousPageView];
    } else if (sender == self.nextPageButton) {
        [self showNextPageView];
    } else if (sender == self.defaultSettingsButton) {
        NSString *msg = NSLocalizedString(@"Reset to defaut settings?", nil);
        [self showAlertViewWithTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Reset", nil) message:msg tag:settings_alert_dialog_default];
    } else if (sender == self.peripheralListScanButton) {
        [self switchScan];
    } else if (sender == self.accCalibrateButton) {
        NSString *msg = NSLocalizedString(@"Calibrate the accelerator of Flexbot?", nil);
        [self showAlertViewWithTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Calibrate", nil) message:msg tag:settings_alert_dialog_calibrate_acc];
    } else if (sender == self.magCalibrateButton) {
        NSString *msg = NSLocalizedString(@"Calibrate the magnetometer of Flexbot?", nil);
        [self showAlertViewWithTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:NSLocalizedString(@"Calibrate", nil) message:msg tag:settings_alert_dialog_calibrate_mag];
    } else if (sender == self.upTrimButton) {
        [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_TRIM_UP];
    } else if (sender == self.downTrimButton) {
        [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_TRIM_DOWN];
    } else if (sender == self.leftTrimButton) {
        [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_TRIM_LEFT];
    } else if (sender == self.rightTrimButton) {
        [[Transmitter sharedTransmitter] transmmitSimpleCommand:MSP_TRIM_RIGHT];
    }
}

- (IBAction)switchButtonClick:(id)sender {
    [self toggleSwitchButton:sender];
    
    if (sender == self.leftHandedSwitchButton) {
        self.settings.isLeftHanded = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:leftHandedValueDidChange:)]) {
            [self.delegate settingsMenuViewController:self leftHandedValueDidChange:self.settings.isLeftHanded];
        }
    } else if (sender == self.ppmPolarityReversedSwitchButton) {
        self.settings.ppmPolarityIsNegative = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:ppmPolarityReversed:)]) {
            [self.delegate settingsMenuViewController:self ppmPolarityReversed:self.settings.ppmPolarityIsNegative];
        }
    } else if (sender == self.accModeSwitchButton) {
        self.settings.isAccMode = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:accModeValueDidChange:)]) {
            [self.delegate settingsMenuViewController:self accModeValueDidChange:self.settings.isAccMode];
        }
    } else if (sender == self.beginnerModeSwitchButton) {
        self.settings.isBeginnerMode = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:beginnerModeValueDidChange:)]) {
            [self.delegate settingsMenuViewController:self beginnerModeValueDidChange:self.settings.isBeginnerMode];
        }
    } else if (sender == self.headfreeModeSwitchButton) {
        self.settings.isHeadFreeMode = (SWITCH_BUTTON_CHECKED == [sender tag]) ? YES : NO;
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:headfreeModeValueDidChange:)]) {
            [self.delegate settingsMenuViewController:self headfreeModeValueDidChange:self.settings.isHeadFreeMode];
        }
    }
}

- (IBAction)sliderRelease:(id)sender {
    if (sender == self.interfaceOpacitySlider) {
        [self.settings save];
        if ([self.delegate respondsToSelector:@selector(settingsMenuViewController:interfaceOpacityValueDidChange:)]) {
            [self.delegate settingsMenuViewController:self interfaceOpacityValueDidChange:self.settings.interfaceOpacity];
        }
    } else if (sender == self.takeOffThrottleSlider) {
        [self.settings save];
    } else if (sender == self.aileronElevatorDeadBandSlider) {
        [self.settings save];
    } else if (sender == self.rudderDeadBandSlider) {
        [self.settings save];
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    if (sender == self.interfaceOpacitySlider) {
        self.interfaceOpacityLabel.text = [NSString stringWithFormat:@"%d %%", (int)self.interfaceOpacitySlider.value];
        self.settings.interfaceOpacity = self.interfaceOpacitySlider.value / 100.0f;
    } else if (sender == self.takeOffThrottleSlider) {
        self.settings.takeOffThrottle = self.takeOffThrottleSlider.value;
        [self updateTakeOffThrottleLabel];
    } else if (sender == self.aileronElevatorDeadBandSlider) {
        self.settings.aileronDeadBand = kAileronElevatorMaxDeadBandRatio * self.aileronElevatorDeadBandSlider.value;
        self.settings.elevatorDeadBand = self.settings.aileronDeadBand;
        [self updateAileronElevatorDeadBandLabel];
    } else if (sender == self.rudderDeadBandSlider) {
        self.settings.rudderDeadBand = kRudderMaxDeadBandRatio * self.rudderDeadBandSlider.value;
        [self updateRudderDeadBandLabel];
    }
}

- (void)handleNotificationPeripheralListDidChange {
    [self.peripheralListTableView reloadData];
}

- (void)showAlertViewWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle message:(NSString *)message tag:(int)tag {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:okButtonTitle, nil];
    alertView.tag = tag;
    [alertView show];
}

#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        switch (alertView.tag) {
            case settings_alert_dialog_connect:
                if ([[[Transmitter sharedTransmitter] bleSerialManager] isScanning]) {
                    [self switchScan];
                }
                [[[Transmitter sharedTransmitter] bleSerialManager] disconnect];
                self.isTryingConnect = YES;
                self.isTryingDisconnect = NO;
                [[[Transmitter sharedTransmitter] bleSerialManager] connect:self.selectedPeripheral];
                break;
            case settings_alert_dialog_disconnect:
                self.isTryingConnect = NO;
                self.isTryingDisconnect = YES;
                [[[Transmitter sharedTransmitter] bleSerialManager] disconnect];
                break;
            case settings_alert_dialog_default:
                [self resetToDefaultSettings];
                break;
            case settings_alert_dialog_calibrate_mag:
                [[[Transmitter sharedTransmitter] bleSerialManager] sendData:[self getSimpleSetCmd:206]];
                break;
            case settings_alert_dialog_calibrate_acc:
                [[[Transmitter sharedTransmitter] bleSerialManager] sendData:[self getSimpleSetCmd:205]];
                break;
            default:
                break;
        }
    }
}

@end
