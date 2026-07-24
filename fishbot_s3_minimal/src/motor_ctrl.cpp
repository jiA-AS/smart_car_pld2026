// ============================================================================
// motor_ctrl.cpp —— 四驱差速混控实现
// ※ 左右侧归属与方向是"按常规推测"的，上车实测后如反了，按下方的 DIR 表修正
// ============================================================================
#include "motor_ctrl.h"
#include "pins.h"

// 单电机方向修正：哪个轮转向反了，把对应的 1 改成 -1
static const int8_t MOTOR_DIR[4] = {1, 1, 1, 1};

void MotorCtrl::begin() {
    motor_.attachMotor(0, MOTOR0_IN1, MOTOR0_IN2);
    motor_.attachMotor(1, MOTOR1_IN1, MOTOR1_IN2);
    motor_.attachMotor(2, MOTOR2_IN1, MOTOR2_IN2);
    motor_.attachMotor(3, MOTOR3_IN1, MOTOR3_IN2);
    stop();
}

void MotorCtrl::stop() {
    motor_.stopMotor(-1);    // -1 = 全部电机
}

void MotorCtrl::drive(int16_t throttle, int16_t turn) {
    int16_t left  = (int16_t)constrain(throttle + turn, -100, 100);
    int16_t right = (int16_t)constrain(throttle - turn, -100, 100);
    int16_t m[4]  = {left, left, right, right};   // 0,1 左侧；2,3 右侧
    setRaw(m);
}

void MotorCtrl::setRaw(const int16_t m[4]) {
    for (int i = 0; i < 4; i++)
        motor_.updateMotorSpeed(i, m[i] * MOTOR_DIR[i]);
}
