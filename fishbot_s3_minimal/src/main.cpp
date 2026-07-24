// ============================================================================
// main.cpp —— FishBot 四驱V2 最小工程主程序
// 三大任务：
//   1. DBus 遥控驾驶（失联/未解臂 -> 立即停车）
//   2. 编码器 + IMU 采集
//   3. V1.0 协议 100Hz 发帧给 FPGA
// ============================================================================
#include <Arduino.h>
#include <Esp32PcntEncoder.h>
#include "pins.h"
#include "protocol_v1.h"
#include "dbus.h"
#include "motor_ctrl.h"
#include "imu_raw.h"

//---------------------- 遥控器配置（按需修改）----------------------
#define THROTTLE_CH   3     // 油门通道：左摇杆上下
#define TURN_CH       2     // 转向通道：左摇杆左右
#define ARM_S1_VALUE  3     // s1 拨到此值（下）= 解臂，其余位置 = 停车
#define DEADZONE      30    // 摇杆死区
#define MAX_SPEED     60    // 速度上限（满量程 ±100，先保守用 60）

Esp32PcntEncoder encoders[4];
DbusReceiver     dbus;
MotorCtrl        motors;
ImuRaw           imu;

uint32_t lastSendMs = 0;
uint16_t sendCnt    = 0;

// 摇杆通道值(364~1684,中位1024) -> 速度(-MAX_SPEED~+MAX_SPEED)
static int16_t mapChannel(int16_t v) {
    int32_t x = (int32_t)constrain(v, DBUS_CH_MIN, DBUS_CH_MAX) - DBUS_CH_MID;
    if (abs(x) < DEADZONE) return 0;
    return (int16_t)(x * MAX_SPEED / 660);
}

void setup() {
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    Serial.begin(115200);                                  // USB 调试口
    Serial2.begin(FPGA_UART_BAUD, SERIAL_8N1,
                  FPGA_UART_RX_PIN, FPGA_UART_TX_PIN);     // -> FPGA
    dbus.begin(Serial1, DBUS_RX_PIN);                      // <- 遥控器接收机
    motors.begin();

    if (!imu.begin(IMU_SDA, IMU_SCL))
        Serial.println("[WARN] MPU6050 not found, IMU data will be 0");

    encoders[0].init(0, ENC0_A, ENC0_B);
    encoders[1].init(1, ENC1_A, ENC1_B);
    encoders[2].init(2, ENC2_A, ENC2_B);
    encoders[3].init(3, ENC3_A, ENC3_B);

    Serial.println("fishbot_s3_minimal ready.");
}

void loop() {
    dbus.update();

    //---------------- 1. 遥控驾驶 ----------------
    if (dbus.isOnline() && dbus.data().s1 == ARM_S1_VALUE) {
        int16_t throttle = mapChannel(dbus.data().ch[THROTTLE_CH]);
        int16_t turn     = mapChannel(dbus.data().ch[TURN_CH]);
        motors.drive(throttle, turn);
    } else {
        motors.stop();    // 失联或未解臂：无条件停车（安全红线）
    }

    //---------------- 2&3. 100Hz 采集并发帧 ----------------
    if (millis() - lastSendMs >= 10) {
        lastSendMs = millis();

        int32_t enc[4];
        for (int i = 0; i < 4; i++)
            enc[i] = (int32_t)encoders[i].getTicks();

        static int16_t acc[3]  = {0};
        static int16_t gyro[3] = {0};
        imu.read(acc, gyro);   // 失败时保持上一帧的值

        protocol_send_frame(Serial2, enc, gyro, acc);

        // 心跳灯：约 2Hz 闪烁表示程序在跑
        if (++sendCnt >= 50) {
            sendCnt = 0;
            digitalWrite(LED_PIN, !digitalRead(LED_PIN));
        }
    }
}
