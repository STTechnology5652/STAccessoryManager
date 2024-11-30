//
//  STAResHeadererilizer.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/23.
//

#import "STAResHeadererilizer.h"

#import <STLog/STLogTool.h>

@interface STAResHeader()
@property(nonatomic, assign) UInt8 cmdId;
@property(nonatomic, assign) UInt8 cmdStatus;
@property(nonatomic, assign) UInt8 cmdTag;
@property(nonatomic, assign) UInt32 cmdDataLen;
@property(nonatomic, strong) NSData *responseContent;

@property(nonatomic, assign) UInt8 cmdEOH;
@property(nonatomic, assign) UInt8 cmdERR;
@property(nonatomic, assign) UInt8 cmdSTI;
@property(nonatomic, assign) UInt8 cmdRES;
@property(nonatomic, assign) UInt8 cmdSCR;
@property(nonatomic, assign) UInt8 cmdPTS;
@property(nonatomic, assign) UInt8 cmdEOF;
@property(nonatomic, assign) UInt8 cmdFID;

@property(nonatomic, assign) UInt32 imageDataLen;

@property(nonatomic, assign) UInt8 b2;
@property(nonatomic, assign) UInt8 b3;
@property(nonatomic, assign) UInt8 b4;
@property(nonatomic, assign) UInt8 b5;
@property(nonatomic, assign) UInt8 headerLen;
@end

@implementation STAResHeader

- (STARespCmdStatus) resCmdStatus {return self.cmdStatus;}

- (NSDictionary *)headerDict {
    NSDictionary *map = @{
        @"cmdId" : [NSString stringWithFormat:@"%02x", self.cmdId],
        @"cmdStatus" : [NSString stringWithFormat:@"%02x", self.cmdStatus],
        @"cmdTag" : [NSString stringWithFormat:@"%02x", self.cmdTag],
        @"cmdDataLen" : [NSString stringWithFormat:@"%04x", self.cmdDataLen],
        @"cmdDataLenIntValue" : [NSString stringWithFormat:@"%06d", self.cmdDataLen],
        @"cmdId" : [NSString stringWithFormat:@"%02x", self.cmdId],
        
        @"imageDataLen" : [NSString stringWithFormat:@"%04x", self.imageDataLen],
        @"imageDataLenIntValue" : [NSString stringWithFormat:@"%06d", self.imageDataLen],
        @"b2" : [NSString stringWithFormat:@"%02x", self.b2],
        @"b3" : [NSString stringWithFormat:@"%02x", self.b3],
        @"b4" : [NSString stringWithFormat:@"%02x", self.b4],
        @"b5" : [NSString stringWithFormat:@"%02x", self.b5],
        @"headerLen" : [NSString stringWithFormat:@"%02x", self.headerLen],

        @"cmdEOH" : [NSString stringWithFormat:@"%02x", self.cmdEOH],
        @"cmdERR" : [NSString stringWithFormat:@"%02x", self.cmdERR],
        @"cmdSTI" : [NSString stringWithFormat:@"%02x", self.cmdSTI],
        @"cmdRES" : [NSString stringWithFormat:@"%02x", self.cmdRES],
        @"cmdSCR" : [NSString stringWithFormat:@"%02x", self.cmdSCR],
        @"cmdPTS" : [NSString stringWithFormat:@"%02x", self.cmdPTS],
        @"cmdEOF" : [NSString stringWithFormat:@"%02x", self.cmdEOF],
        @"cmdFID" : [NSString stringWithFormat:@"%02x", self.cmdFID],
    };
    
    return map;
}

- (NSString *)headerJsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self headerDict] options:0 error:&error];
    if (error) {
        STLogWarning(@"Error converting dictionary to JSON: %@", error.localizedDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSUInteger)headerSorted:(unsigned char *)byt len:(NSUInteger)len {
    NSUInteger offset = 0;
    UInt8 b0 = byt[offset++];
    UInt8 b1 = byt[offset++]; //b1 暂时不处理
    UInt8 b2 = byt[offset++]; // pts
    UInt8 b3 = byt[offset++]; // pts
    UInt8 b4 = byt[offset++]; // pts
    UInt8 b5 = byt[offset++]; // pts
    UInt8 b6 = byt[offset++]; //b1 暂时不处理
    UInt8 b7 = byt[offset++]; //b1 暂时不处理
    UInt8 b8 = byt[offset++]; //b1 暂时不处理
    UInt8 b9 = byt[offset++]; //b1 暂时不处理
    UInt8 b10 = byt[offset++]; //b10 cmdId
    UInt8 b11 = byt[offset++]; //b11 cmdStatus
    UInt8 headerLen = offset;
    
    self.cmdId = b10;
    self.cmdStatus = b11;
    self.cmdTag = b9 >> 4;
    
    if (self.cmdId != 0 && self.cmdTag != 0) { // 这是指令报文， 需要解析指令应答长度
        self.cmdDataLen = (b9 & 0x0F) << 4 << 8 | b8;
    }
    
//    self.cmdEOH = (b1 & 0x80) >> 7;
//    self.cmdERR = (b1 & 0x40) >> 6;
//    self.cmdSTI = (b1 & 0x20) >> 5;
//    self.cmdRES = (b1 & 0x10) >> 4;
//    self.cmdSCR = (b1 & 0x08) >> 3;
//    self.cmdPTS = (b1 & 0x04) >> 2;
//    self.cmdEOF = (b1 & 0x02) >> 1;
//    self.cmdFID = (b1 & 0x01) >> 0;
    if (self.cmdId == 0 && self.cmdTag == 0 && self.cmdStatus == 0) { //这是图像包
        self.imageDataLen = b7 << 8 | b6;
        self.b2 = b2;
        self.b3 = b3;
        self.b4 = b4;
        self.b5 = b5;
    }
    
    self.headerLen = offset;

    return offset;
}

@end


@implementation STAResHeadererilizer

@end
