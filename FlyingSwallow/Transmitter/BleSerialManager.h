//
//  BleSerialManager.h
//  RCTouch
//
//  Created by koupoo on 13-4-17.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define kNotificationPeripheralListDidChange @"NPeripheralListDidChange"

@class BleSerialManager;
@protocol BleSerialManagerDelegate <NSObject>
@optional

- (void)bleSerialManager:(BleSerialManager *)manager didUpdateState:(BOOL)isAvailable;
- (void)bleSerialManager:(BleSerialManager *)manager didDiscoverBleSerial:(CBPeripheral *)peripheral;

- (void)bleSerialManager:(BleSerialManager *)manager didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)bleSerialManager:(BleSerialManager *)manager didFailToConnectPeripheral:(CBPeripheral *)peripheral;
- (void)bleSerialManager:(BleSerialManager *)manager didDisconnectPeripheral:(CBPeripheral *)peripheral;

- (void)bleSerialManagerDidFailSendData:(BleSerialManager *)manager error:(NSError *)error;
- (void)bleSerialManagerDidSendData:(BleSerialManager *)manager;
- (void)bleSerialManager:(BleSerialManager *)manager didReceiveData:(NSData *)data;

@end

@interface BleSerialManager : NSObject <CBCentralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property(nonatomic, assign, readonly) BOOL isAvailabel;
@property(nonatomic, assign, readonly) BOOL isConnected;
@property(nonatomic, assign, readonly) BOOL isReady;
@property(nonatomic, assign, readonly) BOOL isScanning;
@property(nonatomic, strong, readonly) CBCentralManager *centralManager;
@property(nonatomic, strong, readonly) NSMutableArray *bleSerialList;
@property(nonatomic, strong, readonly) CBPeripheral *currentBleSerial;
@property(nonatomic, weak) id<BleSerialManagerDelegate> delegate;

- (void)scan;
- (void)stopScan;
- (void)connect:(CBPeripheral *)peripheral;
- (void)disconnect;
- (void)sendData:(NSData *)data;

@end
