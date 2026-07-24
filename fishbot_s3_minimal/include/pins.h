// ============================================================================
// pins.h —— 鱼香四驱V2（ESP32-S3）引脚映射
// 电机/编码器/IMU 引脚与鱼香官方固件 fishbot.cpp 完全一致
// ============================================================================
#pragma once

//---------------------- 电机驱动（每电机 IN1/IN2 两个脚）----------------------
#define MOTOR0_IN1  5
#define MOTOR0_IN2  4
#define MOTOR1_IN1  15
#define MOTOR1_IN2  16
#define MOTOR2_IN1  3
#define MOTOR2_IN2  8
#define MOTOR3_IN1  46
#define MOTOR3_IN2  9

//---------------------- 编码器（A/B 相）----------------------
#define ENC0_A      6
#define ENC0_B      7
#define ENC1_A      18
#define ENC1_B      17
#define ENC2_A      20
#define ENC2_B      19
#define ENC3_A      11
#define ENC3_B      10

//---------------------- IMU（MPU6050，I2C）----------------------
#define IMU_SDA     12
#define IMU_SCL     13

//---------------------- 板载资源 ----------------------
#define LED_PIN     48          // 板载 LED（心跳灯）

//---------------------- 新增：FPGA 串口（Serial2）----------------------
// ※ 这两个是源码层面推出的空闲脚，接线前请用万用表确认板上确实为空！
#define FPGA_UART_TX_PIN  21    // ESP32 -> FPGA（接 FPGA 的 uart_rxd）
#define FPGA_UART_RX_PIN  47    // FPGA -> ESP32（预留，当前未使用）
#define FPGA_UART_BAUD    115200// 联调通过后，与 FPGA 端一起改为 460800

//---------------------- 新增：DBus 遥控器接收机（Serial1，仅接收）----------------------
#define DBUS_RX_PIN     2
