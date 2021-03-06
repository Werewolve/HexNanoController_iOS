//
//  Settings.h
//  FlyingSwallow
//
//  Created by koupoo on 12-12-22.
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

#import <Foundation/Foundation.h>

#define kKeySettingsInterfaceOpacity @"InterfaceOpacity"
#define kKeySettingsIsLeftHanded @"IsLeftHanded"
#define kKeySettingsIsAccMode @"IsAccMode"
#define kKeySettingsPpmPolarityIsNegative @"PpmPolarityIsNegative"
#define kKeySettingsIsHeadFreeMode @"IsHeadFreeMode"
#define kKeySettingsIsAltHoldMode @"IsAltHoldMode"
#define kKeySettingsIsBeginnerMode @"IsBeginnerMode"
#define kKeySettingsAileronDeadBand @"AileronDeadBand"
#define kKeySettingsElevatorDeadBand @"ElevatorDeadBand"
#define kKeySettingsRudderDeadBand @"RudderDeadBand"
#define kKeySettingsTakeOffThrottle @"TakeOffThrottle"
#define kKeySettingsChannels @"Channels"

@class Channel;
@interface Settings : NSObject

@property(nonatomic, strong) NSMutableDictionary *settingsData;

@property(nonatomic, assign) float interfaceOpacity;
@property(nonatomic, assign) BOOL  isLeftHanded;
@property(nonatomic, assign) BOOL isAccMode;
@property(nonatomic, assign) BOOL ppmPolarityIsNegative;
@property(nonatomic, assign) BOOL isHeadFreeMode;
@property(nonatomic, assign) BOOL isAltHoldMode;
@property(nonatomic, assign) BOOL isBeginnerMode;
@property(nonatomic, assign) float aileronDeadBand;
@property(nonatomic, assign) float elevatorDeadBand;
@property(nonatomic, assign) float rudderDeadBand;
@property(nonatomic, assign) float takeOffThrottle;

- (id)initWithSettingsFile:(NSString *)settingsFilePath;
- (NSUInteger)channelCount;
- (Channel *)channelAtIndex:(NSUInteger)i;
- (Channel *)channelByName:(NSString*)name;
- (void)changeChannelFrom:(NSUInteger)from to:(NSUInteger)to;
- (void)save;
- (void)resetToDefault;

@end
