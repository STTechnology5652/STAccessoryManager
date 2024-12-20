# STAccessoryManager

STAccessoryManager 是一个用于管理和控制 MFi 外部设备的 iOS SDK，主要用于处理设备连接、数据传输和视频流处理等功能。

[English Version](README_EN.md)

## 目录

- [STAccessoryManager](#staccessorymanager)
  - [目录](#目录)
  - [架构设计](#架构设计)
    - [类图](#类图)
      - [Mermaid](#mermaid)
      - [PlantUML](#plantuml)
    - [时序图](#时序图)
      - [Mermaid](#mermaid-1)
      - [PlantUML](#plantuml-1)
  - [主要功能](#主要功能)
  - [核心类和协议](#核心类和协议)
    - [设备管理](#设备管理)
      - [STAccessoryManager](#staccessorymanager-1)
      - [STAccessoryConnectDelegate](#staccessoryconnectdelegate)
    - [设备通信](#设备通信)
      - [STAccesoryHandlerInterface](#staccesoryhandlerinterface)
    - [工具类](#工具类)
      - [STASpeedTool](#staspeedtool)
    - [视频处理相关类](#视频处理相关类)
      - [H264Decoder](#h264decoder)
      - [ViewForOpenGL](#viewforopengl)
  - [使用示例](#使用示例)
  - [注意事项](#注意事项)
  - [系统要求](#系统要求)
  - [依赖框架](#依赖框架)
  - [安装](#安装)
    - [CocoaPods](#cocoapods)
    - [Swift Package Manager](#swift-package-manager)

## 架构设计

### 类图

#### Mermaid
```mermaid
classDiagram
    class STAccessoryManager {
        +static share() STAccessoryManager
        +device(serialNumber: String) EAAccessory
        +config(delegate: STAccessoryConnectDelegate)
        +accessoryHander(devSerialNumber: String, complete: STAComplete<STAccesoryHandlerInterface>)
    }

    class STAccessoryConnectDelegate {
        <<interface>>
        +didConnect(device: EAAccessory)
        +didDisconnect(device: EAAccessory)
    }

    class STAccesoryHandlerInterface {
        <<interface>>
        +getNextCmdTag() UInt8
        +configImage(receiver: STAccesoryHandlerImageReceiver, protocol: String?, complete: STAComplete<String>)
        +sendCommand(cmdData: STAccesoryCmdData, protocol: String?, complete: STAComplete<STAResponse>)
        +openSteam(open: Bool, protocol: String?, complete: STAComplete<STAResponse>)
    }

    class STAccesoryHandlerImageReceiver {
        <<interface>>
        +didReceiveDeviceImageResponse(imgRes: STAResponse)
    }

    class STASpeedTool {
        +startCaculted(complete: (String) -> Void)
        +appendCount(count: Int)
    }

    class H264Decoder {
        +delegate: H264DecoderDelegate
        +decodeNalu(frame: uint8_t*, size: uint32_t)
        +decodeMjpeg(frame: uint8_t*, size: uint32_t)
    }

    class ViewForOpenGL {
        +displayYUV420pData(data: void*, width: NSInteger, height: NSInteger)
        +setVideoSize(width: GLuint, height: GLuint)
        +clearFrame()
    }

    STAccessoryManager ..> STAccessoryConnectDelegate : uses
    STAccessoryManager ..> STAccesoryHandlerInterface : creates
    STAccesoryHandlerInterface ..> STAccesoryHandlerImageReceiver : uses
    STAccesoryHandlerInterface ..> STAccesoryCmdData : uses
    H264Decoder ..> H264DecoderDelegate : uses
```

#### PlantUML
```plantuml
@startuml

class STAccessoryManager {
    + {static} share(): STAccessoryManager
    + device(serialNumber: String): EAAccessory
    + config(delegate: STAccessoryConnectDelegate)
    + accessoryHander(devSerialNumber: String, complete: STAComplete<STAccesoryHandlerInterface>)
}

interface STAccessoryConnectDelegate {
    + didConnect(device: EAAccessory)
    + didDisconnect(device: EAAccessory)
}

interface STAccesoryHandlerInterface {
    + getNextCmdTag(): UInt8
    + configImage(receiver: STAccesoryHandlerImageReceiver, protocol: String?, complete: STAComplete<String>)
    + sendCommand(cmdData: STAccesoryCmdData, protocol: String?, complete: STAComplete<STAResponse>)
    + openSteam(open: Bool, protocol: String?, complete: STAComplete<STAResponse>)
}

interface STAccesoryHandlerImageReceiver {
    + didReceiveDeviceImageResponse(imgRes: STAResponse)
}

class STASpeedTool {
    + startCaculted(complete: (String) -> Void)
    + appendCount(count: Int)
}

class H264Decoder {
    + delegate: H264DecoderDelegate
    + decodeNalu(frame: uint8_t*, size: uint32_t)
    + decodeMjpeg(frame: uint8_t*, size: uint32_t)
}

class ViewForOpenGL {
    + displayYUV420pData(data: void*, width: NSInteger, height: NSInteger)
    + setVideoSize(width: GLuint, height: GLuint)
    + clearFrame()
}

STAccessoryManager ..> STAccessoryConnectDelegate : uses
STAccessoryManager ..> STAccesoryHandlerInterface : creates
STAccesoryHandlerInterface ..> STAccesoryHandlerImageReceiver : uses
STAccesoryHandlerInterface ..> STAccesoryCmdData : uses
H264Decoder ..> H264DecoderDelegate : uses

@enduml
```

### 时序图

#### Mermaid
```mermaid
sequenceDiagram
    participant App
    participant STAccessoryManager
    participant STAccesoryHandlerInterface
    participant MFIDevice
    participant MjpegUtil

    autonumber
    rect rgb(173, 216, 230)
    Note right of App: 1. 初始化阶段
    App->>STAccessoryManager: share()
    App->>STAccessoryManager: config(delegate)
    end

    rect rgb(144, 238, 144)
    Note right of App: 2. 连接阶段
    MFIDevice->>STAccessoryManager: 设备接入
    STAccessoryManager-->>App: didConnect(device)
    App->>STAccessoryManager: accessoryHander(devSerialNumber)
    STAccessoryManager-->>App: handler: STAccesoryHandlerInterface
    end

    rect rgb(255, 255, 224)
    Note right of App: 3. 配置阶段
    App->>STAccesoryHandlerInterface: configImage(receiver)
    App->>STAccesoryHandlerInterface: openSteam(true)
    STAccesoryHandlerInterface->>MFIDevice: 打开数据流
    end

    rect rgb(255, 182, 193)
    Note right of App: 4. 数据传输阶段
    MFIDevice->>STAccesoryHandlerInterface: 发送视频数据
    STAccesoryHandlerInterface->>App: didReceiveDeviceImageResponse
    App->>MjpegUtil: receive(imageData)
    MjpegUtil-->>App: UIImage
    end

    rect rgb(211, 211, 211)
    Note right of App: 5. 断开阶段
    MFIDevice->>STAccessoryManager: 设备断开
    STAccessoryManager-->>App: didDisconnect(device)
    end
```

#### PlantUML
```plantuml
@startuml
participant App
participant STAccessoryManager
participant STAccesoryHandlerInterface
participant MFIDevice
participant MjpegUtil

== 初始化阶段 ==
autonumber
App -> STAccessoryManager: share()
App -> STAccessoryManager: config(delegate)

== 连接阶段 ==
MFIDevice -> STAccessoryManager: 设备接入
STAccessoryManager --> App: didConnect(device)
App -> STAccessoryManager: accessoryHander(devSerialNumber)
STAccessoryManager --> App: handler: STAccesoryHandlerInterface

== 配置阶段 ==
App -> STAccesoryHandlerInterface: configImage(receiver)
App -> STAccesoryHandlerInterface: openSteam(true)
STAccesoryHandlerInterface -> MFIDevice: 打开数据流

== 数据传输阶段 ==
MFIDevice -> STAccesoryHandlerInterface: 发送视频数据
STAccesoryHandlerInterface -> App: didReceiveDeviceImageResponse
App -> MjpegUtil: receive(imageData)
MjpegUtil --> App: UIImage

== 断开阶段 ==
MFIDevice -> STAccessoryManager: 设备断开
STAccessoryManager --> App: didDisconnect(device)
@enduml
```

## 主要功能

- MFi 设备连接和会话管理
- 设备指令收发
- 视频流处理(支持H264/MJPEG)
- 设备配置管理

## 核心类和协议

### 设备管理

#### STAccessoryManager

设备管理类,提供设备连接和会话管理:

```swift
class STAccessoryManager {
    // 获取单例
    static func share() -> STAccessoryManager
    
    // 获取指定设备
    func device(_ serialNumber: String) -> EAAccessory?
    
    // 配置连接状态监听
    func config(delegate: STAccessoryConnectDelegate)
    
    // 获取设备处理器
    func accessoryHander(devSerialNumber: String, complete: STAComplete<STAccesoryHandlerInterface>?)
}
```

#### STAccessoryConnectDelegate

设备连接状态监听:

```swift
protocol STAccessoryConnectDelegate {
    // 设备连接
    func didConnect(device: EAAccessory)
    
    // 设备断开
    func didDisconnect(device: EAAccessory) 
}
```

### 设备通信

#### STAccesoryHandlerInterface

设备处理器对外接口,定义了与设备交互的主要方法：

```swift
protocol STAccesoryHandlerInterface {
    // 获取命令标
    func getNextCmdTag() -> UInt8
    
    // 配置图像接收
    func configImage(receiver: STAccesoryHandlerImageReceiver, 
                    protocol proStr: String?, 
                    complete: STAComplete<String>?)
    
    // 发送命令
    func sendCommand(_ cmdData: STAccesoryCmdData, 
                    protocol proStr: String?, 
                    complete: STAComplete<STAResponse>?)
    
    // 打开/关闭数据流
    func openSteam(_ open: Bool, 
                  protocol proStr: String?, 
                  complete: STAComplete<STAResponse>?)
}
```

### 工具类

#### STASpeedTool

速度统计工具:

```swift
class STASpeedTool {
    // 开始统计
    func startCaculted(_ complete: @escaping (_ speedDes: String) -> Void)
    
    // 添加数据量
    func appendCount(_ count: Int)
}
```

### 视频处理相关类

#### H264Decoder

H264视频解码器：

```objc
@interface H264Decoder : NSObject
@property (weak, nonatomic) id<H264DecoderDelegate> delegate;

// 解码H264数据
- (void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;

// 解码MJPEG帧数据
- (void)decodeMjpeg:(uint8_t *)frame withSize:(uint32_t)frameSize;
@end
```

#### ViewForOpenGL

OpenGL视频渲染视图：

```objc
@interface ViewForOpenGL : UIView
// 显示YUV数据
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h;

// 设置视频尺寸
- (void)setVideoSize:(GLuint)width height:(GLuint)height;

// 清除画面
- (void)clearFrame;
@end
```

## 使用示例

1. 初始化并获取设备：

```swift
let manager = STAccessoryManager.share()
if let device = manager.device(serialNumber) {
    // 使用设备
}
```

2. 获取命令标签并发送命令：

```swift
// 获取命令标签
let cmdTag = handler.getNextCmdTag()

// 使用命令标签创建命令
let cmd = STACommandserialization.setStreamFormatter(cmdTag)
let command = STAccesoryCmdData(tag: cmdTag, data: cmd)

// 发送命令
handler.sendCommand(command, protocol: nil) { response in
    if response.status {
        print("命令发送成功")
    }
}
```

3. 配置视频接收：

```swift
handler.configImage(receiver: imageReceiver, protocol: nil) { result in
    if result.status {
        print("配置成功")
    }
}
```

4. 打开数据流：

```swift
let cmdData = STACommandserialization.openStreamCmd(withTag: tag, open: 0x01)
handler.sendCommand(cmdData, protocol: nil) { response in
    if response.status {
        print("命令发送成功")
    }
}
```

5. 接收图像数据：

```swift
// 实现 STAccesoryHandlerImageReceiver 协议
class YourClass: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        guard let imgData = imgRes.imageData, imgData.count > 0 else { return }
        
        // MJPEG 数据处理
        let mjpegUtil = MjpegUtil()
        mjpegUtil.receive(imgData) { (image: UIImage) in
            // 显示图像
            self.imageView.image = image
        }
        
        // 或者 H264 数据处理
        let h264Decoder = H264Decoder()
        h264Decoder.delegate = self
        h264Decoder.decodeNalu(imgData.bytes, withSize: UInt32(imgData.count))
    }
}

// H264 解码回调
extension YourClass: H264DecoderDelegate {
    func decoder(_ decoder: H264Decoder, didOutput frame: CVPixelBuffer) {
        // 处理解码后的帧数据
        glView.displayYUV420pData(frame, width: width, height: height)
    }
}
```

6. 视频渲染：

```swift
class STVideoView: UIView {
    private lazy var glView: ViewForOpenGL = {
        let view = ViewForOpenGL()
        view.backgroundColor = .black
        return view
    }()
    
    private var hasSetVideoSize = false
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0
    private lazy var h264Decoder: H264Decoder = {
        let decoder = H264Decoder()
        decoder.delegate = self
        return decoder
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(glView)
        glView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            // 16:9 比例
            make.width.equalTo(self.snp.width)
            make.height.equalTo(glView.snp.width).multipliedBy(9.0/16.0)
        }
    }
    
    func setVideoSize(width: Int, height: Int) {
        videoWidth = width
        videoHeight = height
        glView.setVideoSize(UInt32(width), height: UInt32(height))
    }
}

// 实现图像接收和渲染
extension STVideoView: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        guard let imgData = imgRes.imageData, imgData.count > 0 else { return }
        
        // 解码并显示
        h264Decoder.decodeNalu(imgData.bytes, withSize: UInt32(imgData.count))
    }
}

extension STVideoView: H264DecoderDelegate {
    func decoder(_ decoder: H264Decoder, didOutput frame: CVPixelBuffer) {
        // 在主线程更新UI
        DispatchQueue.main.async {
            self.glView.displayYUV420pData(frame, width: self.videoWidth, height: self.videoHeight)
        }
    }
}
```

7. 使用 UIImageView 显示图像：

```swift
class STImageView: UIView {
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var mjpegUtil = MjpegUtil()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            // 16:9 比例
            make.width.equalTo(self.snp.width)
            make.height.equalTo(imageView.snp.width).multipliedBy(9.0/16.0)
        }
    }
}

// 实现图像接收和显示
extension STImageView: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        guard let imgData = imgRes.imageData, imgData.count > 0 else { return }
        
        // MJPEG 数据处理
        mjpegUtil.receive(imgData) { [weak self] (image: UIImage) in
            // 在主线程更新UI
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
    }
}
```

## 注意事项

1. 所有涉及设备交互的操作都应该在正确的队列中执行
2. 视频数据处理应注意内存管理，及时释放不需要的资源
3. 不需要时及时关闭视频流和释放资源
4. 视频渲染使用OpenGL注上下文管理

## 系统要求

- iOS 11.0+
- Xcode 12.0+

## 依赖框架

- ExternalAccessory.framework
- OpenGLES.framework
- VideoToolbox.framework
- AVFoundation.framework

## 安装

### CocoaPods

```ruby
pod 'STAccessoryManager', :git => 'https://github.com/STTechnology5652/STAccessoryManager.git', :tag => '0.0.1'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/STTechnology5652/STAccessoryManager.git", .upToNextMajor(from: "0.0.1"))
]
```
