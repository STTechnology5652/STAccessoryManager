//
//  STAResHeadererilizer.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, STARespCmdStatus) {
    AP_REQ_ACK = 0x01,
    AP_REQ_UNKOWN = 0x80,
    AP_REQ_FAIL = 0x81,
    AP_REQ_ERROR_NO_LEN = 0x82,
    AP_REQ_ERROR_LEN = 0x83,
    AP_REQ_ERROR_FORMAT = 0x84,
    AP_REQ_ERROR_RES = 0x85,
    AP_REQ_ERROR_FPS = 0x86,
};

typedef NS_ENUM(NSUInteger, STRAnalysisResult) {
    /// 解析失败， 删除报文的前n个字节， 这个n 由 usedLength 属性控制
    STRAnalysisResult_failed = 0,
    /// 数据长度不够
    STRAnalysisResult_dataNotEnough,
    /// 解析成功
    STRAnalysisResult_success,
};

@interface STAResHeader: NSObject
@property(nonatomic, readonly, assign) UInt8 cmdId;
@property(nonatomic, readonly, assign) UInt8 cmdStatus;
@property(nonatomic, readonly, assign) UInt8 cmdTag;
@property(nonatomic, readonly, assign) UInt32 cmdDataLen;
@property(nonatomic, readonly, strong) NSData *responseContent;

@property(nonatomic, readonly, assign) UInt8 cmdEOH;
@property(nonatomic, readonly, assign) UInt8 cmdERR;
@property(nonatomic, readonly, assign) UInt8 cmdSTI;
@property(nonatomic, readonly, assign) UInt8 cmdRES;
@property(nonatomic, readonly, assign) UInt8 cmdSCR;
@property(nonatomic, readonly, assign) UInt8 cmgPTS;
@property(nonatomic, readonly, assign) UInt8 cmdEOF;
@property(nonatomic, readonly, assign) UInt8 cmdFID;

@property(nonatomic, readonly, assign) UInt32 imageDataLen;

@property(nonatomic, readonly, assign) UInt8 b2;
@property(nonatomic, readonly, assign) UInt8 b3;
@property(nonatomic, readonly, assign) UInt8 b4;
@property(nonatomic, readonly, assign) UInt8 b5;
@property(nonatomic, readonly, assign) UInt8 headerLen;

- (STARespCmdStatus) resCmdStatus;
- (NSDictionary *)headerDict;
- (NSString *)headerJsonString;
- (NSUInteger)headerSorted:(unsigned char *)byt len:(NSUInteger)len;
@end


@interface STAResHeadererilizer : NSObject

@end

NS_ASSUME_NONNULL_END
