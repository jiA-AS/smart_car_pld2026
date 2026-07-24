// ============================================================================
// fpga_link.h —— ESP32 -> FPGA 传感器帧发送模块（V1.0 协议，100Hz）
// 增量模块：不修改官方固件的 IMU/编码器驱动，IMU 原始值由 imu_raw 只读获取
// ============================================================================
#pragma once
#include <Arduino.h>
#include "imu_raw.h"

class FpgaLink {
public:
    // serial: 使用的串口(推荐 Serial2)；rxPin/txPin 接 H24；baud 先 115200，联调后升 460800
    // sda/scl: IMU 所在 I2C（鱼香四驱V2 = 12,13），用于只读 IMU 原始值
    bool begin(HardwareSerial &serial, int rxPin, int txPin, uint32_t baud, int sda, int scl);
    // 每 10ms 内部节流；encTicks 为 4 路编码器累计计数（由调用方从官方 encoders 对象读取）
    void send(const int32_t encTicks[4]);
    // IMU 探测结果：0=未找到 1=MPU6050 2=LSM6DS3
    uint8_t imuChip() const { return imu_.chipType(); }

private:
    HardwareSerial *serial_ = nullptr;
    ImuRaw          imu_;
    uint32_t        lastSend_ = 0;
};
