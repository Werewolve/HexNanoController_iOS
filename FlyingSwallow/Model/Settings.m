//
//  Settings.m
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

#import "Settings.h"
#import "Channel.h"

@interface Settings () {
    NSMutableArray *_channelArray;
}
@property (nonatomic, strong) NSString *path;
@end

@implementation Settings

- (id)initWithSettingsFile:(NSString *)settingsFilePath{
    self = [super init];
    
    if(self){
        self.path = settingsFilePath;
        
        self.settingsData = [[NSMutableDictionary alloc] initWithContentsOfFile:_path];
        NSArray *channelDataArray = self.settingsData[kKeySettingsChannels];
        NSUInteger channelCount = [channelDataArray count];
        _channelArray = [[NSMutableArray alloc] initWithCapacity:channelCount];

        for(int channelIdx = 0; channelIdx < channelCount; channelIdx++){
            Channel *channel = [[Channel alloc] initWithSetting:self idx:channelIdx];
            [_channelArray addObject:channel];
            
        }
    }
    
    return self;
}

- (void)setInterfaceOpacity:(float)interfaceOpacity{
    self.settingsData[kKeySettingsInterfaceOpacity] = @(interfaceOpacity);
}

- (float)interfaceOpacity {
    return [self.settingsData[kKeySettingsInterfaceOpacity] floatValue];
}

- (void)setIsLeftHanded:(BOOL)isLeftHanded{
    self.settingsData[kKeySettingsIsLeftHanded] = @(isLeftHanded);
}

- (BOOL)isLeftHanded {
    return [self.settingsData[kKeySettingsIsLeftHanded] boolValue];
}

- (void)setIsAccMode:(BOOL)isAccMode{
    self.settingsData[kKeySettingsIsAccMode] = @(isAccMode);
}

- (BOOL)isAccMode {
    return [self.settingsData[kKeySettingsIsAccMode] boolValue];
}

- (void)setIsHeadFreeMode:(BOOL)isHeadFreeMode{
    self.settingsData[kKeySettingsIsHeadFreeMode] = @(isHeadFreeMode);
}

- (BOOL)isHeadFreeMode {
    return [self.settingsData[kKeySettingsIsHeadFreeMode] boolValue];
}

- (void)setIsAltHoldMode:(BOOL)isAltHoldMode{
    self.settingsData[kKeySettingsIsAltHoldMode] = @(isAltHoldMode);
}

- (BOOL)isAltHoldMode {
    return [self.settingsData[kKeySettingsIsAltHoldMode] boolValue];
}

- (void)setIsBeginnerMode:(BOOL)isBeginnerMode{
    self.settingsData[kKeySettingsIsBeginnerMode] = @(isBeginnerMode);
}

- (BOOL)isBeginnerMode {
    return [self.settingsData[kKeySettingsIsBeginnerMode] boolValue];
}

- (void)setPpmPolarityIsNegative:(BOOL)ppmPolarityIsNegative{
    self.settingsData[kKeySettingsPpmPolarityIsNegative] = @(ppmPolarityIsNegative);
}

- (BOOL)ppmPolarityIsNegative {
    return [self.settingsData[kKeySettingsPpmPolarityIsNegative] boolValue];
}

- (void)setAileronDeadBand:(float)aileronDeadBand{
    self.settingsData[kKeySettingsAileronDeadBand] = @(aileronDeadBand);
}

- (float)aileronDeadBand {
    return [self.settingsData[kKeySettingsAileronDeadBand] floatValue];
}

- (void)setElevatorDeadBand:(float)elevatorDeadBand{
    self.settingsData[kKeySettingsElevatorDeadBand] = @(elevatorDeadBand);
}

- (float)elevatorDeadBand {
    return [self.settingsData[kKeySettingsElevatorDeadBand] floatValue];
}

- (void)setRudderDeadBand:(float)rudderDeadBand{
    self.settingsData[kKeySettingsRudderDeadBand] = @(rudderDeadBand);
}

- (float)rudderDeadBand {
    return [self.settingsData[kKeySettingsRudderDeadBand] floatValue];
}

- (void)setTakeOffThrottle:(float)takeOffThrottle{
    self.settingsData[kKeySettingsTakeOffThrottle] = @(takeOffThrottle);
}

- (float)takeOffThrottle {
    return [self.settingsData[kKeySettingsTakeOffThrottle] floatValue];
}

- (void)save{
    [self.settingsData writeToFile:_path atomically:YES];
}

- (NSUInteger)channelCount{
    return [_channelArray count];
}

- (Channel *)channelAtIndex:(NSUInteger)i{
    if(i < [_channelArray count]){
        return _channelArray[i];
    }
    else {
        return nil;
    }
}

- (Channel *)channelByName:(NSString*)name{
    for(Channel *channel in _channelArray){
        if([name isEqualToString:[channel name]]){
            return channel;
        }
    }
    return nil;
}

- (void)changeChannelFrom:(NSUInteger)from to:(NSUInteger)to{
    Channel *channel = _channelArray[from];
	[_channelArray removeObjectAtIndex:from];
	[_channelArray insertObject:channel atIndex:to];
    
    NSMutableArray *channelDataArray = (NSMutableArray *)[self.settingsData valueForKey:kKeySettingsChannels];
    
	id channelData = channelDataArray[from];
	[channelDataArray removeObjectAtIndex:from];
	[channelDataArray insertObject:channelData atIndex:to];
	
	int idx = 0;
	for (Channel *oneChannel in _channelArray) {
		oneChannel.idx = idx++;
	}
}

- (void)resetToDefault{
    NSString *defaultSettingsFilePath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
    
    Settings *defaultSettings = [[Settings alloc] initWithSettingsFile:defaultSettingsFilePath];
    self.settingsData = [defaultSettings.settingsData mutableCopy];

    NSUInteger channelCount = [defaultSettings channelCount];
    
    for(NSUInteger defaultChannelIdx = 0; defaultChannelIdx < channelCount; defaultChannelIdx++){
        Channel *defaultChannel = [[Channel alloc] initWithSetting:defaultSettings idx:(int)defaultChannelIdx];

        Channel *channel = [self channelByName:defaultChannel.name];
        
        if(channel.idx != defaultChannelIdx){
            Channel *needsReordedChannel = _channelArray[defaultChannelIdx];
            needsReordedChannel.idx = channel.idx;
            
            [_channelArray exchangeObjectAtIndex:defaultChannelIdx withObjectAtIndex:channel.idx];
            
            channel.idx = (int)defaultChannelIdx;
        }

        channel.isReversing = defaultChannel.isReversing;
        channel.trimValue = defaultChannel.trimValue;
        channel.outputAdjustabledRange = defaultChannel.outputAdjustabledRange;
        channel.defaultOutputValue = defaultChannel.defaultOutputValue;
        channel.value = channel.defaultOutputValue;

    }
    
}



@end
