//
//  H264Encoder.h
//  H264
//
//  Created by Mr.Han on 2018/4/26.
//  Copyright © 2018年 Mr.Han. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;



@protocol H264EncoderDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end


// 编码
@interface H264Encoder : NSObject

@property (weak, nonatomic) id<H264EncoderDelegate> delegate;

- (void) initWithConfiguration;
- (void) initEncode:(int)width  height:(int)height;
- (void) encode:(CMSampleBufferRef )sampleBuffer;

@end
