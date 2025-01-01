#ifndef STAProtocolParser_hpp
#define STAProtocolParser_hpp

#include <vector>
#include <memory>
#include <cstdint>

namespace STA {

// 全局协议常量
namespace Protocol {
    static constexpr uint8_t kMinHeaderLength = 12;  // 最小头部长度
    static constexpr uint8_t kMaxCmdTag = 0x0F;     // 命令标签最大值
    static constexpr uint32_t kMaxDataLength = 1024 * 1024;  // 最大数据长度 1MB
}

// 协议头部结构
struct ResponseHeader {
    uint8_t cmdId;        // 命令ID
    uint8_t cmdStatus;    // 命令状态
    uint8_t cmdTag;       // 命令标签
    uint32_t cmdDataLen;  // 命令数据长度
    uint32_t imageDataLen;// 图像数据长度
    uint8_t b2;          // PTS bytes
    uint8_t b3;
    uint8_t b4;
    uint8_t b5;
    uint8_t headerLen;    // 头部长度
};

class Response {
public:
    ResponseHeader header;
    std::vector<uint8_t> responseContent;  // 命令响应数据
    std::vector<uint8_t> imageData;        // 图像数据
    
    bool isValid() const;
};

class ProtocolParser {
public:
    static std::vector<Response> parseBuffer(const uint8_t* buffer, size_t length, uint64_t& bytesUsed);
    
private:
    static bool tryParseHeader(const uint8_t* buffer, size_t length, ResponseHeader& header);
    static bool parsePackage(const uint8_t* buffer, size_t length, Response& response, size_t& packageLength);
};

} // namespace STA

#endif /* STAProtocolParser_hpp */ 