//
//  H264Encoder.m
//  H264
//
//  Created by Mr.Han on 2018/4/26.
//  Copyright © 2018年 Mr.Han. All rights reserved.
//

#import "H264Encoder.h"
@import VideoToolbox;
@import AVFoundation;

@implementation H264Encoder
{
    NSString *yuvFile;
    VTCompressionSessionRef EncodingSession;
    dispatch_queue_t aQueue;
    CMFormatDescriptionRef format;
    CMSampleTimingInfo * timingInfo;
    int frameCount;
    NSData *sps;
    NSData *pps;
}



- (void)initWithConfiguration
{
    EncodingSession = nil;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    frameCount = 0;
    sps = NULL;
    pps = NULL;
}



void didCompressH264(void *outputCallbackRefCon,
                     void *sourceFrameRefCon,
                     OSStatus status,
                     VTEncodeInfoFlags infoFlags,
                     CMSampleBufferRef sampleBuffer)
{
    if (status != 0) return;
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    H264Encoder* encoder = (__bridge H264Encoder*)outputCallbackRefCon;
    
    bool keyframe = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        
        if (statusCode == noErr)
        {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            
            if (statusCode == noErr)
            {
                encoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                encoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder->_delegate)
                {
                    [encoder->_delegate gotSpsPps:encoder->sps pps:encoder->pps];
                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    
    if (statusCodeRet == noErr)
    {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        
        while (bufferOffset < totalLength - AVCCHeaderLength)
        {
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder->_delegate gotEncodedData:data isKeyFrame:keyframe];
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}


- (void)initEncode:(int)width height:(int)height
{
    dispatch_sync(aQueue, ^{
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self),  &self->EncodingSession);
        if (status != 0)
        {
            NSLog(@"Error by VTCompressionSessionCreate  ");
            return ;
        }
        
        VTSessionSetProperty(self->EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(self->EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_4_1);
        
        SInt32 bitRate = width*height*50;  //越高效果越屌  帧数据越大
        CFNumberRef ref = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(self->EncodingSession, kVTCompressionPropertyKey_AverageBitRate, ref);
        CFRelease(ref);
        
        int frameInterval = 10; //关键帧间隔 越低效果越屌 帧数据越大
        CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(self->EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval,frameIntervalRef);
        CFRelease(frameIntervalRef);
        VTCompressionSessionPrepareToEncodeFrames(self->EncodingSession);
    });
}




- (void) encode:(CMSampleBufferRef)sampleBuffer
{
    if (EncodingSession == nil||EncodingSession == NULL)
    {
        return;
    }
    
    dispatch_sync(aQueue, ^{
        self->frameCount ++;
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CMTime presentationTimeStamp = CMTimeMake(self->frameCount, 1000);
        VTEncodeInfoFlags flags;
        OSStatus statusCode = VTCompressionSessionEncodeFrame(self->EncodingSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              kCMTimeInvalid,
                                                              NULL, NULL, &flags);
        if (statusCode != noErr)
        {
            if (self->EncodingSession != nil||self->EncodingSession != NULL)
            {
                VTCompressionSessionInvalidate(self->EncodingSession);
                CFRelease(self->EncodingSession);
                self->EncodingSession = NULL;
                return;
            }
        }
    });
}
@end

