//
//  H264Decoder.h
//  H264
//
//  Created by Mr.Han on 2018/4/26.
//  Copyright © 2018年 Mr.Han. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVSampleBufferDisplayLayer.h>

@protocol H264DecoderDelegate <NSObject>

/**
 已经解码的帧数据
 
 @param imageBuffer CVImageBufferRef 数据
 */
- (void)displayDecodedFrame:(CVImageBufferRef)imageBuffer;

@end


/**
 🔆 解码器,  h264 OR  MJpeg
 */
@interface H264Decoder : NSObject


/**
 Delegate
 */
@property (weak, nonatomic) id<H264DecoderDelegate> delegate;




/**
 解码 H264 帧数据
 
 @param frame h264 帧数据
 @param frameSize h264 帧数据大小
 */
- (void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;




/**
解码 MJpeg 帧数据

@param frame MJpeg 帧数据
@param frameSize MJpeg 帧数据大小
*/
- (void)decodeMjpeg:(uint8_t *)frame withSize:(uint32_t)frameSize;

@end
