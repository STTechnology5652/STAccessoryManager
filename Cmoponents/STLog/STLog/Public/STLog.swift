//  STALog.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/15.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

import Foundation

public typealias STLogLevel = String

public extension STLogLevel {
    static let debug = "D"
    static let info = "I"
    static let warning = "W"
    static let error = "E"
    static let fatal = "F"
}

public class STLog: NSObject {
    public static func debug(tag: String = "", justLogFile: Bool = false, _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .debug, line: line, file: file, function: function, tag: tag, justLogFile: justLogFile, items: items, separator: separator, terminator: terminator)
    }
    
    public static func info(tag: String = "", justLogFile: Bool = false, _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .info, line: line, file: file, function: function, tag: tag, justLogFile: justLogFile, items: items, separator: separator, terminator: terminator)
    }
    
    public static func warning(tag: String = "", justLogFile: Bool = false, _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .warning, line: line, file: file, function: function, tag: tag, justLogFile: justLogFile, items: items, separator: separator, terminator: terminator)
    }
    
    public static func err(tag: String = "", justLogFile: Bool = false, _ items: Any..., separator: String = " ", terminator: String = "\n",line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .error, line: line, file: file, function: function, tag: tag, justLogFile: justLogFile, items: items, separator: separator, terminator: terminator)
    }
    
    public static func fatal(tag: String = "", justLogFile: Bool = false, _ items: Any..., separator: String = " ", terminator: String = "\n",line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .fatal, line: line, file: file, function: function, tag: tag, justLogFile: justLogFile, items: items, separator: separator, terminator: terminator)
    }
    
    @objc
    public static func console(str: String = "", justToFile: Bool) {
        if str.count > 0 {
            if justToFile == false {
                print(str)
            }
            STlogFileManager.share.writeLog(str)
        }
    }
    
    private static let df: DateFormatter = {
        let dateF = DateFormatter()
        dateF.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS Z"
        return dateF
    }()
    
    @objc public static func dateStr() -> String {
        return df.string(from: Date())
    }
    
    public static func e(level: STLogLevel, line: Int, file: String, function: String, tag: String = "", justLogFile: Bool = false, items: Any..., separator: String = " ", terminator: String = "\n") {
        let df = DateFormatter()
        let str = "[\(level)][\(dateStr())][\((file as NSString).lastPathComponent) :\(line)][\(function)]\(tag.count > 0 ? "[\(tag)]" : "") \(items.map { "\($0)" }.joined(separator: separator))"
        if justLogFile {
             console(str: str, justToFile: false) //忽略大日志， 提升调试速率
        } else {
            console(str: str, justToFile: justLogFile)
        }
    }
}

extension STLog {
    public static func openFileLog(_ openWriteLog: Bool) {
        STlogFileManager.share.openFileLog(openWriteLog)
    }
    
    public static func configLogFileDir(_ path: String = NSTemporaryDirectory()) -> Bool {
        return STlogFileManager.share.configLogDir(path)
    }
}
