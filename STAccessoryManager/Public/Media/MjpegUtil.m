//
//  MjpegUtil.m
//  mjpeg
//
//  Created by 叩问九天 on 2020/12/25.
//

#import "MjpegUtil.h"

//mjpeg开始标志
#define BEGIN_MARKER_BYTES { 0xFF, 0xD8 }
static NSData *_beginMarkerData = nil;

//mjpeg结束标志
#define END_MARKER_BYTES { 0xFF, 0xD9 }
static NSData *_endMarkerData = nil;

//一个或者多个量化表DQT(difine quantization table)
#define DQT_MARKER_BYTES { 0xFF, 0xDB }
static NSData *_dqtMarkerData = nil;

//一个或者多个霍夫曼表DHT(Difine Huffman Table)
#define DHT_MARKER_BYTES { 0xFF, 0xC4 }
static NSData *_dhtMarkerData = nil;

@interface MjpegUtil ()

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation MjpegUtil

- (instancetype)init {
    self = [super init];
    if (self)
    {
        if (_endMarkerData == nil)
        {
            uint8_t endMarker[2] = END_MARKER_BYTES;
            _endMarkerData = [[NSData alloc] initWithBytes:endMarker length:2];
        }
        if(_beginMarkerData == nil)
        {
            uint8_t endMarker[2] = BEGIN_MARKER_BYTES;
            _beginMarkerData = [[NSData alloc] initWithBytes:endMarker length:2];
        }
        if (_dqtMarkerData == nil) {
            uint8_t dqtMarker[2] = DQT_MARKER_BYTES;
            _dqtMarkerData = [[NSData alloc] initWithBytes:dqtMarker length:2];
        }
        if (_dhtMarkerData == nil) {
            uint8_t dhtMarker[2] = DHT_MARKER_BYTES;
            _dhtMarkerData = [[NSData alloc] initWithBytes:dhtMarker length:2];
        }
        
        self.receivedData = [NSMutableData data];
    }
    
    return self;
}

- (void)receiveData:(NSData *)data image:(Result)image;
{
    [self.receivedData appendData:data];
    NSRange beginRange = [_receivedData rangeOfData:_beginMarkerData
                                            options:0
                                              range:NSMakeRange(0, _receivedData.length)];
    if (beginRange.location == NSNotFound) {
        return;
    }
    NSRange endRange = [_receivedData rangeOfData:_endMarkerData
                                          options:NSDataSearchBackwards
                                            range:NSMakeRange(beginRange.location+beginRange.length, _receivedData.length - (beginRange.location+beginRange.length))];
    
    
    if(endRange.location == NSNotFound){
        return;
    }
    NSRange dqtRange = [_receivedData rangeOfData:_dqtMarkerData options:0 range:NSMakeRange(beginRange.location+beginRange.length, _receivedData.length - (beginRange.location+beginRange.length))];
    if (dqtRange.location == NSNotFound) {
        return;
    }
    
    NSRange dhtRange = [_receivedData rangeOfData:_dhtMarkerData options:0 range:NSMakeRange(beginRange.location+beginRange.length, _receivedData.length - (beginRange.location+beginRange.length))];
    if (dhtRange.location == NSNotFound) {
        return;
    }
    
    long endLocation = endRange.location + endRange.length;
    
    if (_receivedData.length >= endLocation){
        NSData *imageData = [_receivedData subdataWithRange:NSMakeRange(beginRange.location, endLocation-beginRange.location)];
        
        UIImage *receivedImage = [UIImage imageWithData:imageData.copy];
        
        if (receivedImage)
        {
            if (image)
            {
                image(receivedImage);
            }
            
            [_receivedData replaceBytesInRange:NSMakeRange(0, endLocation) withBytes:NULL length:0];
            UIImageWriteToSavedPhotosAlbum(receivedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        } else {
            //解析图失败， 也需要释放内存
            [_receivedData replaceBytesInRange:NSMakeRange(0, endLocation) withBytes:NULL length:0];
        }
       

        
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
      NSLog(@"保存失败");
   }
   else  {
      NSLog(@"保存成功");
   }
}

@end
