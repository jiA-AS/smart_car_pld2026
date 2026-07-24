/**
 * @file fishbot.h
 * @author fishros (fishros@foxmail.com)
 * @brief FishBot核心类相关定义（PLD2026 无ROS版：已移除全部 micro-ROS 内容）
 * @version V1.0.0-noros
 *
 * @copyright Copyright (c) fishros.com & fishros.org.cn 2023
 *
 */
#ifndef __FISHBOT_H__
#define __FISHBOT_H__
/* ESP32 */
#include <Arduino.h>
#include <Esp32PcntEncoder.h>
#include <Esp32McpwmMotor.h>
#include <PidController.h>
#include <Kinematics.h>
#include <OneButton.h>
#include <ImuDriver.h>

#include "fishlog.h"
#include "fishbot_config.h"
#include "fishbot_display.h"
#include "fishbot_utils.h"

bool setup_fishbot();
void loop_fishbot_control();
void loop_fishbot_console(); // PLD2026: $command 串口控制台（原 transport 循环中的串口解析部分，与 micro-ROS 无关）

#endif // __FISHBOT_H__
