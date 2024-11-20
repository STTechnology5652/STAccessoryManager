//
//  STAResponseSerialization.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

#import "STAResponseSerialization.h"
#import "STACommandserialization.h"

@interface STAResponseSerialization()

@property(nonatomic, assign) STRAnalysisResult analysisStatus;
@property(nonatomic, assign) BOOL cmgTag;
@property(nonatomic, assign) NSUInteger usedLength;
@property(nonatomic, copy) NSString *des;
@property(nonatomic, copy) NSData *responseData;
@property(nonatomic, copy) NSObject *reasonseInfo;

@end

@implementation STAResponseSerialization

+ (instancetype)analysisData:(NSData *)data {
    /*
     解包步骤：
     1. 取 0 - 12 字节
     2. 逐个字节解析
     3. 如果解析失败， 取 1 - 13 字节 再次尝试
     4. 依次类推， 解析 15次， 如果都不对， 则让buffer抛弃前 15 个字节。
     */
    
    STAResponseSerialization *result = [STAResponseSerialization new];
    unsigned char * byt = data.bytes;
    NSUInteger len = data.length;
    NSUInteger offset = 0;
    
    for (; offset <= len - 11; offset ++) {
        [result analysisByt:byt + offset len:len - offset];
        if (result.analysisStatus == STRAnalysisResult_success) { //解析成功
            result.usedLength += offset;
            break;
        }
    }
    
    offset --;
    if (result.analysisStatus == STRAnalysisResult_failed) { //len - 11 次解析，都失败了， 说明这段报文的前 len - 11 字节有问题
        result.usedLength = offset;
    }
    
    return result;
}

- (void) analysisByt: (unsigned char *)byt len:(NSUInteger)len {
    self.usedLength = 0; //重置消耗的字节数量
    if (len < 12 || byt == NULL) { //没有字节可以解析
        self.analysisStatus = STRAnalysisResult_failed; //剩余报文不够， 需要忽略此次解析
        return;
    }
    
    NSUInteger offset = 0;
    if (byt[offset++] != 0x0c) { // 头字节不对
        self.usedLength = offset;
        return;
    }
    
    unichar b1 = byt[offset++]; //b1 暂时不处理
    
    unichar b2 = byt[offset++]; // pts
    unichar b3 = byt[offset++]; // pts
    unichar b4 = byt[offset++]; // pts
    unichar b5 = byt[offset++]; // pts
    
    unichar b6 = byt[offset++]; //b1 暂时不处理
    
    unichar b7 = byt[offset++]; //b1 暂时不处理
    unichar b8 = byt[offset++]; //b1 暂时不处理
    unichar b9 = byt[offset++]; //b1 暂时不处理
    unichar b10 = byt[offset++]; //b10 cmdId
    unichar b11 = byt[offset++]; //b11 cmdStatus
    
    /*
     1. 判断 cmdId， 如果是0， 则认为是 视频流数据报文
     2. 根据 cmdId 做对应报文的解析
     */
    
    switch (b10) {
        case STRACmdId_GetDeviceConfig:
            break;
        case   STRACmdId_SetStreamOnOff:
            break;
        case STRACmdId_SetStreamSetting:
            break;
        case STRACmdId_GetPropertyPageInfo:
            break;
        case STRACmdId_GetPropertyValueOrMode:
            break;
        case STRACmdId_SetPropertyValueOrMode:
            break;
        default:
            break;
    }
}

@end
