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

const NSString *kTag_cmdRes = @"kTag_STAResponse";
- (instancetype)init {
    if (self = [super init]) { //初始化， 给对象属性赋值，防止属性空值
        self.resHeader = [STAResHeader new];
        self.responseData = [NSData new];
        self.des = @"";
    }
    return self;
}

+ (NSArray<STAResponse*> *)analysisiBuffer:(NSData *)data byteUsed:(UInt64 *)byteUsed {
    /*
     1. 解析 前 1024 个字节， 寻找到第一个完整的 报文头
     2. 从报文头的第一个字节，开始解析一个完整包
     3. 记录当前已经解析的字节数
     4. 返回 一个报文对象数组
     */
    
    NSMutableArray<STAResponse *> * result = [NSMutableArray new];
    if (data.length < 12) {
        *byteUsed = 0;
        return result;
    }
    
    NSDate *startDate = [NSDate now];
    STLogInfo(@"[%@] start analysis cmd response data[%lu]", kTag_cmdRes, data.length, data);
    STLogDebug_file(@"[%@] start analysis cmd response data[%lu]: %@", kTag_cmdRes, data.length, [data hexString]);
    NSUInteger offset = 0;
    UInt8 *byt = data.bytes;
    NSUInteger len = data.length;
    for (; offset < len; ) {
        STAResponse *oneRes = [self analysisCmdResBytes:byt + offset len:len - offset];
        
        if (oneRes.analysisStatus == STRAnalysisResult_success) {
            [result addObject:oneRes];
            offset += oneRes.usedLength;
            STLogDebug(@"[%@] store one cmd response usedByt[%lu]: %@", kTag_cmdRes, oneRes.usedLength, oneRes);
            continue;
        } else if (oneRes.analysisStatus == STRAnalysisResult_dataNotEnough) { //数据长度不够了
//            offset ++; //此处是为了和下文的 offset-- 对应上， 防止字节多偏移
            STLogDebug(@"[%@] skip one cmd response, since has not more data: %@", kTag_cmdRes, oneRes);
            break;
        } else if (oneRes.analysisStatus == STRAnalysisResult_failed) { // 遇到一个错误的报文， 忽略这段字节， 继续解析
            offset += oneRes.usedLength;
            STLogDebug(@"[%@] skip one cmd response, since is error usedByte[%lu]: %@", kTag_cmdRes, oneRes.usedLength, oneRes);
            continue;
        }
    }
    
    *byteUsed = offset;
    
    NSDate *finishDate = [NSDate now];
    STLogInfo(@"[%@] finish analysis cmd response, used bytes[%lu], time[%g] count[%lu]: %@", kTag_cmdRes, offset, [finishDate timeIntervalSinceDate:startDate], result.count, result);
    return result;
}

+ (instancetype)analysisCmdResBytes:(UInt8 *)byt len:(NSInteger)len {
    STAResponse *result = [STAResponse new];
   
    if (len < 0x0c) {
        result.usedLength = 0;
        result.analysisStatus = STRAnalysisResult_dataNotEnough;
        return result;
    }
    
    /*
     解包步骤：
     1. 取 0 - 12 字节
     2. 逐个字节解析
     3. 如果解析失败， 取 1 - 13 字节 再次尝试
     4. 依次类推， 解析 15次， 如果都不对， 则让buffer抛弃前 15 个字节。
     */
    
    NSUInteger offset = 0;
    for (; offset <= len - 0x0C; offset ++) {
        [result analysisByt:byt + offset len:len - offset];
        if (result.analysisStatus == STRAnalysisResult_success) { //解析成功
            result.usedLength = result.resHeader.headerLen + result.resHeader.cmdDataLen + result.resHeader.imageDataLen;
            break;
        }
        
        if (result.analysisStatus == STRAnalysisResult_dataNotEnough) { // 数据不够， 忽略此次解析
            result.usedLength = 0;
            break;
        }
    }
    
    
    NSData *usedData = [NSData dataWithBytes:byt length:result.usedLength < len ? result.usedLength : len];
    STLogDebug_file(@"[%@] one cmd response used[%lu]: %@", kTag_cmdRes, result.usedLength, [usedData hexString]);
    STLogInfo(@"[%@] one cmd response used[%lu] [%@]: %@", kTag_cmdRes, result.usedLength, self, usedData);
    STLogDebug(@"[%@] analysisi cmd response result[%lu]: %@", kTag_cmdRes, result.usedLength, result.jsonString);
    return result;
}

- (void) analysisByt: (unsigned char *)byt len:(NSUInteger)len {
    if (len < 12 || byt == NULL) { //报文长度不足12 或者 没有字节可以解析
        self.analysisStatus = STRAnalysisResult_dataNotEnough; //剩余报文不够， 需要忽略此次解析, 外层需要重新传入 byt 和 len， 开启下一次解析
        self.usedLength = 0;
        STLogErr(@"[%@] analysisi cmd error, data not enough: %@", kTag_cmdRes, [NSData dataWithBytes:byt length:len]);
        return;
    }
    
    [self analysisHeaderBytes:byt len:len];
}


- (void)analysisHeaderBytes:(unsigned char *)byt len:(NSUInteger)len {
    if (len > 0 && byt[0] != 0x0c) {
        self.usedLength = 1;
        self.analysisStatus = STRAnalysisResult_failed;
        STLogErr(@"[%@] analysisi cmd error, header error: %@", kTag_cmdRes, [NSData dataWithBytes:byt length:len]);
        return;
    }
    
    STAResHeader *header = self.resHeader;
    NSUInteger headerLen = [header headerSorted:byt len:len];
    NSUInteger offSet = header.headerLen;
    NSUInteger usedLen = headerLen + header.cmdDataLen + header.imageDataLen;
    if (usedLen > len) { //单包报文 数据不够， 需要忽略，等待报文足够的时候再解析
        self.analysisStatus = STRAnalysisResult_dataNotEnough;
        self.usedLength = 0;
        return;
    }
    
    if (offSet <= len) { // 指令应答的 response data 域
        self.responseData = [NSData dataWithBytes: byt + offSet length:header.cmdDataLen];
    }
    
    offSet += header.cmdDataLen;
    if (offSet <= len) { // 指令应答的 image data域
        self.imageData = [NSData dataWithBytes: byt + offSet length:header.imageDataLen];
    }
    
    self.analysisStatus = STRAnalysisResult_success;
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
