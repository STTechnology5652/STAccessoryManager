//
//  STAResponse.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

#import <Foundation/Foundation.h>
#import "STAResponseTypes.h"
#import "STAResHeadererilizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface STAResponse : NSObject

@property (nonatomic, assign) STRAnalysisResult analysisStatus;
@property (nonatomic, strong) STAResHeader *resHeader;
@property (nonatomic, strong) NSData *responseContent;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, assign) NSUInteger usedLength;
@property (nonatomic, copy) NSString *des;

- (instancetype)init;
- (NSDictionary *)jsonDict;
- (NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
