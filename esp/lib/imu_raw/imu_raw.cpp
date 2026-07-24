// ============================================================================
// imu_raw.cpp —— IMU 原始寄存器读取实现（MPU6050 / LSM6DS3 双芯片自适应）
//
// MPU6050：地址0x68，WHO_AM_I(0x75)=0x68；数据0x3B起14字节【大端】
//           acc xyz, temp, gyro xyz
// LSM6DS3(TR-C)：地址0x6A/0x6B，WHO_AM_I(0x0F)=0x69/0x6A；
//           数据0x22起12字节【小端】 gyro xyz, acc xyz
// ============================================================================
#include "imu_raw.h"

//------------------------------ 寄存器定义 ------------------------------
// MPU6050
#define MPU_ADDR      0x68
#define MPU_WHOAMI    0x75
#define MPU_PWR1      0x6B
#define MPU_DATA      0x3B
// LSM6DS3
#define LSM_ADDR0     0x6A
#define LSM_ADDR1     0x6B
#define LSM_WHOAMI    0x0F
#define LSM_CTRL1_XL  0x10
#define LSM_CTRL2_G   0x11
#define LSM_DATA      0x22

bool ImuRaw::probe_(uint8_t addr, uint8_t reg, uint8_t expect) {
    Wire.beginTransmission(addr);
    Wire.write(reg);
    if (Wire.endTransmission(false) != 0) return false;
    if (Wire.requestFrom(addr, (uint8_t)1) != 1) return false;
    return Wire.read() == expect;
}

bool ImuRaw::wakeMpu6050_() {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(MPU_PWR1);
    Wire.write(0x00);                 // 唤醒；量程保持默认 ±250dps / ±2g
    return Wire.endTransmission() == 0;
}

bool ImuRaw::initLsm6ds3_() {
    // CTRL1_XL：ODR=104Hz(0x40)，FS=±2g(0x00)
    Wire.beginTransmission(addr_);
    Wire.write(LSM_CTRL1_XL);
    Wire.write(0x40);
    if (Wire.endTransmission() != 0) return false;
    // CTRL2_G：ODR=104Hz(0x40)，FS=±250dps(0x00)
    Wire.beginTransmission(addr_);
    Wire.write(LSM_CTRL2_G);
    Wire.write(0x40);
    return Wire.endTransmission() == 0;
}

bool ImuRaw::begin(int sda, int scl) {
    Wire.begin(sda, scl);
    Wire.setClock(400000);
    delay(50);

    // 1) 探测 MPU6050
    if (probe_(MPU_ADDR, MPU_WHOAMI, 0x68)) {
        if (wakeMpu6050_()) {
            chip_ = 1; addr_ = MPU_ADDR; ok_ = true;
            delay(100);
            return true;
        }
    }
    // 2) 探测 LSM6DS3（两个可能地址、两个可能 WHO_AM_I 值）
    const uint8_t addrs[2]   = {LSM_ADDR0, LSM_ADDR1};
    const uint8_t whoamis[2] = {0x6A, 0x69};    // TR-C=0x6A, 原版=0x69
    for (int a = 0; a < 2 && !ok_; a++)
        for (int w = 0; w < 2 && !ok_; w++)
            if (probe_(addrs[a], LSM_WHOAMI, whoamis[w])) {
                addr_ = addrs[a];
                if (initLsm6ds3_()) { chip_ = 2; ok_ = true; }
            }
    if (ok_) delay(100);
    return ok_;
}

bool ImuRaw::readMpu6050_(int16_t acc[3], int16_t gyro[3]) {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(MPU_DATA);
    if (Wire.endTransmission(false) != 0) return false;
    if (Wire.requestFrom(MPU_ADDR, (uint8_t)14) != 14) return false;
    auto rd = []() -> int16_t {   // 大端
        return (int16_t)(((int16_t)Wire.read() << 8) | (int16_t)Wire.read());
    };
    acc[0] = rd(); acc[1] = rd(); acc[2] = rd();
    rd();                          // 温度跳过
    gyro[0] = rd(); gyro[1] = rd(); gyro[2] = rd();
    return true;
}

bool ImuRaw::readLsm6ds3_(int16_t acc[3], int16_t gyro[3]) {
    Wire.beginTransmission(addr_);
    Wire.write(LSM_DATA);
    if (Wire.endTransmission(false) != 0) return false;
    if (Wire.requestFrom(addr_, (uint8_t)12) != 12) return false;
    auto rd = []() -> int16_t {   // 小端
        uint8_t lo = (uint8_t)Wire.read();
        return (int16_t)(((int16_t)Wire.read() << 8) | (int16_t)lo);
    };
    gyro[0] = rd(); gyro[1] = rd(); gyro[2] = rd();   // 0x22~0x27
    acc[0]  = rd(); acc[1]  = rd(); acc[2]  = rd();   // 0x28~0x2D
    return true;
}

bool ImuRaw::read(int16_t acc[3], int16_t gyro[3]) {
    if (!ok_) return false;
    if (chip_ == 1) return readMpu6050_(acc, gyro);
    if (chip_ == 2) return readLsm6ds3_(acc, gyro);
    return false;
}
