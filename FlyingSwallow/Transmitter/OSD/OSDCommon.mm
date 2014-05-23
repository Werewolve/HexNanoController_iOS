//
//  OSDCommon.c
//  UdpEchoClient
//
//  Created by koupoo on 13-3-1.
//  Copyright (c) 2013年 www.hexairbot.com. All rights reserved.
//

#include "OSDCommon.h"
#include <vector>
#include <string>

#define kOsdInfoRequestListLen 2

using namespace std;

int mainInfoRequest[kOsdInfoRequestListLen] = {MSP_ATTITUDE, MSP_ALTITUDE};

vector<byte> requestMSPWithPayload (int msp, const string & payload) {
    vector<byte> bf;
    
    if (msp < 0) {
        return bf;
    }
    
    bf.insert(bf.begin(), MSP_HEADER, MSP_HEADER + strlen(MSP_HEADER));
    
    byte checksum=0;
    
    NSUInteger payloadLength = payload.length();
    
    byte pl_size = payloadLength != 0 ? (byte)payloadLength : 0;
    
    bf.push_back(pl_size);
    
    checksum ^= (pl_size&0xFF);
    
    bf.push_back((byte)(msp & 0xFF));
    
    checksum ^= (msp&0xFF);
    
    if (payloadLength != 0) {        
        byte b;
        for(int byteIdx = 0; byteIdx < payloadLength; byteIdx++) {
            b = payload[byteIdx];            
            bf.push_back((byte)(b&0xFF));
            checksum ^= (b&0xFF);
        }
        
    }
    bf.push_back(checksum);
    return (bf);
}

vector<byte> requestMSPList (const int *msps, int count) {
    vector<byte> requestList;
    string emptyPayload("");
    
    for(int mspIdx = 0; mspIdx < count; mspIdx++) {
        vector<byte> oneRequest = requestMSPWithPayload(msps[mspIdx], emptyPayload);
        
        requestList.insert(requestList.end(), oneRequest.begin(), oneRequest.end());
    }
    return requestList;
}

vector<byte> requestMSP(int msp) {
    string payload("");
    return requestMSPWithPayload(msp, payload);
}

void sendRequestMSP(const vector<byte>& msp) {
}

#ifdef __cplusplus
extern "C"{
#endif

NSData *getDefaultOSDDataRequest() {
    vector<byte> requestList = requestMSPList(mainInfoRequest, kOsdInfoRequestListLen);
    NSUInteger requestDataSize = requestList.size();
    return [NSData dataWithBytes:requestList.data() length:requestDataSize];
}

NSData *getSimpleCommand(unsigned char commandName) {
    unsigned char package[6];

    package[0] = '$';
    package[1] = 'M';
    package[2] = '<';
    package[3] = 0;
    package[4] = commandName;
    
    unsigned char checkSum = 0;
    
    int dataSizeIdx = 3;
    int checkSumIdx = 5;
    
    checkSum ^= (package[dataSizeIdx] & 0xFF);
    checkSum ^= (package[dataSizeIdx + 1] & 0xFF);
    
    package[checkSumIdx] = checkSum;

    return [NSData dataWithBytes:package length:6];
}

#ifdef __cplusplus
}
#endif