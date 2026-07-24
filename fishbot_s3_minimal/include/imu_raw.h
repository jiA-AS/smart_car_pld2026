// ============================================================================
// imu_raw.h —— MPU6050 原始寄存器读取（不经过滤波/换算，符合协议"原始值"要求）
// 上电默认量程：陀螺仪 ±250dps、加速度 ±2g（与 FPGA 端解算系数一致）
// ============================================================================
#pragma once
#include <Arduino.h>
#include <Wire.h>

class ImuRaw {
public:
    // 初始化 I2C 并唤醒 MPU6050；失败返回 false（IMU 数据将保持 0）
    bool begin(int sda, int scl);
    // 读取 3 轴加速度和 3 轴陀螺仪原始值；失败返回 false（输出保持旧值）
    bool read(int16_t acc[3], int16_t gyro[3]);

private:
    bool ok_ = false;
};
