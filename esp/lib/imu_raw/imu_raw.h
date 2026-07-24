// ============================================================================
// imu_raw.h —— IMU 原始寄存器读取（双芯片自适应）
// 鱼香四驱V2原理图芯片为 LSM6DS3TR-C；部分批次/改版可能为 MPU6050。
// begin() 自动探测芯片类型；量程统一配置为 陀螺仪±250dps、加速度±2g，
// 与 FPGA 端解算系数一致。
// ============================================================================
#pragma once
#include <Arduino.h>
#include <Wire.h>

class ImuRaw {
public:
    // 初始化 I2C 并自动探测/配置 IMU；失败返回 false（IMU 数据将保持 0）
    bool begin(int sda, int scl);
    // 读取 3 轴加速度和 3 轴陀螺仪原始值；失败返回 false（输出保持旧值）
    bool read(int16_t acc[3], int16_t gyro[3]);
    // 探测结果：0=未找到 1=MPU6050 2=LSM6DS3(TR-C)
    uint8_t chipType() const { return chip_; }

private:
    bool    probe_(uint8_t addr, uint8_t reg, uint8_t expect);
    bool    wakeMpu6050_();
    bool    initLsm6ds3_();
    bool    readMpu6050_(int16_t acc[3], int16_t gyro[3]);
    bool    readLsm6ds3_(int16_t acc[3], int16_t gyro[3]);

    bool    ok_   = false;
    uint8_t chip_ = 0;      // 0=none 1=MPU6050 2=LSM6DS3
    uint8_t addr_ = 0;
};
