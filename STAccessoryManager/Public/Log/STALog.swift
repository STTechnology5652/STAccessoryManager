//
//  STALog.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/15.
//

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
    public static func debug(tag: String = "", _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .debug, line: line, file: file, function: function, tag: tag, items: items, separator: separator, terminator: terminator)
    }
    
    public static func info(tag: String = "", _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .info, line: line, file: file, function: function, tag: tag, items: items, separator: separator, terminator: terminator)
    }
    
    public static func warning(tag: String = "", _ items: Any..., separator: String = " ", terminator: String = "\n", line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .warning, line: line, file: file, function: function, tag: tag, items: items, separator: separator, terminator: terminator)
    }
    
    public static func err(tag: String = "", _ items: Any..., separator: String = " ", terminator: String = "\n",line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .error, line: line, file: file, function: function, tag: tag, items: items, separator: separator, terminator: terminator)
    }
    
    public static func fatal(tag: String = "", _ items: Any..., separator: String = " ", terminator: String = "\n",line: Int = #line, file: String = #file, function: String = #function) {
        e(level: .fatal, line: line, file: file, function: function, tag: tag, items: items, separator: separator, terminator: terminator)
    }
    
    private static let df: DateFormatter = {
        let dateF = DateFormatter()
        dateF.dateFormat = "YYYY-mm-dd HH:mm:ss.SSS Z"
        return dateF
    }()
    
    @objc public static func dateStr() -> String {
        return df.string(from: Date())
    }
    
    public static func e(level: STLogLevel, line: Int, file: String, function: String, tag: String = "", items: Any..., separator: String = " ", terminator: String = "\n") {
        let df = DateFormatter()
        let str = "[\(level)][\(dateStr())][\((file as NSString).lastPathComponent) :\(line)][\(function)]\(tag.count > 0 ? "[\(tag)]" : "") \(items.map { "\($0)" }.joined(separator: separator))"
        print(str)
    }
}
