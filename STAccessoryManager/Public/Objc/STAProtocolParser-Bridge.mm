#import "STAProtocolParser-Bridge.h"
#import "STAProtocolParser.h"
#import <STLog/STLogTool.h>

@implementation STAProtocolParserBridge

+ (NSArray<STAResponse *> *)parseBuffer:(NSData *)buffer bytesUsed:(uint64_t *)bytesUsed {
    uint64_t used = 0;
    std::vector<STA::Response> responses = STA::ProtocolParser::parseBuffer(
        (const uint8_t*)buffer.bytes, 
        buffer.length, 
        used
    );
    
    *bytesUsed = used;
    
    NSMutableArray<STAResponse *> *result = [NSMutableArray arrayWithCapacity:responses.size()];
    
    for (const auto& response : responses) {
        STAResponse *staResponse = [[STAResponse alloc] init];
        
        // 设置头部信息
        staResponse.resHeader.cmdId = response.header.cmdId;
        staResponse.resHeader.cmdStatus = response.header.cmdStatus;
        staResponse.resHeader.cmdTag = response.header.cmdTag;
        staResponse.resHeader.cmdDataLen = response.header.cmdDataLen;
        staResponse.resHeader.imageDataLen = response.header.imageDataLen;
        
        // 设置响应内容
        if (!response.responseContent.empty()) {
            staResponse.responseContent = [NSData dataWithBytes:response.responseContent.data() 
                                                      length:response.responseContent.size()];
        }
        
        // 设置图像数据
        if (!response.imageData.empty()) {
            staResponse.imageData = [NSData dataWithBytes:response.imageData.data() 
                                                length:response.imageData.size()];
        }
        
        // 设置其他属性
        staResponse.analysisStatus = STRAnalysisResult_success; // 如果能解析到这里，说明成功了
        staResponse.usedLength = response.header.headerLen + 
                               response.responseContent.size() + 
                               response.imageData.size();
        staResponse.des = @"Parsed successfully";
        
//        STLogDebug(@"one response:%@", staResponse.jsonString);
        [result addObject:staResponse];
    }
    
    return result;
}

@end 
