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

@implementation STAResponse

#define STLogDebug_file_resp(format, ...) STLogDebug_file(@"[kTag_STAResponse] "format, ##__VA_ARGS__)
#define STLogDebug_resp(format, ...) STLogDebug(@"[kTag_STAResponse] "format, ##__VA_ARGS__)

const NSString *kTag_cmdRes = @"kTag_STAResponse";
- (instancetype)init {
    if (self = [super init]) { //初始化， 给对象属性赋值，防止属性空值
        self.des = @"";
        self.resHeader = [STAResHeader new];
    }
    return self;
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
        @"responseData" : self.responseContent.hexString ?: @"",
        @"imageData" : self.imageData.hexString ?:@"",
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
