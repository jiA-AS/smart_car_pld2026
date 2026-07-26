// ============================================================================
// fpga_link.cpp —— ESP32 ↔ FPGA 双向通信实现
// ============================================================================
#include "fpga_link.h"

bool FpgaLink::begin(HardwareSerial &serial, int rxPin, int txPin, uint32_t baud,
                     int sda, int scl) {
    serial_ = &serial;
    serial.begin(baud, SERIAL_8N1, rxPin, txPin);
    // 只读打开 IMU（双芯片自适应）；重复 Wire.begin 对官方 ImuDriver 无影响
    return imu_.begin(sda, scl);
}

void FpgaLink::send(const int32_t encTicks[4]) {
    uint32_t now = millis();
    if (now - lastSend_ < 10) return;      // 100Hz 节流
    lastSend_ = now;

    static int16_t acc[3]  = {0};
    static int16_t gyro[3] = {0};
    imu_.read(acc, gyro);                  // 失败保持上一帧值

    // 构建并缓存最近一帧原始字节（供 OLED 调试显示）
    {
        SensorFrame f;
        f.head[0] = 0xAA; f.head[1] = 0x55;
        f.type    = PROTO_TYPE_SENSOR;
        f.timestamp = (uint16_t)(millis() & 0xFFFF);
        memcpy(f.enc,  encTicks, sizeof(f.enc));
        memcpy(f.gyro, gyro,     sizeof(f.gyro));
        memcpy(f.acc,  acc,      sizeof(f.acc));
        f.crc = crc8_smbus(&f.type, 31);
        memcpy(lastTxRaw_, &f, PROTO_FRAME_LEN);
    }

    protocol_send_frame(*serial_, encTicks, gyro, acc);

    memcpy(lastEnc_,  encTicks, sizeof(lastEnc_));
    memcpy(lastGyro_, gyro,     sizeof(lastGyro_));
    memcpy(lastAcc_,  acc,      sizeof(lastAcc_));

    txCount_++;
}

void FpgaLink::receive() {
    CmdFrame frame;
    int result = protocol_parse_cmd(*serial_, frame);
    if (result == 1) {
        // 成功收到一帧
        memcpy(&cmd_, &frame, sizeof(CmdFrame));
        lastCmdMs_ = millis();
        watchdog_  = false;
        rxOkCount_++;
    } else if (result == -1) {
        rxCrcErr_++;
    }

    // 200ms 看门狗检查
    if (!watchdog_ && cmdOnline() && (millis() - lastCmdMs_ > 200)) {
        watchdog_ = true;
    }
}

bool FpgaLink::cmdOnline() const {
    return (lastCmdMs_ != 0);
}

uint32_t FpgaLink::cmdLastMs() const {
    return lastCmdMs_;
}

bool FpgaLink::cmdWatchdog() const {
    return watchdog_;
}