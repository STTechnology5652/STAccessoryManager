//
//  STAResponse.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

#import "STAResponse.h"
#import "STACommandSerialization.h"

#import "NSData+STHex.h"

#import <STLog/STLogTool.h>

@interface STAResponse()
@property(nonatomic, assign) STRAnalysisResult analysisStatus;
@property(nonatomic, strong) STAResHeader *resHeader;
@property(nonatomic, assign) NSUInteger usedLength;
@property(nonatomic, copy) NSString *des;

@property(nonatomic, copy) NSData *responseData;
@property(nonatomic, copy) NSData *imageData;

@end

@implementation STAResponse

#define STLogDebug_file_resp(format, ...) STLogDebug_file(@"[kTag_STAResponse] "format, ##__VA_ARGS__)
#define STLogDebug_resp(format, ...) STLogDebug(@"[kTag_STAResponse] "format, ##__VA_ARGS__)

const NSString *kTag_cmdRes = @"kTag_STAResponse";
- (instancetype)init {
    if (self = [super init]) { //初始化， 给对象属性赋值，防止属性空值
        self.resHeader = [STAResHeader new];
        self.responseData = [NSData new];
        self.des = @"";
    }
    return self;
}

+ (NSArray<STAResponse *> *)new_analysisiBuffer:(NSData *)data byteUsed:(nonnull UInt64 *)byteUsed {
    NSThread *curThread = [NSThread currentThread];
    NSDate *startDate = [NSDate date];
    NSString *taskId = [NSUUID UUID].UUIDString;
    NSUInteger len= data.length;
    UInt8 *byt = data.bytes;
    NSUInteger offset = 0;
    NSUInteger taskNum = 0;
    NSUInteger useFullLen = 0;
    
    NSMutableArray<STAResponse *> *result = [NSMutableArray new];
    
    STAResponse *preRes = nil;
    @autoreleasepool {
        STLogDebug_resp(@"analysis_start[%@] len_to_analysis:[%lu]", taskId, data.length);
        STLogDebug_file_resp(@"analysis_start[%@] len_to_analysis:%lu byts:%@", taskId, data.length, data.hexString);
        
        while (offset < len) {
            taskNum ++;
            NSUInteger usedLen = 0;
            STAResponse *oneRes = [self analysisOnece:byt + offset len:len - offset usedLen:&usedLen taskId:taskId taskNum:taskNum];
            offset += usedLen;
            if (oneRes != nil && oneRes.analysisStatus == STRAnalysisResult_success ) { //解析失败, 继续下一段报文
                useFullLen += oneRes.usedLength;
                [result addObject:oneRes];
            }
        }
        
        
        NSTimeInterval timeUsed = [[NSDate date] timeIntervalSinceDate:startDate];
        STLogDebug_resp(@"analysis_finish[%@][%.05fs] len_usefull:%lu oriLen:[%lu] usefullResCount:%lu thread: %@", taskId, timeUsed, useFullLen, len, result.count, curThread);
    }
    
    *byteUsed = offset;
    return result;
}

+ (STAResponse * _Nullable) analysisOnece:(UInt8 *)byt len:(NSUInteger)len usedLen:(NSUInteger *)usedLen taskId:(NSString *)taskId taskNum:(NSUInteger)taskNum {
    // 尝试解析一个报文包
    NSUInteger offset = 0;
    
    NSData* debugData = [NSData dataWithBytes:byt length:len];
    STLogDebug_resp(@"analysis_start_onece[%@](num:%lu) len_to_analysis:%lu", taskId, taskNum, len);
    STLogDebug_file_resp(@"analysis_start_onece[%@](num:%lu) len_to_analysis[%lu]:%@", taskId, taskNum, len, debugData);
    if (len < 0x0c) { //不够 0x0c 字节
        STLogDebug_resp(@"analysis_finish_onece[%@](num:%lu) failed byte not enough", taskId, taskNum);
        STLogDebug_file_resp(@"analysis_finish_onece[%@](num:%lu) failed byte not enough:%@", taskId, taskNum, debugData);
        *usedLen = len;
        return nil;
    }
    
    if (byt[offset] != 0x0c) { //首字节不是 0xOC
        STLogDebug_resp(@"analysis_finish_onece[%@](num:%lu) failed B0 error[%02x]", taskId, taskNum, byt[offset]);
        STLogDebug_file_resp(@"analysis_finish_onece[%@](num:%lu) failed B0 error[%02x]:%@", taskId, taskNum, byt[offset], debugData);
        offset ++;
        *usedLen = offset;
        return nil;
    }
    
    STAResponse *result = [STAResponse new];
    STAResHeader *header = result.resHeader;
    NSUInteger headerLen = [header headerSorted:byt len:len];
    offset += headerLen;
    if (header.cmdDataLen > 0 ) { // 有 data域
        if (offset + header.cmdDataLen > len){ // data 域 数据不足
            *usedLen = len;
            result.analysisStatus = STRAnalysisResult_dataNotEnough;
            STLogDebug_resp(@"analysis_finish_onece[%@](num:%lu) failed cmdDataNotEnough:%lu -->%lu resInfo: %@", taskId, taskNum, len, header.cmdDataLen, result.jsonString);
            STLogDebug_file_resp(@"analysis_finish_onece[%@](num:%lu) failed cmdDataNotEnough:%@ resInfo: %@", taskId, taskNum, debugData, result.jsonString);
            return nil;
        }
        
        result.responseData = [NSData dataWithBytes:byt + offset length:header.cmdDataLen];
        offset += header.cmdDataLen;
    }
    
    if (header.imageDataLen > 0) { // 有 image 域
        if (offset + header.imageDataLen > len) { // image 域 数据不足
            *usedLen = len;
            result.analysisStatus = STRAnalysisResult_dataNotEnough;
            STLogDebug_resp(@"analysis_finish_onece[%@](num:%lu) failed imageDataNotEnough:%lu --> %lu resInfo: %@", taskId, taskNum, len, header.imageDataLen, result.jsonString);
            STLogDebug_file_resp(@"analysis_finish_onece[%@](num:%lu) failed imageDataNotEnough:%@ resInfo: %@", taskId, taskNum, debugData, result.jsonString);
            return nil;
        }
        result.imageData = [NSData dataWithBytes:byt + offset length:header.imageDataLen];
        offset += header.imageDataLen;
    }
    
    result.analysisStatus = STRAnalysisResult_success;
    result.usedLength = offset;
    *usedLen = offset;
    STLogDebug_resp(@"analysis_finish_onece[%@](num:%lu) len_to_analysis:%lu usedLen:%lu resInfo:%@", taskId, taskNum, len, offset, [result jsonString]);
    return result;
}



+ (NSArray<STAResponse*> *)analysisiBuffer:(NSData *)data byteUsed:(UInt64 *)byteUsed {
    return [self new_analysisiBuffer:data byteUsed:byteUsed];
}

@end

@interface STAResponse(json)
@end
@implementation STAResponse(json)

- (NSDictionary *)jsonDict {
    NSDictionary *map = @{
        @"analysisStatus" : @(self.analysisStatus),
        @"resHeader" : [self.resHeader headerDict],
        @"usedLength" : @(self.usedLength),
        @"des" : self.des,
        @"responseData" : [NSString stringWithFormat:@"%@", self.responseData],
        @"imageData" : [NSString stringWithFormat:@"%@", self.imageData],
    };
    
    return map;
}

- (NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self jsonDict] options:0 error:&error];
    if (error) {
        STLogWarning(@"[%@] Error converting dictionary to JSON: %@", kTag_cmdRes, error.localizedDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}
@end
