#import <Foundation/Foundation.h>
#import "STAResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface STAProtocolParserBridge : NSObject

+ (NSArray<STAResponse *> *)parseBuffer:(NSData *)buffer bytesUsed:(uint64_t *)bytesUsed;

@end

NS_ASSUME_NONNULL_END 