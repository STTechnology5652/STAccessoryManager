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


+ (NSData *)dataFromHexString:(NSString *)hexString {
    // 移除所有非十六进制字符，如空格或换行
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    cleanString = [cleanString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    cleanString = [cleanString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    // 确保十六进制字符串的长度是偶数
    if (cleanString.length % 2 != 0) {
        return nil; // 如果字符串长度不是偶数，无法正确解析
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:cleanString.length / 2];
    
    for (NSInteger i = 0; i < cleanString.length; i += 2) {
        // 获取每对字符
        NSString *hexPair = [cleanString substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        
        // 将十六进制字符串转换为字节
        if ([[NSScanner scannerWithString:hexPair] scanHexInt:&byteValue]) {
            [data appendBytes:&byteValue length:1];
        } else {
            return nil; // 如果扫描失败，返回nil
        }
    }
    
    return data;
}

@end
