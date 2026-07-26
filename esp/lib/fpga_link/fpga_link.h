// ============================================================================
// fpga_link.h —— ESP32 ↔ FPGA 双向通信模块（V1.0 上行 + V1.1 下行）
//
// 上行：100Hz 发送 34 字节传感器帧（编码器+IMU）
// 下行：50Hz 接收 9 字节控制帧（模式+速度），带 200ms 看门狗
// ============================================================================
#pragma once
#include <Arduino.h>
#include "imu_raw.h"
#include "protocol_v1.h"

class FpgaLink {
public:
    // serial: 使用的串口(推荐 Serial2)；rxPin/txPin 接 H24；baud 115200
    // sda/scl: IMU 所在 I2C（鱼香四驱V2 = 12,13），用于只读 IMU 原始值
    bool begin(HardwareSerial &serial, int rxPin, int txPin, uint32_t baud, int sda, int scl);

    // 每 10ms 内部节流；encTicks 为 4 路编码器累计计数
    void send(const int32_t encTicks[4]);

    // 下行 V1.1 接收和看门狗（loop 中调用，非阻塞）
    void receive();

    // 下行状态查询
    bool     cmdOnline() const;          // 200ms 内收到过合法下行帧
    uint32_t cmdLastMs()  const;         // 最后收到合法帧的 millis()
    uint8_t  cmdMode()    const { return cmd_.mode; }
    int16_t  cmdLeft()    const { return cmd_.left_speed; }
    int16_t  cmdRight()   const { return cmd_.right_speed; }
    bool     cmdWatchdog() const;        // 看门狗触发（200ms 无合法帧）
    const uint8_t* cmdRaw() const { return (const uint8_t*)&cmd_; }  // 下行原始帧 9 字节

    // 上行帧原始字节
    const uint8_t* txRaw() const { return lastTxRaw_; }           // 上行原始帧 34 字节

    // 上行帧关键传感器数值（最近一帧，调试用）
    int32_t txEnc(int idx)   const { return lastEnc_[idx]; }
    int16_t txGyro(int axis) const { return lastGyro_[axis]; }
    int16_t txAcc(int axis)  const { return lastAcc_[axis]; }

    // IMU 探测结果：0=未找到 1=MPU6050 2=LSM6DS3
    uint8_t imuChip() const { return imu_.chipType(); }

    // 发送计数器（调试用）
    uint32_t txCount() const { return txCount_; }
    uint32_t rxOkCount()  const { return rxOkCount_; }
    uint32_t rxCrcErr()   const { return rxCrcErr_; }

private:
    HardwareSerial *serial_ = nullptr;
    ImuRaw          imu_;
    uint32_t        lastSend_ = 0;

    // 下行 V1.1
    CmdFrame cmd_{};
    uint32_t lastCmdMs_ = 0;
    bool     watchdog_  = false;

    // 上行帧缓存
    uint8_t  lastTxRaw_[PROTO_FRAME_LEN] = {0};
    int32_t  lastEnc_[4]  = {0};
    int16_t  lastGyro_[3] = {0};
    int16_t  lastAcc_[3]  = {0};

    // 计数器
    uint32_t txCount_  = 0;
    uint32_t rxOkCount_ = 0;
    uint32_t rxCrcErr_  = 0;
};