//
//  STAResHeadererilizer.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/23.
//

#import <Foundation/Foundation.h>
#import "STAResponseTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface STAResHeader: NSObject
@property(nonatomic, assign) UInt8 cmdId;
@property(nonatomic, assign) UInt8 cmdStatus;
@property(nonatomic, assign) UInt8 cmdTag;
@property(nonatomic, assign) UInt32 cmdDataLen;
@property(nonatomic, strong) NSData *responseContent;

@property(nonatomic, assign) UInt8 cmdEOH;
@property(nonatomic, assign) UInt8 cmdERR;
@property(nonatomic, assign) UInt8 cmdSTI;
@property(nonatomic, assign) UInt8 cmdRES;
@property(nonatomic, assign) UInt8 cmdSCR;
@property(nonatomic, assign) UInt8 cmdPTS;
@property(nonatomic, assign) UInt8 cmdEOF;
@property(nonatomic, assign) UInt8 cmdFID;

@property(nonatomic, assign) UInt32 imageDataLen;

@property(nonatomic, assign) UInt8 b2;
@property(nonatomic, assign) UInt8 b3;
@property(nonatomic, assign) UInt8 b4;
@property(nonatomic, assign) UInt8 b5;
@property(nonatomic, assign) UInt8 headerLen;

- (UInt8) resCmdStatus;
- (NSDictionary *)headerDict;
- (NSString *)headerJsonString;
- (NSUInteger)headerSorted:(unsigned char *)byt len:(NSUInteger)len;
@end


@interface STAResHeadererilizer : NSObject

@end

NS_ASSUME_NONNULL_END
