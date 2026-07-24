// ============================================================================
// fpga_link.cpp —— ESP32 -> FPGA 传感器帧发送实现
// ============================================================================
#include "fpga_link.h"
#include "protocol_v1.h"

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

    protocol_send_frame(*serial_, encTicks, gyro, acc);
}
