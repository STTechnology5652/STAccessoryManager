//
//  H264Decoder.m
//  H264
//
//  Created by Mr.Han on 2018/4/26.
//  Copyright © 2018年 Mr.Han. All rights reserved.
//

#import "H264Decoder.h"
#include <stdio.h>

#define H264OutputWidth 480
#define H264OutputHeight 640

//#define MJPegOutputWidth 960
//#define MJPegOutputHeight 1280

#define MJPegOutputWidth 1080
#define MJPegOutputHeight 1920


@interface H264Decoder()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}

@end




@implementation H264Decoder
#pragma mark - 🔴 自定义方法 🔻
#pragma mark 解码回调函数
static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration )
{
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
    
    H264Decoder *decoder = (__bridge H264Decoder *)decompressionOutputRefCon;
    
    if (decoder.delegate != nil)
    {
        [decoder.delegate displayDecodedFrame:pixelBuffer];
    }
}




#pragma mark  初始化 H264 解码器
- (BOOL)initH264Decoder
{
    if(_deocderSession)
    {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr)
    {
        // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        NSDictionary* destinationPixelBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                                           (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:H264OutputHeight],
                                                           (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:H264OutputWidth],
//                                                           (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:NO],
                                                           (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES]};
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL,
                                              (__bridge CFDictionaryRef)destinationPixelBufferAttributes,
                                              &callBackRecord,
                                              &_deocderSession);
        
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
        
        if (status == noErr)
        {
            return YES;
        } else
        {
            NSLog(@"❌ Init decoder session failed status= %d", (int)status);
            return NO;
        }
        
    } else
    {
        NSLog(@"❌ IOS8VT: reset decoder session failed status=%d", (int)status);
        
        return NO;
    }
}




#pragma mark 初始化 MJPEG 解码器
- (BOOL)initMJpegDecoder
{
    if(_deocderSession)
    {
        return YES;
    }
    
    //创建视频描叙信息，包括视频的宽，高和编码信息，这里我们使用MJPEG对应的编码类型kCMVideoCodecType_JPEG
    OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                     kCMVideoCodecType_JPEG,
                                                     MJPegOutputHeight,
                                                     MJPegOutputWidth,
                                                     NULL,
                                                     &_decoderFormatDescription);
    if(status == noErr)
    {
        //创建解码回调函数
        VTDecompressionOutputCallbackRecord callback;
        callback.decompressionOutputCallback = didDecompress;
        callback.decompressionOutputRefCon = (__bridge void *)self;
        
        //定义解码得到的图片像素格式
        NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],
                                                          (id)kCVPixelBufferOpenGLESCompatibilityKey,
                                                          [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                                          (id)kCVPixelBufferPixelFormatTypeKey,
                                                          nil];
        
        //创建session
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL,
                                              (__bridge CFDictionaryRef)destinationImageBufferAttributes,
                                              &callback,
                                              &_deocderSession);
        if (status == noErr)
        {
            return YES;
        } else
        {
            NSLog(@"❌ Init decoder session failed status= %d", (int)status);
            return NO;
        }
        
    } else
    {
        NSLog(@"❌ IOS8VT: greates format description failed status=%d", (int)status);
        
        return NO;
    }
}



#pragma mark 解码帧数据
- (CVPixelBufferRef)decode:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                          (void *)frame,
                                                          frameSize,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          frameSize,
                                                          FALSE,
                                                          &blockBuffer);
    if(status == kCMBlockBufferNoErr)
    {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {frameSize};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer)
        {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr)
            {
                NSLog(@"❌ IOS8VT: Invalid session, reset decoder session");
                
            } else if(decodeStatus == kVTVideoDecoderBadDataErr)
            {
                NSLog(@"❌ IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
                
            } else if(decodeStatus != noErr)
            {
                NSLog(@"❌ IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}




#pragma mark 解码 MJpeg 帧数据
- (void)decodeMjpeg:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    if ([self initMJpegDecoder])
    {
        [self decode:frame withSize:frameSize];
    }
}




#pragma mark 解码 H264 帧数据 (I, SPS, PPS, 其他帧 B/P)
- (void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    // 开始解码
    int nalu_type = (frame[4] & 0x1F);
    CVPixelBufferRef pixelBuffer = NULL;
    uint32_t nalSize = (uint32_t)(frameSize - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    frame[0] = *(pNalSize + 3);
    frame[1] = *(pNalSize + 2);
    frame[2] = *(pNalSize + 1);
    frame[3] = *(pNalSize);

    switch (nalu_type)
    {
        case 0x05: // 关键帧 I
        {
            if([self initH264Decoder])
            {
                pixelBuffer = [self decode:frame withSize:frameSize];
            }
            break;
        }
        case 0x07: // SPS
        {
            _spsSize = frameSize - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, &frame[4], _spsSize);
            break;
        }
        case 0x08: // PPS
        {
            _ppsSize = frameSize - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);
            break;
        }
        default: // 其他帧 B/P
        {
            if([self initH264Decoder])
            {
                pixelBuffer = [self decode:frame withSize:frameSize];
            }
            break;
        }
    }
}




#pragma mark 重置解码器
- (void)resetDecoder
{
    _sps = nil;
    _spsSize = 0;
    _pps = nil;
    _ppsSize = 0;
    _deocderSession = nil;
    _decoderFormatDescription = nil;
}

@end

