//
//  STARespDevConfigSerilizer.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/30.
//

#import "STARespDevConfigSerilizer.h"
#import <STLog/STLogTool.h>

#import "NSData+STHex.h"

@interface STARespDevConfig ()
@property(nonatomic, assign) UInt16 formatID;
@property(nonatomic, assign) UInt16 resolutionID;
@property(nonatomic, assign) UInt16 imageWidth;
@property(nonatomic, assign) UInt16 imageHeight;
@property(nonatomic, assign) UInt64 fps;
@end

@implementation STARespDevConfig
+ (NSArray<STARespDevConfig*> *) analysisConfigData:(NSData *)data {
    STLogDebug(@"start analysis devconfig:%@", data.hexString);
    NSMutableArray<STARespDevConfig*> *result = [NSMutableArray new];
    /*
     | Format ID          | Res ID        | Width       | Height       | FPS              |
     | :----------------- | :------------ | :---------- | :----------- | :--------------- |
     | B4                 | B5            | B6-B7       | B8-B9        | B10-B15          |
     | 0x01: YUV 0x02: MJ | Resolution ID | Image Width | Image Height | fps (6 settings) |
     */
    
    UInt8 *byt = data.bytes;
    NSUInteger len = data.length;
    UInt8 offset = 0;
    while (offset < len) {
        if (len - offset < 12) { //不够解析了
            break;
        }
        STLogDebug(@"start analysis devconfig once:%@", [NSData dataWithBytes:byt + offset length:12].hexString);

        STARespDevConfig *oneConfig = [STARespDevConfig new];
        oneConfig.formatID = byt[offset++];
        oneConfig.resolutionID = byt[offset++];
        oneConfig.imageWidth = byt[offset++] | (byt[offset++] << 8);
        oneConfig.imageHeight = byt[offset++] | (byt[offset++] << 8);
        oneConfig.fps = byt[offset++] | (byt[offset++] << 8)| (byt[offset++] << 16)| (byt[offset++] << 24)| (byt[offset++] << 32) | (byt[offset++] << 40);
        [result addObject:oneConfig];
    }
    
    return result;
}

- (NSDictionary *)jsonDict {
    NSDictionary *map = @{
        @"formatID" : @(self.formatID),
        @"resolutionID" : @(self.resolutionID),
        @"imageWidth" : @(self.imageWidth),
        @"imageHeight" : @(self.imageHeight),
        @"fps" : @(self.fps),
        
        @"formatID_hex" : [NSString stringWithFormat:@"%02x", self.formatID],
        @"resolutionID_hex" : [NSString stringWithFormat:@"%02x", self.resolutionID],
        @"imageWidth_hex" : [NSString stringWithFormat:@"%04x", self.imageWidth],
        @"imageHeight_hex" : [NSString stringWithFormat:@"%04x", self.imageHeight],
        @"fps_hex" : [NSString stringWithFormat:@"%010x", self.fps],
    };
    
    return map;
}

- (NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self jsonDict] options:0 error:&error];
    if (error) {
        STLogWarning(@"dev config json Error converting dictionary to JSON: %@", error.localizedDescription);
        return @"";
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}
@end
