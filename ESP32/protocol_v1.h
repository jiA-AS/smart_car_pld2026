// ============================================================================
// protocol_v1.h —— V1.2 上行传感器帧 + V1.1 下行控制帧（与 FPGA 端严格对应）
//
// 上行 V1.2 (ESP32 → FPGA, 100Hz, 35 字节，全小端)：
//   AA 55 | 版本=0x03 | timestamp(2) | enc[4]×4 | gyro[3]×2 | acc[3]×2 | disp_mode | CRC8
//   CRC8/SMBUS：多项式 0x07、初值 0x00，覆盖版本 ~ disp_mode 共 32 字节
//   ★ V1.2 新增 disp_mode：遥控器左拨杆 s1 映射的显示模式（0=视角 1=轨迹 2=调试）
//   ★ 版本字节 0x01→0x03：与旧版固件互不兼容（FPGA 会判版本拒绝旧帧），
//     升级时必须 ESP/FPGA 两侧同时更新，否则上行帧全部 CRC/版本被拒
//
// 下行 V1.1 (FPGA → ESP32, 50Hz, 9 字节，全小端)：
//   55 AA | 版本=0x02 | mode | left_speed(2) | right_speed(2) | CRC8
//   CRC8/SMBUS：多项式 0x07、初值 0x00，覆盖前 8 字节（含帧头）
// ============================================================================
#pragma once
#include <Arduino.h>

/*================ 上行 V1.2 ================*/
#define PROTO_FRAME_LEN       35
#define PROTO_TYPE_SENSOR     0x03

// 显示模式（遥控器左拨杆 s1 映射）
#define DISP_MODE_VIEW        0   // s1上：视角（FPGA 全 HUD；OLED 接收页）
#define DISP_MODE_TRACK       1   // s1中：轨迹（FPGA 轨迹仪表突出；OLED 姿态页）
#define DISP_MODE_DEBUG       2   // s1下：调试（FPGA 夜间阈值+调试行；OLED 发送页）

#pragma pack(1)
typedef struct {
    uint8_t  head[2];      // 0xAA 0x55
    uint8_t  type;         // 0x03（协议中称为"版本"，V1.2）
    uint16_t timestamp;    // 毫秒时间戳低 16 位
    int32_t  enc[4];       // 编码器累计计数
    int16_t  gyro[3];      // 陀螺仪原始值（±250dps 量程）
    int16_t  acc[3];       // 加速度计原始值（±2g 量程）
    uint8_t  disp_mode;    // [V1.2] 显示模式 0=视角 1=轨迹 2=调试
    uint8_t  crc;          // CRC8，覆盖 type ~ disp_mode 共 32 字节
} SensorFrame;
#pragma pack()
static_assert(sizeof(SensorFrame) == PROTO_FRAME_LEN, "SensorFrame 必须为 35 字节");

/*================ 下行 V1.1 ================*/
#define CMD_FRAME_LEN         9
#define CMD_TYPE_CTRL         0x02

#define CMD_MODE_STOP         0   // 停车
#define CMD_MODE_SPEED        1   // 速度控制
#define CMD_MODE_SEARCH       2   // 搜索（原地转）

#pragma pack(1)
typedef struct {
    uint8_t  head[2];      // 0x55 0xAA（与上行方向相反，防止自环混淆）
    uint8_t  version;      // 0x02
    uint8_t  mode;         // 0=停车 1=速度控制 2=搜索
    int16_t  left_speed;   // 左轮目标速度 -100~+100（%）
    int16_t  right_speed;  // 右轮目标速度 -100~+100（%）
    uint8_t  crc;          // CRC8，覆盖前 8 字节（含帧头）
} CmdFrame;
#pragma pack()
static_assert(sizeof(CmdFrame) == CMD_FRAME_LEN, "CmdFrame 必须为 9 字节");

/*================ CRC8/SMBUS ================*/
// CRC-8/SMBUS：多项式 0x07，初值 0x00，非反射，异或出 0x00
// 与 FPGA 端 v1_decode.v / ctrl_link_tx.v 内 crc8_next 逐比特等价
inline uint8_t crc8_smbus(const uint8_t *data, uint16_t len) {
    uint8_t crc = 0;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (uint8_t j = 0; j < 8; j++)
            crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x07) : (uint8_t)(crc << 1);
    }
    return crc;
}

/*================ 上行组帧 ================*/
// 组帧并发送；返回发送字节数（应为 35）
inline size_t protocol_send_frame(HardwareSerial &serial,
                                  const int32_t enc[4],
                                  const int16_t gyro[3],
                                  const int16_t acc[3],
                                  uint8_t disp_mode) {     // [V1.2] 显示模式
    SensorFrame f;
    f.head[0] = 0xAA;
    f.head[1] = 0x55;
    f.type    = PROTO_TYPE_SENSOR;
    f.timestamp = (uint16_t)(millis() & 0xFFFF);
    memcpy(f.enc,  enc,  sizeof(f.enc));
    memcpy(f.gyro, gyro, sizeof(f.gyro));
    memcpy(f.acc,  acc,  sizeof(f.acc));
    f.disp_mode = disp_mode;
    f.crc = crc8_smbus(&f.type, 32);
    return serial.write((const uint8_t *)&f, sizeof(f));
}

/*================ 下行解析 ================*/
// 尝试从串口接收缓冲中解析一帧 V1.1 下行命令
// 返回 0=未收到完整帧 1=成功解析 -1=CRC 错误
inline int protocol_parse_cmd(HardwareSerial &serial, CmdFrame &out) {
    while (serial.available() >= CMD_FRAME_LEN) {
        // 查找帧头 0x55 0xAA
        uint8_t b0 = serial.read();
        if (b0 != 0x55) continue;
        if (!serial.available()) return 0;
        uint8_t b1 = serial.peek();
        if (b1 != 0xAA) continue;
        serial.read(); // 消费 0xAA

        // 已找到帧头，读取剩余 7 字节
        uint8_t buf[CMD_FRAME_LEN];
        buf[0] = 0x55;
        buf[1] = 0xAA;
        // 等待剩余 7 字节（50Hz 帧间隔 20ms，115200 下 9 字节仅需 ~0.8ms，无需长等）
        uint32_t t0 = millis();
        size_t   idx = 2;
        while (idx < CMD_FRAME_LEN && (millis() - t0) < 5) {
            if (serial.available()) {
                buf[idx++] = serial.read();
            }
        }
        if (idx < CMD_FRAME_LEN) {
            // 超时未收齐，丢弃此帧
            return 0;
        }

        // 验证 CRC8（覆盖前 8 字节，含帧头）
        if (crc8_smbus(buf, 8) != buf[8]) {
            return -1; // CRC 错误
        }

        memcpy(&out, buf, sizeof(CmdFrame));
        return 1; // 成功
    }
    return 0; // 数据不足
}