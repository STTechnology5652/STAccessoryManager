//
//  STACommandserialization.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

#import "STACommandserialization.h"
#import <STLog/STLogTool.h>

typedef NS_ENUM(UInt8, STCmdId) {
    STCmdIdStreamOnOff = 0x01,
    STCmdIdGetDeviceConfig,
    STCmdIdSetStreamSetting,
    STCmdIdGetPropertyPageInfo,
    STCmdIdGetPropertyValueOrMode,
    STCmdIdSetPropertyValueOrMode,
    STCmdIdExtensionUnit,
};

typedef NS_ENUM(NSUInteger, STCmdDir) {
    STcmdDirGet = 0x00,
    STcmdDirSet = 0x01,
};

@implementation STACommandserialization
+ (NSData *)getDevConfig: (UInt8) tag {
    NSData *cmdData = [NSData new];
    return [self createCmdWithTag:tag cmdId:STCmdIdGetDeviceConfig dir:STcmdDirGet cmdData:cmdData];
}


+ (NSData *)setStreamFormatter: (UInt8) tag {
    NSMutableData *cmdData = [NSMutableData new];
    UInt8 b4 = 0x02; // Format ID  0x01: YUV 0x02: MJ
    UInt8 b5 = 0x02; // Resolution ID
    UInt8 b6 = 30; // FPS
    [cmdData appendBytes:&b4 length:1];
    [cmdData appendBytes:&b5 length:1];
    [cmdData appendBytes:&b6 length:1];
    return [self createCmdWithTag:tag cmdId:STCmdIdSetStreamSetting dir:STcmdDirSet cmdData:cmdData];
}

+ (NSData *)openStreamCmdWithTag: (UInt8) tag open:(UInt8)open {
   return [self createCmdWithTag:tag cmdId:STCmdIdStreamOnOff dir:STcmdDirSet cmdData:[NSData dataWithBytes:&open length:1]];
}

+ (NSData *)createCmdWithTag:(UInt8)tag cmdId:(STRACmdId)cmdId dir:(UInt8)dir cmdData:(NSData *)cmdData {
    NSMutableData *result = [NSMutableData new];
    UInt8 cmdDataLenH = 0, cmdDataLenL = 0;
    UInt32 cmdLen = (UInt32)[cmdData length];
    cmdDataLenH = cmdLen >> 8 & 0x0F;
    cmdDataLenL = cmdLen & 0xFF;
    UInt8 cmdTag = tag << 4 | cmdDataLenH;
    
    [result appendBytes:&cmdDataLenL length:1]; // CMD Data Length Lo
    [result appendBytes:&cmdTag length:1]; // CMD Tag (Counter 1~F) | CMD Data Length Hi
    [result appendBytes:&cmdId length:1]; // CMD ID
    [result appendBytes:&dir length:1]; // CMD Dir (Get:0, Set:1)
    [result appendData:cmdData]; // Data
    STLogInfo(@"command to device >>>>: %@", result);
    return result;
}
@end
