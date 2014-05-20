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

@implementation Settings
@synthesize settingsData = _settingsData;
@synthesize interfaceOpacity = _interfaceOpacity;
@synthesize isLeftHanded = _isLeftHanded;
@synthesize ppmPolarityIsNegative = _ppmPolarityIsNegative;
@synthesize isHeadFreeMode = _isHeadFreeMode;
@synthesize isAltHoldMode = _isAltHoldMode;
@synthesize isBeginnerMode = _isBeginnerMode;
@synthesize aileronDeadBand = _aileronDeadBand;
@synthesize elevatorDeadBand = _elevatorDeadBand;
@synthesize rudderDeadBand = _rudderDeadBand;
@synthesize takeOffThrottle = _takeOffThrottle;
@synthesize isAccMode = _isAccMode;

- (id)initWithSettingsFile:(NSString *)settingsFilePath{
    self = [super init];
    
    if(self){
        _path = settingsFilePath;
        
        _settingsData = [[NSMutableDictionary alloc] initWithContentsOfFile:_path];
        
        _interfaceOpacity = [_settingsData[kKeySettingsInterfaceOpacity] floatValue];
        _isLeftHanded = [_settingsData[kKeySettingsIsLeftHanded] boolValue];
        _isAccMode = [_settingsData[kKeySettingsIsAccMode] boolValue];
        _ppmPolarityIsNegative = [_settingsData[kKeySettingsPpmPolarityIsNegative] boolValue];
        _isHeadFreeMode = [_settingsData[kKeySettingsIsHeadFreeMode] boolValue];
        _isAltHoldMode =  [_settingsData[kKeySettingsIsAltHoldMode] boolValue];
        _isBeginnerMode = [_settingsData[kKeySettingsIsBeginnerMode] boolValue];
        _aileronDeadBand = [_settingsData[kKeySettingsAileronDeadBand] floatValue];
        _elevatorDeadBand = [_settingsData[kKeySettingsElevatorDeadBand] floatValue];
        _rudderDeadBand = [_settingsData[kKeySettingsRudderDeadBand] floatValue];
        _takeOffThrottle = [_settingsData[kKeySettingsTakeOffThrottle] floatValue];
        
        NSArray *channelDataArray = _settingsData[kKeySettingsChannels];
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
    _interfaceOpacity = interfaceOpacity;
    
    _settingsData[kKeySettingsInterfaceOpacity] = @(_interfaceOpacity);
}

- (void)setIsLeftHanded:(BOOL)isLeftHanded{
    _isLeftHanded = isLeftHanded;
    
     _settingsData[kKeySettingsIsLeftHanded] = @(_isLeftHanded);
}

- (void)setIsAccMode:(BOOL)isAccMode{
    _isAccMode = isAccMode;
    
    _settingsData[kKeySettingsIsAccMode] = @(_isAccMode);
}


- (void)setIsHeadFreeMode:(BOOL)isHeadFreeMode{
    _isHeadFreeMode = isHeadFreeMode;
    
    _settingsData[kKeySettingsIsHeadFreeMode] = @(_isHeadFreeMode);
}

- (void)setIsAltHoldMode:(BOOL)isAltHoldMode{
    _isAltHoldMode = isAltHoldMode;
    
    _settingsData[kKeySettingsIsAltHoldMode] = @(_isAltHoldMode);
}

- (void)setIsBeginnerMode:(BOOL)isBeginnerMode{
    _isBeginnerMode = isBeginnerMode;
    
    _settingsData[kKeySettingsIsBeginnerMode] = @(_isBeginnerMode);
}

- (void)setPpmPolarityIsNegative:(BOOL)ppmPolarityIsNegative{
    _ppmPolarityIsNegative = ppmPolarityIsNegative;

     _settingsData[kKeySettingsPpmPolarityIsNegative] = @(_ppmPolarityIsNegative);
}

- (void)setAileronDeadBand:(float)aileronDeadBand{
    _aileronDeadBand = aileronDeadBand;
    
     _settingsData[kKeySettingsAileronDeadBand] = @(_aileronDeadBand);
}

- (void)setElevatorDeadBand:(float)elevatorDeadBand{
    _elevatorDeadBand = elevatorDeadBand;
    
     _settingsData[kKeySettingsElevatorDeadBand] = @(_elevatorDeadBand);
}

- (void)setRudderDeadBand:(float)rudderDeadBand{
    _rudderDeadBand = rudderDeadBand;
    
    _settingsData[kKeySettingsRudderDeadBand] = @(_rudderDeadBand);
}


- (void)setTakeOffThrottle:(float)takeOffThrottle{
    _takeOffThrottle = takeOffThrottle;
    
    _settingsData[kKeySettingsTakeOffThrottle] = @(_takeOffThrottle);
}

- (void)save{
    [_settingsData writeToFile:_path atomically:YES];
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
    
    NSMutableArray *channelDataArray = (NSMutableArray *)[_settingsData valueForKey:kKeySettingsChannels];
    
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
    
    NSDictionary *defaultSettingsData = defaultSettings.settingsData;
    
    self.interfaceOpacity = [defaultSettingsData[kKeySettingsInterfaceOpacity] floatValue];
    self.isLeftHanded = [defaultSettingsData[kKeySettingsIsLeftHanded] boolValue];
    self.isAccMode = [defaultSettingsData[kKeySettingsIsAccMode] boolValue];
    self.ppmPolarityIsNegative = [defaultSettingsData[kKeySettingsPpmPolarityIsNegative] boolValue];
    self.isHeadFreeMode = [defaultSettingsData[kKeySettingsIsHeadFreeMode] boolValue];
    self.isAltHoldMode = [defaultSettingsData[kKeySettingsIsAltHoldMode] boolValue];
    self.isBeginnerMode = [defaultSettingsData[kKeySettingsIsBeginnerMode] boolValue];
    self.aileronDeadBand = [defaultSettingsData[kKeySettingsAileronDeadBand] floatValue];
    self.elevatorDeadBand = [defaultSettingsData[kKeySettingsElevatorDeadBand] floatValue];
    self.rudderDeadBand = [defaultSettingsData[kKeySettingsRudderDeadBand] floatValue];
    self.takeOffThrottle = [defaultSettingsData[kKeySettingsTakeOffThrottle] floatValue];
    
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
