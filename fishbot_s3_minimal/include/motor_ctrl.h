// ============================================================================
// motor_ctrl.h —— 四驱电机控制（差速混控），基于鱼香 Esp32McpwmMotor 库
// ============================================================================
#pragma once
#include <Arduino.h>
#include <Esp32McpwmMotor.h>

class MotorCtrl {
public:
    void begin();                                // 挂载 4 个电机并停止
    void stop();                                 // 全部电机停止
    // 差速混控：throttle=油门 turn=转向，范围 [-100,100]
    void drive(int16_t throttle, int16_t turn);
    // 直接写 4 个电机速度（调试用），范围 [-100,100]
    void setRaw(const int16_t m[4]);

private:
    Esp32McpwmMotor motor_;
};
