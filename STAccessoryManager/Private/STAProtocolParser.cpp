#include "STAProtocolParser.h"
#include <cstring>

namespace STA {

bool Response::isValid() const {
    if (header.headerLen < Protocol::kMinHeaderLength) return false;
    
    if (header.cmdId != 0 && header.cmdTag != 0) {
        if (header.cmdDataLen > 0 && responseContent.empty()) return false;
        if (header.cmdDataLen != responseContent.size()) return false;
    }
    
    if (header.cmdId == 0 && header.cmdTag == 0 && header.cmdStatus == 0) {
        if (header.imageDataLen > 0 && imageData.empty()) return false;
        if (header.imageDataLen != imageData.size()) return false;
    }
    
    return true;
}

std::vector<Response> ProtocolParser::parseBuffer(const uint8_t* buffer, size_t length, uint64_t& bytesUsed) {
    std::vector<Response> responses;
    responses.reserve(100);
    size_t offset = 0;
    bytesUsed = 0;
    
    // 限制单次处理的最大响应数量
    const size_t maxResponses = 100;
    
    while (offset < length && responses.size() < maxResponses) {
        // 1. 在剩余数据中查找有效的报文头
        size_t headerStart = offset;
        bool foundHeader = false;
        
        while (headerStart + Protocol::kMinHeaderLength <= length) {
            if (buffer[headerStart] == 0x0C) {
                // 尝试解析报文头
                ResponseHeader header;
                if (tryParseHeader(buffer + headerStart, length - headerStart, header)) {
                    foundHeader = true;
                    break;
                }
            }
            headerStart++;
        }
        
        if (!foundHeader) {
            // 没找到有效报文头，保留最后 kMinHeaderLength-1 个字节
            bytesUsed = length - Protocol::kMinHeaderLength + 1;
            break;
        }
        
        // 2. 解析完整报文
        Response response;
        size_t packageLength;
        if (!parsePackage(buffer + headerStart, length - headerStart, response, packageLength)) {
            // 数据不足以解析完整报文
            bytesUsed = headerStart;
            break;
        }
        
        // 3. 添加解析成功的报文
        responses.push_back(std::move(response));
        offset = headerStart + packageLength;
        bytesUsed = offset;
    }
    
    // 如果处理完成，清理多余的容量
    responses.shrink_to_fit();
    return responses;
}

bool ProtocolParser::tryParseHeader(const uint8_t* buffer, size_t length, ResponseHeader& header) {
    if (length < Protocol::kMinHeaderLength || buffer[0] != 0x0C) {
        return false;
    }
    
    size_t offset = 1;  // 跳过 b0 (0x0C)
    uint8_t b1 = buffer[offset++];  // 命令标志位
    
    // 读取 PTS 时间戳 (4字节)
    uint32_t pts;
    memcpy(&pts, buffer + offset, 4);
    offset += 4;
    
    uint8_t b6 = buffer[offset++];  // 数据长度低字节
    uint8_t b7 = buffer[offset++];  // 数据长度高字节
    uint8_t b8 = buffer[offset++];  // 数据长度扩展字节
    uint8_t b9 = buffer[offset++];  // 命令标签 + 数据长度扩展
    uint8_t b10 = buffer[offset++]; // 命令ID
    uint8_t b11 = buffer[offset++]; // 命令状态
    
    // 解析命令相关字段
    header.cmdId = b10;
    header.cmdStatus = b11;
    header.cmdTag = b9 >> 4;  // 高4位为命令标签
    
    // 验证命令标签
    if (header.cmdTag > Protocol::kMaxCmdTag) {
        return false;
    }
    
    // 添加更严格的数据长度限制
    const size_t maxImageSize = 1024 * 1024;  // 1MB
    const size_t maxCmdDataSize = 64 * 1024;  // 64KB
    
    if (header.cmdId == 0 && header.cmdTag == 0) {
        header.cmdDataLen = 0;
        header.imageDataLen = (b7 << 8) | b6;
        if (header.imageDataLen > maxImageSize) {
            return false;
        }
    } else {
        header.cmdDataLen = ((b9 & 0x0F) << 8) | b8;
        if (header.cmdDataLen > maxCmdDataSize) {
            return false;
        }
        header.imageDataLen = 0;
    }
    
    // 计算总包长度，验证数据是否足够
    size_t totalLength = Protocol::kMinHeaderLength + header.cmdDataLen + header.imageDataLen;
    if (totalLength > length) {
        return false;
    }
    
    // 保存时间戳相关字节
    if (header.cmdId == 0 && header.cmdTag == 0) {
        header.b2 = (pts >> 24) & 0xFF;
        header.b3 = (pts >> 16) & 0xFF;
        header.b4 = (pts >> 8) & 0xFF;
        header.b5 = pts & 0xFF;
    } else {
        header.b2 = header.b3 = header.b4 = header.b5 = 0;
    }
    
    header.headerLen = Protocol::kMinHeaderLength;
    return true;
}

bool ProtocolParser::parsePackage(const uint8_t* buffer, size_t length, Response& response, size_t& packageLength) {
    // 检查总内存使用
    size_t totalMemoryNeeded = Protocol::kMinHeaderLength;
    if (response.header.cmdDataLen > 0) {
        totalMemoryNeeded += response.header.cmdDataLen;
    }
    if (response.header.imageDataLen > 0) {
        totalMemoryNeeded += response.header.imageDataLen;
    }
    
    if (totalMemoryNeeded > Protocol::kMaxDataLength) {
        return false;
    }
    
    // 使用 tryParseHeader 解析头部
    if (!tryParseHeader(buffer, length, response.header)) {
        packageLength = 1;  // 跳过一个字节
        return false;
    }
    
    size_t totalLength = Protocol::kMinHeaderLength;
    
    // 检查数据完整性
    if (response.header.cmdDataLen > 0) {
        response.responseContent.reserve(response.header.cmdDataLen);
        if (totalLength + response.header.cmdDataLen > length) {
            packageLength = 0;  // 数据不完整，等待更多数据
            return false;
        }
        response.responseContent.assign(buffer + totalLength,
                                     buffer + totalLength + response.header.cmdDataLen);
        totalLength += response.header.cmdDataLen;
    }
    
    if (response.header.imageDataLen > 0) {
        response.imageData.reserve(response.header.imageDataLen);
        if (totalLength + response.header.imageDataLen > length) {
            packageLength = 0;  // 数据不完整，等待更多数据
            return false;
        }
        response.imageData.assign(buffer + totalLength,
                                buffer + totalLength + response.header.imageDataLen);
        totalLength += response.header.imageDataLen;
    }
    
    packageLength = totalLength;
    return true;
}

} // namespace STA 
