//
//  STlogFileManager.swift
//  DoraemonKit
//
//  Created by stephenchen on 2024/11/23.
//

import Foundation

class STlogFileManager {
    private var fileDir: String = NSTemporaryDirectory()
    static let share = STlogFileManager().configDefault()
    
    private var logHandle: FileHandle?
    private var curLogPath: String?
    private var isAllowWriteLog: Bool = false
    
    private var currentLogFileName: String = "Default.log"
    private let logQueue = DispatchQueue(label: "STLogWriteQueue", qos: .background)
    
    private func configDefault() -> Self {
        if logHandle == nil {
            let date = Date()
            let df = DateFormatter()
            df.dateFormat = "YYYYMMdd_HHmmss_SS"
            let name = df.string(from: date) + ".log"
            logHandle = getLogFileHandler(name: name)
        }
        return self
    }
    
    func openFileLog(_ openWriteLog: Bool) {
        isAllowWriteLog = openWriteLog
        if openWriteLog {
            try? logHandle?.close()
            logHandle = nil
            checkLogHandle()
        } else {
            try? logHandle?.close()
            logHandle = nil
        }
    }
    
    func configLogDir(_ path: String) -> Bool {
        if createLogDir(dirPath: path) == true {
            fileDir = path
            return true
        }
        
        // 不能使用这个路径， 继续使用 默认路径
        fileDir = NSTemporaryDirectory()
        try? logHandle?.close()
        logHandle = nil
        
        return false
    }
    
    func writeLog(_ log: String) {
        guard isAllowWriteLog else {
            return
        }
        
        logQueue.async { [weak self] in
            guard let self else { return }
            if isAllowWriteLog == true, let data = (log + "\n").data(using: .utf8), let logHandle = self.logHandle  {
                logHandle.write(data)
            }
        }
    }
    
    private func checkLogHandle() -> FileHandle? {
        if let logHandle {
            if let curLogPath, FileManager.default.fileExists(atPath: curLogPath) == true {
                return logHandle
            } else { //关闭句柄， 重新创建log 文件
                try? logHandle.close()
                self.logHandle = nil
                configDefault()
                return logHandle
            }
        } else {
            configDefault()
            return logHandle
        }
    }
    
    private func createLogDir(dirPath: String) -> Bool {
        let dirPath = (dirPath as NSString).appendingPathComponent("STLog")
        let fm = FileManager.default
        if fm.fileExists(atPath: dirPath) == false {
            try? fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
        }
        
        return fm.fileExists(atPath: dirPath)
    }
    
    private func getLogFileHandler(name: String) -> FileHandle? {
        var logFileUrl = URL(fileURLWithPath: (fileDir as NSString).appendingPathComponent(name))
        logFileUrl.deletePathExtension()
        logFileUrl.appendPathExtension("log")
        
        let logPath = logFileUrl.path
        let fm = FileManager.default
        if fm.fileExists(atPath: logPath) == false {
            try? fm.createFile(atPath: logPath, contents: nil)
        }
        
        guard let fh = try? FileHandle.init(forWritingTo: logFileUrl) else {
            print("STLog create log file handle failed")
            return nil
        }
        
        fh.seekToEndOfFile()
        curLogPath = logFileUrl.path
        return fh
    }
}
