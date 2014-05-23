//
//  OSDData.m
//  UdpEchoClient
//
//  Created by koupoo on 13-2-28.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//


#import "OSDData.h"
#include "OSDCommon.h"
#include <vector>
#include <string>

using namespace std;

#define OSD_UPDATE_REQUEST_FREQ 50

#define IDLE         0
#define HEADER_START 1
#define HEADER_M     2
#define HEADER_ARROW 3
#define HEADER_SIZE  4
#define HEADER_CMD   5
#define HEADER_ERR   6

@interface OSDData() {
    int c_state;
    bool err_rcvd;
    byte checksum;
    byte cmd;
    int offset, dataSize;
    byte inBuf[256];
    int p;
    
    float mot[8], servo[8];
    long currentTime,mainInfoUpdateTime,attitudeUpdateTime;
}
@property(nonatomic, readwrite, assign) int version;

@property(nonatomic, readwrite, assign) int multiType;

@property(nonatomic, readwrite, assign) float gyroX;
@property(nonatomic, readwrite, assign) float gyroY;
@property(nonatomic, readwrite, assign) float gyroZ;

@property(nonatomic, readwrite, assign) float accX;
@property(nonatomic, readwrite, assign) float accY;
@property(nonatomic, readwrite, assign) float accZ;

@property(nonatomic, readwrite, assign) float magX;
@property(nonatomic, readwrite, assign) float magY;
@property(nonatomic, readwrite, assign) float magZ;

@property(nonatomic, readwrite, assign) float altitude;
@property(nonatomic, readwrite, assign) float head;
@property(nonatomic, readwrite, assign) float angleX;
@property(nonatomic, readwrite, assign) float angleY;

@property(nonatomic, readwrite, assign) int gpsSatCount;
@property(nonatomic, readwrite, assign) int gpsLongitude;
@property(nonatomic, readwrite, assign) int gpsLatitude;
@property(nonatomic, readwrite, assign) int gpsAltitude;
@property(nonatomic, readwrite, assign) int gpsDistanceToHome;
@property(nonatomic, readwrite, assign) int gpsDirectionToHome;
@property(nonatomic, readwrite, assign) int gpsFix;
@property(nonatomic, readwrite, assign) int gpsUpdate;
@property(nonatomic, readwrite, assign) int gpsSpeed;

@property(nonatomic, readwrite, assign) float rcThrottle;
@property(nonatomic, readwrite, assign) float rcYaw;
@property(nonatomic, readwrite, assign) float rcRoll;
@property(nonatomic, readwrite, assign) float rcPitch;
@property(nonatomic, readwrite, assign) float rcAux1;
@property(nonatomic, readwrite, assign) float rcAux2;
@property(nonatomic, readwrite, assign) float rcAux3;
@property(nonatomic, readwrite, assign) float rcAux4;

@property(nonatomic, readwrite, assign) float debug1;
@property(nonatomic, readwrite, assign) float debug2;
@property(nonatomic, readwrite, assign) float debug3;
@property(nonatomic, readwrite, assign) float debug4;


@property(nonatomic, readwrite, assign) int pMeterSum;
@property(nonatomic, readwrite, assign) int byteVbat;

@property(nonatomic, readwrite, assign) int cycleTime;
@property(nonatomic, readwrite, assign) int i2cError;

@property(nonatomic, readwrite, assign) int mode;
@property(nonatomic, readwrite, assign) int present;
@end

@implementation OSDData

- (id)init{
    if(self =[super init]){
        self.rcThrottle = 1500;
        self.rcRoll     = 1500;
        self.rcPitch    = 1500;
        self.rcYaw      =1500;
        self.rcAux1     =1500;
        self.rcAux2     =1500;
        self.rcAux3     =1500;
        self.rcAux4     =1500;

    }
    
    return self;
}

- (id)initWithOSDData:(OSDData *)osdData{
    if(self = [super init]){
        self.version = osdData.version;
        
        self.multiType = osdData.multiType;
        
        self.gyroX = osdData.gyroX;
        self.gyroY = osdData.gyroY;
        self.gyroZ = osdData.gyroZ;
        
        self.accX = osdData.accX;
        self.accY = osdData.accY;
        self.accZ = osdData.accZ;
        
        self.magX = osdData.magX;
        self.magY = osdData.magY;
        self.magZ = osdData.magZ;
        
        self.altitude = osdData.altitude;
        self.head     = osdData.head;
        self.angleX   = osdData.angleX;
        self.angleY   = osdData.angleY;
        
        self.gpsSatCount  = osdData.gpsSatCount;
        self.gpsLongitude = osdData.gpsLongitude;
        self.gpsLatitude  = osdData.gpsLatitude;
        self.gpsAltitude  = osdData.gpsAltitude;
        self.gpsDistanceToHome = osdData.gpsDistanceToHome;
        self.gpsDirectionToHome = osdData.gpsDirectionToHome;
        self.gpsFix = osdData.gpsFix;
        self.gpsUpdate = osdData.gpsUpdate;
        self.gpsSpeed = osdData.gpsSpeed;
        
        self.rcThrottle = osdData.rcThrottle;
        self.rcYaw      = osdData.rcYaw;
        self.rcRoll     = osdData.rcRoll;
        self.rcPitch    = osdData.rcPitch;
        self.rcAux1     = osdData.rcAux1;
        self.rcAux2     = osdData.rcAux2;
        self.rcAux3     = osdData.rcAux3;
        self.rcAux4     = osdData.rcAux4;
        
        self.pMeterSum = osdData.pMeterSum;
        self.byteVbat = osdData.byteVbat;
        
        self.cycleTime = osdData.cycleTime;
        self.i2cError = osdData.i2cError;
        
        self.mode = osdData.mode;
        self.present = osdData.present;
        
        self.debug1 = osdData.debug1;
        self.debug2 = osdData.debug2;
        self.debug3 = osdData.debug3;
        self.debug4 = osdData.debug4;
    }
    
    return self;
}

- (Float32)read32{
//    uint32_t part1 = (inBuf[p++]&0xff);
//    uint32self.t part2 = ((inBuf[p++]&0xff)<<8);
//    uint32_t part3 = ((inBuf[p++]&0xff)<<16);
//    uint32_t part4 = ((inBuf[p++]&0xff)<<24);
//    
//    uint32_t num = part1 + part2 + part3 + part4;
//    
//    float num2 = 10;
//    
//    
//    memcpy(&num2, &num, 4);
//    
//    
//    return num2;
    
    return (inBuf[p++]&0xff) + ((inBuf[p++]&0xff)<<8) + ((inBuf[p++]&0xff)<<16) + ((inBuf[p++]&0xff)<<24);
}

- (float)int32ToFloat:(int)intNum{
    float floatNum;
    
    memcpy((void *)(&floatNum), (void *)(&intNum), 4);
    
    return floatNum;
}

- (int16_t)read16{
    return (inBuf[p++]&0xff) + ((inBuf[p++])<<8); 
}

- (int)read8 {
    return inBuf[p++]&0xff;
}

- (void)parseRawData:(NSData *)data{
//    if ((currentTime - mainInfoUpdateTime) >(double)(1000 / updateFreq)* CLOCKS_PER_SEC / 1000.0) {
//        printf("\n***time durantion:%lfms", (currentTime - mainInfoUpdateTime) / (float)CLOCKS_PER_SEC * 1000);
//        
//        mainInfoUpdateTime = currentTime;
//        
//        printf("\nrequest \n");
//        
//        //vector<byte> requestList = requestMSPList(mainInfoRequest, 12);
//        
//        if(_delegate != nil){
//           // NSData *request = [NSData dataWithBytes:requestList.data() length:requestList.size()];
//           // [_delegate sendOsdDataUpdateRequest:request];
//        }
//    }
    
    NSUInteger byteCount = data.length;
    
    byte * dataPtr = (byte *)data.bytes;
    
    int idx;
    byte c;
    
    for (int byteIdx = 0; byteIdx < byteCount; byteIdx++) {
        c = dataPtr[byteIdx];
        
        if (c_state == IDLE) {
            c_state = (c=='$') ? HEADER_START : IDLE;
        } else if (c_state == HEADER_START) {
            c_state = (c=='M') ? HEADER_M : IDLE;
        } else if (c_state == HEADER_M) {
            if (c == '>') {
                c_state = HEADER_ARROW;
            } else if (c == '!') {
                c_state = HEADER_ERR;
            } else {
                c_state = IDLE;
            }
        } else if (c_state == HEADER_ARROW || c_state == HEADER_ERR) {
            /* is this an error message? */
            err_rcvd = (c_state == HEADER_ERR);        /* now we are expecting the payload size */
            dataSize = (c&0xFF);
            /* reset index variables */
            p = 0;
            offset = 0;
            checksum = 0;
            checksum ^= (c&0xFF);
            /* the command is to follow */
            c_state = HEADER_SIZE;
        } else if (c_state == HEADER_SIZE) {
            cmd = (byte)(c&0xFF);
            checksum ^= (c&0xFF);
            c_state = HEADER_CMD;
        } else if (c_state == HEADER_CMD && offset < dataSize) {
            checksum ^= (c&0xFF);
            inBuf[offset++] = (byte)(c&0xFF);
        } else if (c_state == HEADER_CMD && offset >= dataSize) {
            /* compare calculated and transferred checksum */
            if ((checksum&0xFF) == (c&0xFF)) {
                if (err_rcvd) {
                    //printf("Copter did not understand request type %d\n", c);
                     c_state = IDLE;
                    
                } else {
                    /* we got a valid response packet, evaluate it */
                    [self evaluateCommand:cmd dataSize:dataSize];
                }
            } else {
                NSLog(@"invalid checksum for command %d: %d expected, got %d\n", ((int)(cmd&0xFF)), (checksum&0xFF), (int)(c&0xFF));
                NSLog(@"<%d %d> {",(cmd&0xFF), (dataSize&0xFF));
                
                for (idx = 0; idx < dataSize; idx++) {
                    if (idx != 0) { 
                        printf(" ");   
                    }
                    printf("%d",(inBuf[idx] & 0xFF));
                }
                
                printf("} [%d]\n", c);
                
                string data((char *)inBuf, dataSize);
                
                printf("%s\n", data.c_str());
                
            }
            c_state = IDLE;
        }

    }
}

- (void)evaluateCommand:(byte)cmd_ dataSize:(int)aDataSize{
    int i;
    int icmd = (int)(cmd_ & 0xFF);
    switch(icmd) {
        case MSP_IDENT:
            self.version = [self read8];
            self.multiType = [self read8];
            [self read8]; // MSP version
            [self read32];// capability
            break;
        case MSP_STATUS:
            self.cycleTime = [self read16];
            self.i2cError  = [self read16];
            self.present   = [self read16];
            self.mode      = [self read32];
            break;
        case MSP_RAW_IMU:
            self.accX = [self read16];
            self.accY = [self read16];
            self.accZ = [self read16];
            self.gyroX = [self read16] / 8;
            self.gyroY = [self read16] / 8;
            self.gyroZ = [self read16] / 8;
            self.magX = [self read16] / 3;
            self.magY = [self read16] / 3;
            self.magZ = [self read16] / 3;             
            break;
        case MSP_SERVO:
            for(i=0;i<8;i++) 
                servo[i] = [self read16]; 
            break;
        case MSP_MOTOR:
            for(i=0;i<8;i++) 
                mot[i] = [self read16]; 
            break;
        case MSP_RC:
            self.rcRoll     = [self read16];
            self.rcPitch    = [self read16];
            self.rcYaw      = [self read16];
            self.rcThrottle = [self read16];    
            self.rcAux1 = [self read16];
            self.rcAux2 = [self read16];
            self.rcAux3 = [self read16];
            self.rcAux4 = [self read16];
            break;
        case MSP_RAW_GPS:
            self.gpsFix = [self read8];
            self.gpsSatCount = [self read8];
            self.gpsLatitude = [self read32];
            self.gpsLongitude = [self read32];
            self.gpsAltitude = [self read16];
            self.gpsSpeed = [self read16]; 
            break;
        case MSP_COMP_GPS:
            self.gpsDistanceToHome = [self read16];
            self.gpsDirectionToHome = [self read16];
            self.gpsUpdate = [self read8]; 
            break;
        case MSP_ATTITUDE:
            self.angleX = [self read16]/10;  //[-180,180]，往右roll时，为正数
            self.angleY = [self read16]/10;  //[-180,180]，头往上仰时，为负
            self.head = [self read16]; 
            
            if(self.delegate != nil) {
                [self.delegate osdDataDidUpdateOneFrame:self];
            }
            break;
        case MSP_ALTITUDE:
            self.altitude = (float) [self read32]; //[self int32ToFloat:[self read32]];
            break;
        case MSP_BAT:
            self.byteVbat = [self read8];
            self.pMeterSum = [self read16]; 
            break;
        case MSP_RC_TUNING:
            break;
        case MSP_ACC_CALIBRATION:
            break;
        case MSP_MAG_CALIBRATION:
            break;
        case MSP_PID:
            break;
        case MSP_BOX:
            break;
        case MSP_BOXNAMES:
            break;
        case MSP_PIDNAMES:
            break;
        case MSP_MISC:
            break;
        case MSP_MOTOR_PINS:
            break;
        case MSP_SET_RAW_RC_TINY:
            NSLog(@"set rc: %d, %d, %d, %d", [self read16], [self read16], [self read16], [self read16]);
            break;
        case MSP_DEBUG:
            self.debug1 = [self read16];
            self.debug2 = [self read16];
            self.debug3 = [self read16];
            self.debug4 = [self read16];
            break;
        default:
            NSLog(@"error: Don't know how to handle reply:%d datasize:%d", icmd, aDataSize);
            break;
           
    }
}


@end
