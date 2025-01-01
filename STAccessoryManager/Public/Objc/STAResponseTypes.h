#ifndef STAResponseTypes_h
#define STAResponseTypes_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, STRAnalysisResult) {
    STRAnalysisResult_failed = 0,
    STRAnalysisResult_dataNotEnough,
    STRAnalysisResult_success,
};

#endif /* STAResponseTypes_h */ 