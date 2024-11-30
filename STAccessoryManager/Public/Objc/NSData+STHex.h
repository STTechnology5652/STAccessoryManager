//
//  NSData+STHex.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HexString)

/**
 * 将 NSData 转换为十六进制字符串
 */
- (NSString *)hexString;
+ (NSData *)dataFromHexString:(NSString *)hexString;
@end

NS_ASSUME_NONNULL_END
