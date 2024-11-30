//
//  STARespDevConfigSerilizer.h
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STARespDevConfigSerilizer;

@interface STARespDevConfig : NSObject<STARespDevConfigSerilizer>
@property(nonatomic, readonly, assign) UInt16 formatID;
@property(nonatomic, readonly, assign) UInt16 resolutionID;
@property(nonatomic, readonly, assign) UInt16 imageWidth;
@property(nonatomic, readonly, assign) UInt16 imageHeight;
@property(nonatomic, readonly, assign) UInt64 fps;

- (NSDictionary*)jsonDict;
- (NSString*)jsonString;
@end


@protocol STARespDevConfigSerilizer<NSObject>
+ (NSArray<STARespDevConfig*> *) analysisConfigData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
