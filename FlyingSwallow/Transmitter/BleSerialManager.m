//
//  BleSerialManager.m
//  RCTouch
//
//  Created by koupoo on 13-4-17.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import "BleSerialManager.h"

#define kSerialService           0xFFE0
#define kSerialCharacteristic    0xFFE1

@interface BleSerialManager()
@property(nonatomic, assign, readwrite) BOOL isAvailabel; //ble是否可用
@property(nonatomic, assign, readwrite) BOOL isConnected; //连接上Ble
@property(nonatomic, assign, readwrite) BOOL isReady;     //当Services和Charactristic都准备就绪，就可以传输数据了
@property(nonatomic, assign, readwrite) BOOL isScanning;
@property(nonatomic, strong, readwrite) CBCentralManager *centralManager;
@property(nonatomic, strong) NSMutableArray *bleSerialList;
@property(nonatomic, strong) CBPeripheral *currentBleSerial;

@property(nonatomic, assign) BOOL isTryingConnect;
@property(nonatomic, strong) CBCharacteristic  *serialCharacteristic;

@end

@implementation BleSerialManager

- (id)init{
    self = [super init];
    
    if (self) {
       self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
       self.bleSerialList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isConnected{
    return [self.currentBleSerial isConnected];
}

- (void)scan{
    if (self.isAvailabel == YES && self.isScanning == NO) {
        self.isScanning = YES;
        
        [self.bleSerialList removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPeripheralListDidChange object:self userInfo:nil];
        
        if ([self.delegate respondsToSelector:@selector(bleSerialManager:didDiscoverBleSerial:)]) {
            [self.delegate bleSerialManager:self didDiscoverBleSerial:nil];
        }
        
//        CBUUID *serialServiceUUID = [self getSerialServiceUUID];
        
//        NSDictionary *options = @{@"YES": CBCentralManagerScanOptionAllowDuplicatesKey};
        
       // [self.centralManager scanForPeripheralsWithServices:[NSArray arrayWithObject:serialServiceUUID]
                                                    //options:options];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        
        NSLog(@"Scanning started");
    }
}

-(void)stopScan{
    if (self.centralManager != nil) {
        [self.centralManager stopScan];
    }
    self.isScanning = NO;
}

-(void)connect:(CBPeripheral *)peripheral{
    if (peripheral == self.currentBleSerial) {
        if ([self isConnected]) {
            return;
        }
        if (self.isTryingConnect) {
            return;
        }
        
        self.isTryingConnect = YES;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    else{        
        [self disconnect];
        self.isTryingConnect = YES;
        self.currentBleSerial = peripheral;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)disconnect{
    if (self.currentBleSerial != nil) {
        [self.centralManager cancelPeripheralConnection:_currentBleSerial];
        self.currentBleSerial = nil;
        self.serialCharacteristic = nil;
    }
}

-(void)sendData:(NSData *)data{
    if(self.serialCharacteristic == nil){
        if ([self.delegate respondsToSelector:@selector(bleSerialManagerDidFailSendData:error:)]) {
            [self.delegate bleSerialManagerDidFailSendData:self error:nil];
        }
    }
    else{
        [self.currentBleSerial writeValue:data forCharacteristic:self.serialCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark CBPeripheralDelegate Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.isAvailabel = YES;
    }
    else{
        self.isAvailabel = NO;
    }
    
    if([self.delegate respondsToSelector:@selector(bleSerialManager:didUpdateState:)]){
        [self.delegate bleSerialManager:self didUpdateState:self.isAvailabel];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    // Reject any where the value is above reasonable range
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
//    if (RSSI.integerValue > -15) {
//        return;
//    }
//    
//    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
//    if (RSSI.integerValue < -35) {
//        return;
//    }
    
//    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    
    if (![self.bleSerialList containsObject:peripheral] && ([peripheral.name isEqualToString:@"AnyFlite"] || [peripheral.name isEqualToString:@"Hex Mini"] || [peripheral.name isEqualToString:@"HMSoft"] || [peripheral.name isEqualToString:@"Hex Nano"] || [peripheral.name isEqualToString:@"Any Flite"] || [peripheral.name isEqualToString:@"Flexbot"])) {
        [(NSMutableArray *)_bleSerialList addObject:peripheral];

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPeripheralListDidChange object:self userInfo:nil];
        
        if ([self.delegate respondsToSelector:@selector(bleSerialManager:didDiscoverBleSerial:)]) {
            [self.delegate bleSerialManager:self didDiscoverBleSerial:nil];
        }
	}
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if (peripheral != self.currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    self.isTryingConnect = NO;
    
    self.currentBleSerial = peripheral;
    
//    if(_delegate != nil){
//        if ([_delegate respondsToSelector:@selector(bleSerialManager:didConnectPeripheral:)]) {
//            [_delegate bleSerialManager:self didConnectPeripheral:peripheral];
//        }
//    }
    
    [self.centralManager stopScan];
    self.isScanning = NO;
    
    NSLog(@"Peripheral Connected");;
    NSLog(@"Scanning stopped");
    peripheral.delegate = self;
    
    CBUUID *serialServiceUUID = [self getSerialServiceUUID];

    [peripheral discoverServices:@[serialServiceUUID]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (peripheral != _currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    self.isTryingConnect = NO;

    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    
    self.currentBleSerial = nil;
}

//当非正常断开（cancelPeripheralConnection）时，error为断开的原因，
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{    
    if (self.currentBleSerial != nil && peripheral != self.currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    self.isTryingConnect = NO;
    if (error != nil) {
        NSLog(@"disconnect error:%@. (%@)", peripheral, [error localizedDescription]);
    }
    
    self.currentBleSerial = nil;
    
    if(self.delegate != nil){
        if ([self.delegate respondsToSelector:@selector(bleSerialManager:didDisconnectPeripheral:)]) {
            [self.delegate bleSerialManager:self didDisconnectPeripheral:peripheral];
        }
    }
}
#pragma mark CBPeripheralDelegate Methods end


- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.currentBleSerial.isConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.currentBleSerial.services != nil) {
        for (CBService *service in self.currentBleSerial.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([[characteristic.UUID UUIDString] isEqualToString:[self.serialCharacteristic.UUID UUIDString]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.currentBleSerial setNotifyValue:NO forCharacteristic:characteristic];
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.currentBleSerial];
}


#pragma mark CBPeripheralDelegate Methods
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (peripheral != self.currentBleSerial) {  //old peripheral just do nothing
        return;
    }
    
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    NSArray *characteristicList = @[[self getSerialCharacteristicUUID]];
    
    // Discover the characteristic we want...
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:characteristicList forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (peripheral != self.currentBleSerial) {  //old peripheral just do nothing
        return;
    }

    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[self getSerialCharacteristicUUID]]) {
    
            NSLog(@"****begin notify value for characteritic:%@", characteristic);
            
            self.serialCharacteristic = characteristic;
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            if(self.delegate != nil){
                if ([self.delegate respondsToSelector:@selector(bleSerialManager:didConnectPeripheral:)]) {
                    [self.delegate bleSerialManager:self didConnectPeripheral:peripheral];
                }
            }
            
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (peripheral != self.currentBleSerial) {  //old peripheral just do nothing
        return;
    }

    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error: %@", [error localizedDescription]);
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(bleSerialManager:didReceiveData:)]) {
        [self.delegate bleSerialManager:self didReceiveData:characteristic.value];
    }
    
//    // Have we got everything we need?
//    if ([stringFromData isEqualToString:@"EOM"]) {
//        
//        // We have, so show the data,
//        [self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
//        
//        // Cancel our subscription to the characteristic
//        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
//        
//        // and disconnect from the peripehral
//        [self.centralManager cancelPeripheralConnection:peripheral];
//    }
//    
//    // Otherwise, just add the data on to what we already have
//    [self.data appendData:characteristic.value];
//    
//    // Log it
}

//Invoked upon completion of a -[setNotifyValue:forCharacteristic:] request.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (peripheral != self.currentBleSerial || characteristic != self.serialCharacteristic) {  //old, just do nothing
        return;
    }
    
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self disconnect];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (peripheral != self.currentBleSerial || characteristic != self.serialCharacteristic) { //old do nothing
        return;
    }

    if (error != nil) {
        if ([self.delegate respondsToSelector:@selector(bleSerialManagerDidFailSendData:error:)]) {
            [self.delegate bleSerialManagerDidFailSendData:self error:error];
        }
    }
    else{
        if ([self.delegate respondsToSelector:@selector(bleSerialManagerDidSendData:)]) {
            [self.delegate bleSerialManagerDidSendData:self];
        }
    }
}

#pragma mark CBPeripheralDelegate Methods end

/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (CBUUID *)getSerialServiceUUID{
    UInt16 serialService = [self swap:kSerialService];
    
    NSData *serialServiceData = [[NSData alloc] initWithBytes:(char *)&serialService length:2];
    return [CBUUID UUIDWithData:serialServiceData];
}

- (CBUUID *)getSerialCharacteristicUUID{
    UInt16 serialCharacteristic_ = [self swap:kSerialCharacteristic];
    
    NSData *serialCharacteristicData = [[NSData alloc] initWithBytes:(char *)&serialCharacteristic_ length:2];
    
    return [CBUUID UUIDWithData:serialCharacteristicData];
}


- (void)dealloc{
    [self disconnect];
}

@end
