//
//  Channel.m
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

#import "Channel.h"
#import "Settings.h"
#import "Transmitter.h"
#import "util.h"

@interface Channel()
@property(nonatomic, strong, readwrite) NSString *name;
@property(nonatomic, strong) NSMutableDictionary *data;
@end

@implementation Channel

- (id)initWithSetting:(Settings *)settings idx:(int)idx {
    self = [super init];
    if (self) {
        self.ownerSettings = settings;
        self.idx = idx;
        self.data = [settings.settingsData valueForKey:kKeySettingsChannels][idx];
        self.name = [_data valueForKey:kKeyChannelName];
        self.isReversing = [[_data valueForKey:kKeyChannelIsReversed] boolValue];
        self.trimValue = [[_data valueForKey:kKeyChannelTrimValue] floatValue];
        self.outputAdjustabledRange = [[_data valueForKey:kKeyChannelOutputAdjustableRange] floatValue];
        self.defaultOutputValue = [[_data valueForKey:kKeyChannelDefaultOutputValue] floatValue];
        [self setValue:self.defaultOutputValue];
    }
    return self;
}

- (void)setValue:(float)value {
	_value = clip(value, -1.0, 1.0);
	float outputValue = clip(value + self.trimValue, -1.0, 1.0);
	if (self.isReversing) {
		outputValue = -outputValue;
	}
	outputValue *= self.outputAdjustabledRange;
    
    [[Transmitter sharedTransmitter] setPpmValue:outputValue atChannel:self.idx];
}

- (void)setIsReversed:(BOOL)isReversing {
    _isReversing = isReversing;
    [self.data setValue:@(self.isReversing) forKey:kKeyChannelIsReversed];
}

- (void)setTrimValue:(float)trimValue {
    _trimValue = trimValue;
    [self.data setValue:@(self.trimValue) forKey:kKeyChannelTrimValue];
}

- (void)setOutputAdjustabledRange:(float)outputAdjustabledRange {
    _outputAdjustabledRange = outputAdjustabledRange;
    [self.data setValue:@(self.outputAdjustabledRange) forKey:kKeyChannelOutputAdjustableRange];
}

- (void)setDefaultOutputValue:(float)defaultOutputValue {
    _defaultOutputValue = defaultOutputValue;
    [self.data setValue:@(self.defaultOutputValue) forKey:kKeyChannelDefaultOutputValue];
}

@end
