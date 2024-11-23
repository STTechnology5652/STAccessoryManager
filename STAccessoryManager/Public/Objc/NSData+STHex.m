//
//  NSData+STHex.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/23.
//

#import "NSData+STHex.h"

@implementation NSData (HexString)

- (NSString *)hexString {
    const unsigned char *dataBuffer = [self bytes];
    if (!dataBuffer) {
        return [NSString string]; // 如果数据为空，返回空字符串
    }

    NSMutableString *hexString = [NSMutableString stringWithCapacity:self.length * 2];
    
    // 遍历每个字节，并将其转换为十六进制字符串
    for (NSInteger i = 0; i < self.length; i++) {
        [hexString appendFormat:@"%02x", dataBuffer[i]]; // %02x 确保输出两个字符的十六进制值
    }
    
    return [hexString copy];
}

@end
