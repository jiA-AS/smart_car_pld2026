// ============================================================================
// dbus.h —— 大疆 DR16 接收机 DBus 协议解析（ESP32-S3，硬件反相，免外部电路）
// 物理层：100000bps、8E1（偶校验）、信号反相；帧长 18 字节，周期约 7ms
// ============================================================================
#pragma once
#include <Arduino.h>

#define DBUS_FRAME_LEN    18
#define DBUS_CH_MID       1024    // 摇杆中位
#define DBUS_CH_MIN       364
#define DBUS_CH_MAX       1684
#define DBUS_TIMEOUT_MS   200     // 超过此时间无帧 = 失联

typedef struct {
    int16_t ch[4];   // ch0=右摇杆左右 ch1=右摇杆上下 ch2=左摇杆左右 ch3=左摇杆上下
    uint8_t s1;      // 左拨杆开关：1=上 2=中 3=下
    uint8_t s2;      // 右拨杆开关：1=上 2=中 3=下
} DbusData;

// 摇杆通道值(364~1684,中位1024) -> 输出(-maxOut~+maxOut)，带 ±30 死区
inline int16_t dbus_map_channel(int16_t v, int16_t maxOut) {
    int32_t x = (int32_t)constrain(v, DBUS_CH_MIN, DBUS_CH_MAX) - DBUS_CH_MID;
    if (abs(x) < 30) return 0;
    return (int16_t)(x * maxOut / 660);
}

class DbusReceiver {
public:
    // rxPin 接接收机信号线；ESP32 硬件 UART 原生支持反相，无需外部反相器
    void begin(HardwareSerial &serial, int rxPin);
    void update();                              // 主循环中调用，解析已收到的字节
    bool isOnline() const;                      // 200ms 内收到过有效帧
    const DbusData &data() const { return data_; }

private:
    HardwareSerial *serial_ = nullptr;
    DbusData  data_{};
    uint8_t   buf_[DBUS_FRAME_LEN];
    uint8_t   idx_ = 0;
    uint32_t  lastByteUs_ = 0;
    uint32_t  lastFrameMs_ = 0;
    bool parseFrame_(const uint8_t *f);
};
