//
//  STAResponse.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

#import <Foundation/Foundation.h>

#import "STAResHeadererilizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface STAResponse : NSObject
@property(nonatomic, readonly, assign) STRAnalysisResult analysisStatus;
@property(nonatomic, readonly, strong) STAResHeader *resHeader;
@property(nonatomic, readonly, assign) NSUInteger usedLength;
@property(nonatomic, readonly, strong) NSString *des;

@property(nonatomic, readonly, strong) NSData *responseData;
@property(nonatomic, readonly, strong) NSData *imageData;

- (NSDictionary *)jsonDict;
- (NSString *)jsonString;

+ (NSArray<STAResponse*> *)analysisiBuffer:(NSData *)data byteUsed:(UInt64 *)byteUsed;
@end

NS_ASSUME_NONNULL_END
