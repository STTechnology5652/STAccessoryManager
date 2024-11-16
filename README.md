# STAccessoryManager

[![Version](https://img.shields.io/cocoapods/v/STAccessoryManager.svg?style=flat)](https://cocoapods.org/pods/STAccessoryManager) [![License](https://img.shields.io/cocoapods/l/STAccessoryManager.svg?style=flat)](https://github.com/coder/STAccessoryManager/blob/701ff106db3caa805f9dab12df7749c03c889c47/LICENSE) [![Platform](https://img.shields.io/cocoapods/p/STAccessoryManager.svg?style=flat)](https://cocoapods.org/pods/STAccessoryManager)

<!--toc:start-->

- [STAccessoryManager](#staccessorymanager)
  - [时间拆解](#时间拆解)
    - [1. 时间统计](#1-时间统计)
    - [2. 功能细节](#2-功能细节)
  - [摘要](#摘要)
  - [用法](#用法)
    - [集成](#集成)
  - [调用](#调用)
    - [引用](#引用)
    - [调用接口](#调用接口)
  - [历史版本](#历史版本)

<!--toc:end-->

## 时间拆解

### 1. 时间统计

| 序号 | 名称             | 工时[天] | 描述                                               |
| :--- | :--------------- | :------- | :------------------------------------------------- |
| 1    | 有线协议调试     | 4        | 协议分析，协议调试，视频数据解析                   |
| 2    | SDK封装          | 3        | 接口设计，功能调试                                 |
| 3    | app 主体功能开发 | 3        | app 页面绘制， 交互开发， 实时流展示， SDK 联调    |
| 4    | 拓展功能开发     | 5        | 设备设置功能，截图功能，文件管理功能，文件分享功能 |
| 5    | app 上架         | n        | 苹果审核时间不可控， app是否打回重申不可控         |

### 2. 功能细节

- 2.1 协议调试

  - 1. 协议分析
       协议文稿梳理
  - 2. 协议实现
    - 1. 报文组装/拆解
    - 2. 报文收发机制
  - 3. 设备调试

- 2.2 SDK封装

  - 1. SDK 主体设计
  - 2. SDK 接口开发
    - 1. 连接/断连 回调，
    - 2. 开启/关闭 流
    - 3. 流数据报文解析，媒体流回调
    - 4. 获取设备信息
    - 5. 获取设备配置 config / property
    - 6. 设置设备 config / property
    - 7. 【透传接口】 为以后C++拓展做准备
  - 3. SDK 异常场景梳理与测试

- 2.3 app 主体功能

  - 1. UI设计稿梳理
  - 2. UI绘制
  - 3. UI交互实现
  - 4. SDK联调【此段任务在SDK开发阶段就可以完成】
  - 5. 视频流播放

- 2.4 app 拓展功能

  - 1. 读取/下发 设备配置
  - 2. 展示设备配置
  - 3. 实时数据流播放
  - 4. 截图功能
  - 5. 视频录制并存储
  - 6. 视频文件管理：类似文件管理器功能
  - 7. 文件分享：通过系统分析功能，可以打开微信、airdrop、邮箱等app 分享视频

- 2.5 app 上架审核
  苹果审核比较消耗时间，时长不可控
  - 1. 苹果账号需要提供
  - 2. app 上架信息
    - 1. app 截图
    - 2. app 主体信息
    - 3. app 主体官网
    - 4. app 描述: 用途，功能等
  - 3. 提审信息
       > 演示视频录制
       > 编写提审描述信息
  - 4. 提审/被拒等沟通

## 摘要

STAccessoryManager 组件主要用于：

- 1 定制的MFI设备通讯

## 用法

### 集成

pod 'STAccessoryManager', '~> x.x.x'

## 调用

### 引用

- objc

  ```objc
  #import <STAccessoryManager/STAccessoryManager-Swift.h>
  ```

- swift

  ```swift
  import STAccessoryManager
  ```

### 调用接口

- objc

  ```objc
  //objc 代码
  ```

- swift

  ```swift
  //siwft 代码
  ```

## 历史版本

- [1.0.0](http://github/coder/STAccessoryManager/tag/1.0.0)

  - 初始化版本
  - 提供： xxx， xxx 功能

- - [1.0.1](http://github/coder/STAccessoryManager/tag/1.0.1)

  - 修复
  - 提供： xxx， xxx 功能
