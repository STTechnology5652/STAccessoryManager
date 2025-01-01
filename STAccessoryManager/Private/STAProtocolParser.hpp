#ifndef STAProtocolParser_hpp
#define STAProtocolParser_hpp

#include <vector>
#include <memory>
#include <cstdint>

namespace STA {

struct ResponseHeader {
    uint8_t cmdId;
    uint8_t cmdStatus;
    uint8_t cmdTag;
    uint32_t cmdDataLen;
    uint32_t imageDataLen;
    uint8_t b2;
    uint8_t b3;
    uint8_t b4;
    uint8_t b5;
    uint8_t headerLen;
};

class Response {
public:
    ResponseHeader header;
    std::vector<uint8_t> responseContent;
    std::vector<uint8_t> imageData;
    
    bool isValid() const;
};

class ProtocolParser {
public:
    static std::vector<Response> parseBuffer(const uint8_t* buffer, size_t length, uint64_t& bytesUsed);
    
private:
    static bool parseHeader(const uint8_t* buffer, size_t length, ResponseHeader& header, size_t& headerLength);
    static bool parsePackage(const uint8_t* buffer, size_t length, Response& response, size_t& packageLength);
};

} // namespace STA

#endif /* STAProtocolParser_hpp */ 