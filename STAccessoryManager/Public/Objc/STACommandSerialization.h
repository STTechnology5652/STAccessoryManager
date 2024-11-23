//
//  STACommandserialization.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(unsigned char, STRACmdId) {
    STRACmdId_SetStreamOnOff = 0x01,
    STRACmdId_GetDeviceConfig,
    STRACmdId_SetStreamSetting,
    STRACmdId_GetPropertyPageInfo,
    STRACmdId_GetPropertyValueOrMode,
    STRACmdId_SetPropertyValueOrMode,
};

@interface STACommandserialization : NSObject
+ (NSData *)getDevConfig: (UInt8) tag;
+ (NSData *)openStreamCmdWithTag: (UInt8) tag open:(UInt8)open;
+ (NSData *)createCmdWithTag:(UInt8)tag cmdId:(STRACmdId)cmdId dir:(UInt8)scr cmdData:(NSData *)cmdData;
@end

NS_ASSUME_NONNULL_END
