//
//  STAResponseSerialization.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
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
    /// 解析失败，因为报文的前15个字节都不对， 删除报文的前n个字节， 这个n 由 usedLength 属性控制
    STRAnalysisResult_failed = 0,
    /// 解析成功
    STRAnalysisResult_success,
};

@interface STAResponseSerialization : NSObject
@property(nonatomic, readonly, assign) STRAnalysisResult analysisStatus;
@property(nonatomic, readonly, assign) BOOL cmgTag;
@property(nonatomic, readonly, assign) NSUInteger usedLength;
@property(nonatomic, readonly, assign) STARespCmdStatus cmdStatus;
@property(nonatomic, readonly, copy) NSString *des;
@property(nonatomic, readonly, copy) NSData *responseData;
@property(nonatomic, readonly, copy) NSObject *reasonseInfo;

+ (instancetype)analysisData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
