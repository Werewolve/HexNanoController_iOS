//
//  PPMTransmitter.m
//  RCTouch
//
//  Created by koupoo on 13-3-15.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import "Transmitter.h"
#import "OSDCommon.h"
#import "BasicInfoManager.h"

#define kPpmChannelCount 8
#define kOsdRequestFreqRatio 2
#define kInputAllowableContiniousTimeoutCount  2
#define kOutputAllowableContiniousTimeoutCount 2
#define kInputTimeout  0.5
#define kOutputTimeout 0.5

@interface Transmitter () {
    float oldChannelList[kPpmChannelCount];
    float channelList[kPpmChannelCount];
    unsigned char package[22];
}

@property (nonatomic, assign) enum PpmPolarity polarity;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong, readwrite) BleSerialManager *bleSerialManager;
@property (nonatomic, assign) int outputTimeoutCount;
@property (nonatomic, assign) int inputTimeoutCount;

@end

@implementation Transmitter

+ (Transmitter *)sharedTransmitter{
    static Transmitter* sharedTransmitter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedTransmitter = [[Transmitter alloc] init];
	});
	return sharedTransmitter;
}

- (id)init {
    if (self = [super init]) {
        self.outputState = TransmitterStateError;
        self.inputState = TransmitterStateError;
        self.bleSerialManager = [[BleSerialManager alloc] init];
        self.bleSerialManager.delegate = self;
    }
    return self;
}

- (void)updatePpmPackage2 {
    unsigned char checkSum = 0;
    
    int dataSizeIdx = 3;
    int checkSumIdx = 9;
    
    checkSum ^= (package[dataSizeIdx] & 0xFF);
    checkSum ^= (package[dataSizeIdx + 1] & 0xFF);
    
    for (int channelIdx = 0; channelIdx < kPpmChannelCount - 4; channelIdx++) {
        float scale =  channelList[channelIdx];
        if (scale > 1.0f) {
            scale = 1.0f;
        } else if (scale < -1.0f) {
            scale = -1.0f;
        }
        unsigned char pulseLen =  (uint16_t)(fabs(500 + 500 * scale)) / 4;
        package[5 + channelIdx] = pulseLen;
        checkSum ^= (package[5 + channelIdx] & 0xFF);
    }
    package[checkSumIdx] = checkSum;
}

- (void)updatePpmPackage {
    unsigned char checkSum = 0;
    
    int dataSizeIdx = 3;
    int checkSumIdx = 10;
    package[dataSizeIdx] = 5;
    
    checkSum ^= (package[dataSizeIdx] & 0xFF);
    checkSum ^= (package[dataSizeIdx + 1] & 0xFF);
    
    for (int channelIdx = 0; channelIdx < kPpmChannelCount - 4; channelIdx++) {
        float scale =  channelList[channelIdx];
        if (scale > 1.0f) {
            scale = 1.0f;
        } else if (scale < -1.0f) {
            scale = -1.0f;
        }
        unsigned char pulseLen =  (uint16_t)(fabs(500 + 500 * scale)) / 4;
        package[5 + channelIdx] = pulseLen;
        checkSum ^= (package[5 + channelIdx] & 0xFF);
    }
    
    unsigned char auxChannels = 0x00;
    
    float aux1Scale = channelList[4];
    if (aux1Scale < -0.666) {
        auxChannels |= 0x00;
    } else if (aux1Scale < 0.3333) {
        auxChannels |= 0x40;
    } else {
        auxChannels |= 0x80;
    }
    
    float aux2Scale = channelList[5];
    if (aux2Scale < -0.666) {
        auxChannels |= 0x00;
    } else if (aux2Scale < 0.3333) {
        auxChannels |= 0x10;
    } else {
        auxChannels |= 0x20;
    }
    
    float aux3Scale = channelList[6];
    if (aux3Scale < -0.666) {
        auxChannels |= 0x00;
    } else if (aux3Scale < 0.3333) {
        auxChannels |= 0x04;
    } else {
        auxChannels |= 0x08;
    }
    
    float aux4Scale = channelList[7];
    if (aux4Scale < -0.666) {
        auxChannels |= 0x00;
    } else if (aux4Scale < 0.3333) {
        auxChannels |= 0x01;
    } else {
        auxChannels |= 0x02;
    }
    
    package[5 + 4] = auxChannels;
    checkSum ^= (package[5 + 4] & 0xFF);
    package[checkSumIdx] = checkSum;
}

- (void)updatePackageCheckSum {
    unsigned char checkSum = 0;
    
    int dataSizeIdx = 3;
    int checkSumIdx = 21;
    
    for (int checkIdx = dataSizeIdx; checkIdx < checkSumIdx; checkIdx++) {
        checkSum ^= (package[checkIdx] & 0xFF);
    }
    package[checkSumIdx] = checkSum;
}

- (void)initPackage {
    package[0] = '$';
    package[1] = 'M';
    package[2] = '<';
    package[3] = 4;
    package[4] = MSP_SET_RAW_RC_TINY;
    
    [self updatePpmPackage];
}

- (void)sendTransmitterStateDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTransmitterStateDidChange object:self userInfo:nil];
}

- (void)transmmit {
    @autoreleasepool {
        static int osdRequestTimer = 0;
        osdRequestTimer++;
        [self updatePpmPackage];
        
        memcpy(oldChannelList, channelList, kPpmChannelCount * sizeof(float));
        NSMutableData *data = nil;
        if (!data) {
            data = [NSMutableData dataWithBytes:package length:11];
        } else {
            [data appendData:[NSData dataWithBytes:package length:11]];
        }
        if ([self.bleSerialManager isConnected] && data != nil) {
            [self.bleSerialManager sendData:data];
        }
    }
}

- (BOOL)start {
    [self stop];
    [self initPackage];
    if (!self.osdData) {
        self.osdData = [[OSDData alloc] init];
        self.osdData.delegate = self;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.04 target:self selector:@selector(transmmit) userInfo:nil repeats:YES];
    return YES;
}

- (BOOL)stop {
    [self.timer invalidate];
    self.timer = nil;
    return YES;
}

- (void)setPpmValue:(float)value atChannel:(NSUInteger)channelIdx {
    channelList[channelIdx] = value;
}

- (BOOL)isConnected {
    return ((self.outputState == TransmitterStateOk) && (self.inputState == TransmitterStateOk));
}

- (BOOL)transmmitData:(NSData *)data{
    if ([self.bleSerialManager isConnected] && data != nil) {
        NSMutableData *packageData = [NSMutableData data];
        for (int idx = 0; idx < 1; idx++) {
            [packageData appendData:data];
        }
        [self.bleSerialManager sendData:packageData];
        return YES;
    }
    return NO;
}

- (BOOL)transmmitSimpleCommand:(unsigned char)commandName {
    return [self transmmitData:getSimpleCommand(commandName)];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	exit(0);
}

- (void)osdDataDidUpdateOneFrame:(OSDData *)osdData {
    [[[BasicInfoManager sharedManager] osdView] setNeedsDisplay];
}

#pragma mark BleSerialManagerDelegate Methods

- (void)bleSerialManager:(BleSerialManager *)manager didUpdateState:(BOOL)isAvailable {
}

- (void)bleSerialManager:(BleSerialManager *)manager didDiscoverBleSerial:(CBPeripheral *)peripheral {
    NSLog(@"discover ble serial");
}

- (void)bleSerialManager:(BleSerialManager *)manager didConnectPeripheral:(CBPeripheral *)peripheral {
    self.outputState = TransmitterStateOk;
    self.inputState = TransmitterStateOk;
    [self sendTransmitterStateDidChangeNotification];
}

- (void)bleSerialManager:(BleSerialManager *)manager didFailToConnectPeripheral:(CBPeripheral *)peripheral {
    self.outputState = TransmitterStateError;
    self.inputState = TransmitterStateError;
    [self sendTransmitterStateDidChangeNotification];
    
    NSLog(@"didFailToConnectPeripheral");
    
    [[[Transmitter sharedTransmitter] bleSerialManager] disconnect];
    [[[Transmitter sharedTransmitter] bleSerialManager] connect:peripheral];
}

- (void)bleSerialManager:(BleSerialManager *)manager didDisconnectPeripheral:(CBPeripheral *)peripheral {
    self.outputState = TransmitterStateError;
    self.inputState = TransmitterStateError;
    
    NSLog(@"didDisconnectPeripheral");
    
    [self sendTransmitterStateDidChangeNotification];
}

- (void)bleSerialManagerDidFailSendData:(BleSerialManager *)manager error:(NSError *)error {
    NSLog(@"fail send data***");
}

- (void)bleSerialManagerDidSendData:(BleSerialManager *)manager {
    self.outputTimeoutCount = 0;
    if (self.outputState == TransmitterStateError) {
        self.outputState = TransmitterStateOk;
        [self sendTransmitterStateDidChangeNotification];
    }
    NSLog(@"did send data***");
}

- (void)bleSerialManager:(BleSerialManager *)manager didReceiveData:(NSData *)data{
    [self.osdData parseRawData:data];
}

#pragma mark BleSerialManagerDelegate Methods end

- (void)dealloc {
    [self stop];
}

@end
