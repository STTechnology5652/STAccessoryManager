//
//  STLogTool.m
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/15.
//

#import "STLogTool.h"

#import <STLog/STLog-Swift.h>

@implementation STLogTool
+ (void)logExecuteFile:(const char *)file function: (const char *)function line: (NSUInteger)line level: (NSString *)level des:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6) {
    va_list args;
    NSString *content = nil;
    NSString *fileStr = [[NSString stringWithCString:file encoding:NSUTF8StringEncoding] lastPathComponent];
    va_start(args, format);
    content = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSString* des = [NSString stringWithFormat:@"[%@][%@][%@ :%lu][%s] %@", level, STLog.dateStr, fileStr, line, function, content];
    [STLog consoleWithStr:des justToFile:NO];
}

+ (void)logExecuteJustToLogFile_file:(const char *)file function: (const char *)function line: (NSUInteger)line level: (NSString *)level des:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6) {
    va_list args;
    NSString *content = nil;
    NSString *fileStr = [[NSString stringWithCString:file encoding:NSUTF8StringEncoding] lastPathComponent];
    va_start(args, format);
    content = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSString* des = [NSString stringWithFormat:@"[%@][%@][%@ :%lu][%s] %@", level, STLog.dateStr, fileStr, line, function, content];
    [STLog consoleWithStr:des justToFile:YES];
}
@end
