/**
 * @file main.cpp
 * @author fishros (fishros@foxmail.com)
 * @brief 主函数部分（PLD2026 无ROS版：不再创建 micro-ROS 传输任务）
 * @version V1.0.0-noros
 *
 * @copyright Copyright (c) fishros.com & fishros.org.cn 2023
 *
 */
#include <Arduino.h>
#include "fishbot.h"

void setup()
{
  setup_fishbot();
}

void loop()
{
  loop_fishbot_console(); // $command 串口控制台：read_config / restart / pid_kp 等
  delay(10);              // 10ms -> loop_fishbot_control 以 100Hz 运行
  loop_fishbot_control();
}
