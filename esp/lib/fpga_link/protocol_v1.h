// ============================================================================
// protocol_v1.h —— V1.0 传感器帧协议（与 FPGA 端 packet_decode 严格对应）
// 帧格式（34字节，全小端）：
//   AA 55 | type=0x01 | timestamp(2) | enc[4]×4 | gyro[3]×2 | acc[3]×2 | CRC8
// CRC8/SMBUS：多项式 0x07、初值 0x00，覆盖 type ~ acc[2] 共 31 字节
// ============================================================================
#pragma once
#include <Arduino.h>

#define PROTO_FRAME_LEN     34
#define PROTO_TYPE_SENSOR   0x01

#pragma pack(1)
typedef struct {
    uint8_t  head[2];      // 0xAA 0x55
    uint8_t  type;         // 0x01
    uint16_t timestamp;    // 毫秒时间戳低 16 位
    int32_t  enc[4];       // 编码器累计计数
    int16_t  gyro[3];      // 陀螺仪原始值（±250dps 量程）
    int16_t  acc[3];       // 加速度计原始值（±2g 量程）
    uint8_t  crc;          // CRC8，覆盖 type ~ acc[2] 共 31 字节
} SensorFrame;
#pragma pack()

static_assert(sizeof(SensorFrame) == PROTO_FRAME_LEN, "SensorFrame 必须为 34 字节");

// CRC8/SMBUS：与 FPGA 端 crc8_next 逐比特等价
inline uint8_t crc8_smbus(const uint8_t *data, uint16_t len) {
    uint8_t crc = 0;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (uint8_t j = 0; j < 8; j++)
            crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x07) : (uint8_t)(crc << 1);
    }
    return crc;
}

// 组帧并发送；返回发送字节数（应为 34）
inline size_t protocol_send_frame(HardwareSerial &serial,
                                  const int32_t enc[4],
                                  const int16_t gyro[3],
                                  const int16_t acc[3]) {
    SensorFrame f;
    f.head[0] = 0xAA;
    f.head[1] = 0x55;
    f.type    = PROTO_TYPE_SENSOR;
    f.timestamp = (uint16_t)(millis() & 0xFFFF);
    memcpy(f.enc,  enc,  sizeof(f.enc));
    memcpy(f.gyro, gyro, sizeof(f.gyro));
    memcpy(f.acc,  acc,  sizeof(f.acc));
    f.crc = crc8_smbus(&f.type, 31);
    return serial.write((const uint8_t *)&f, sizeof(f));
}
