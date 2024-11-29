//
//  MjpegUtil.h
//  mjpeg
//
//  Created by 叩问九天 on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^Result) (UIImage *image);

@interface MjpegUtil : NSObject

- (void)receiveData:(NSData *)data image:(Result)image;


@end

NS_ASSUME_NONNULL_END
