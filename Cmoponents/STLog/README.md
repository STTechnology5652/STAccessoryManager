# STLog

[![CI Status](https://img.shields.io/travis/coder/STLog.svg?style=flat)](https://travis-ci.org/coder/STLog)
[![Version](https://img.shields.io/cocoapods/v/STLog.svg?style=flat)](https://cocoapods.org/pods/STLog)
[![License](https://img.shields.io/cocoapods/l/STLog.svg?style=flat)](https://github.com/coder/STLog/blob/701ff106db3caa805f9dab12df7749c03c889c47/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/STLog.svg?style=flat)](https://cocoapods.org/pods/STLog)

## 摘要

STLog 组件主要用于：

- 1 格式化日志输出

## 用法

### 集成

pod 'STLog', '~> 1.0.0'

## 调用

### 引用

- objc

  ```objc
  #import <STLog/STLog.h>
  ```

- swift

  ```swift
  import STLog
  ```

### 调用接口

- objc

  ```objc
  STLogDebug(@"TEST - OC");
  ```

  效果:
  ```log
  [D][2023-10-17 11:02:38.843 +0800][STLogTest.m :13][+[STLogTest load]] TEST - OC

  ```

- swift

  ```swift
  STLog.debug("Test")
  ```

  效果:
  ```log
  [D][2023-10-17 18:02:39.704 +0800][ViewController.swift :23][initData()] date:2024-11-17 18:02:39.704 +0800
  ```

## 历史版本

- [0.0.1](https://github.com/STTechnology5652/STLog/tag/0.0.1)

  - 初始化版本
  - 提供： 日志输出功能
