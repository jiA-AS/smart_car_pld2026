// ============================================================================
// imu_raw.cpp —— MPU6050 原始寄存器读取实现
// 寄存器布局（0x3B 起连读 14 字节，大端）：
//   ACC_X H/L, ACC_Y H/L, ACC_Z H/L, TEMP H/L, GYRO_X/Y/Z H/L
// ============================================================================
#include "imu_raw.h"

#define MPU_ADDR   0x68
#define REG_WHOAMI 0x75
#define REG_PWR1   0x6B
#define REG_DATA   0x3B

bool ImuRaw::begin(int sda, int scl) {
    Wire.begin(sda, scl);
    Wire.setClock(400000);
    // WHO_AM_I 应为 0x68
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(REG_WHOAMI);
    if (Wire.endTransmission(false) != 0) return false;
    if (Wire.requestFrom(MPU_ADDR, 1) != 1) return false;
    if (Wire.read() != 0x68) return false;
    // 唤醒（退出睡眠模式），量程保持上电默认 ±250dps / ±2g
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(REG_PWR1);
    Wire.write(0x00);
    if (Wire.endTransmission() != 0) return false;
    delay(100);
    ok_ = true;
    return true;
}

bool ImuRaw::read(int16_t acc[3], int16_t gyro[3]) {
    if (!ok_) return false;
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(REG_DATA);
    if (Wire.endTransmission(false) != 0) return false;
    if (Wire.requestFrom(MPU_ADDR, 14) != 14) return false;
    auto rd = []() -> int16_t {
        return (int16_t)(((int16_t)Wire.read() << 8) | (int16_t)Wire.read());
    };
    acc[0]  = rd();
    acc[1]  = rd();
    acc[2]  = rd();
    rd();                 // 温度，跳过
    gyro[0] = rd();
    gyro[1] = rd();
    gyro[2] = rd();
    return true;
}
