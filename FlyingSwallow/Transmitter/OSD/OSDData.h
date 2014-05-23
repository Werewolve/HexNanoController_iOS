//
//  OSDData.h
//  UdpEchoClient
//
//  Created by koupoo on 13-2-28.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OSDData;

@protocol OSDDataDelegate <NSObject>

//- (void)OSDDataDidUpdateTimeOut:(OSDData *)osdData;

- (void)osdDataDidUpdateOneFrame:(OSDData *)osdData;

@end


@interface OSDData : NSObject

@property(nonatomic, readonly, assign) int version;

@property(nonatomic, readonly, assign) int multiType;

@property(nonatomic, readonly, assign) float gyroX;
@property(nonatomic, readonly, assign) float gyroY;
@property(nonatomic, readonly, assign) float gyroZ;

@property(nonatomic, readonly, assign) float accX;
@property(nonatomic, readonly, assign) float accY;
@property(nonatomic, readonly, assign) float accZ;

@property(nonatomic, readonly, assign) float magX;
@property(nonatomic, readonly, assign) float magY;
@property(nonatomic, readonly, assign) float magZ;

@property(nonatomic, readonly, assign) float altitude;
@property(nonatomic, readonly, assign) float head;
@property(nonatomic, readonly, assign) float angleX;
@property(nonatomic, readonly, assign) float angleY;

@property(nonatomic, readonly, assign) int gpsSatCount;
@property(nonatomic, readonly, assign) int gpsLongitude;
@property(nonatomic, readonly, assign) int gpsLatitude;
@property(nonatomic, readonly, assign) int gpsAltitude;
@property(nonatomic, readonly, assign) int gpsDistanceToHome;
@property(nonatomic, readonly, assign) int gpsDirectionToHome;
@property(nonatomic, readonly, assign) int gpsFix;
@property(nonatomic, readonly, assign) int gpsUpdate;
@property(nonatomic, readonly, assign) int gpsSpeed;

@property(nonatomic, readonly, assign) float rcThrottle;
@property(nonatomic, readonly, assign) float rcYaw;
@property(nonatomic, readonly, assign) float rcRoll;
@property(nonatomic, readonly, assign) float rcPitch;
@property(nonatomic, readonly, assign) float rcAux1;
@property(nonatomic, readonly, assign) float rcAux2;
@property(nonatomic, readonly, assign) float rcAux3;
@property(nonatomic, readonly, assign) float rcAux4;

@property(nonatomic, readonly, assign) float debug1;
@property(nonatomic, readonly, assign) float debug2;
@property(nonatomic, readonly, assign) float debug3;
@property(nonatomic, readonly, assign) float debug4;


@property(nonatomic, readonly, assign) int pMeterSum;
@property(nonatomic, readonly, assign) int byteVbat;

@property(nonatomic, readonly, assign) int cycleTime;
@property(nonatomic, readonly, assign) int i2cError;

@property(nonatomic, readonly, assign) int mode;
@property(nonatomic, readonly, assign) int present;

@property(nonatomic, weak) id<OSDDataDelegate> delegate;

- (id)initWithOSDData:(OSDData *)osdData;
- (void)parseRawData:(NSData *)data;


@end
