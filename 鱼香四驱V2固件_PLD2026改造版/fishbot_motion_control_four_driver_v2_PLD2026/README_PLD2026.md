# PLD2026 改造版固件说明（在官方 fishbot_motion_control_microros_four_driver_v2 基础上改造）

## 改了什么（全部改动一览）

只改了一个文件 + 新增三个库，官方代码其余部分（IMU 驱动、编码器驱动、运动学、micro-ROS 通信、显示、按键）**原封不动**。

| 位置 | 改动 |
|---|---|
| `src/fishbot.cpp` 顶部 | 新增 `#include "dbus.h"`、`#include "fpga_link.h"` 及两个全局对象 |
| `src/fishbot.cpp` `setup_fishbot()` 结尾 | 新增 `dbus.begin(Serial1, 38)` 与 `fpga.begin(Serial2, 41, 42, 115200, 12, 13)` |
| `src/fishbot.cpp` `loop_fishbot_control()` | 原 PID 速度环 for 循环 → 遥控器开环直驱（失联/未解臂自动停车） |
| `src/fishbot.cpp` `imu.update()` 之后 | 新增读取 4 路编码器累计计数 + `fpga.send(ticks)`（100Hz） |
| `lib/dbus/`（新增） | 大疆 DR16/DT7 DBus 协议解析（硬件反相，免外部电路） |
| `lib/imu_raw/`（新增） | IMU 原始值只读获取，MPU6050 / LSM6DS3 双芯片自适应 |
| `lib/fpga_link/`（新增） | V1.0 协议 34 字节帧组帧 + 发送（10ms 节流 = 100Hz） |

所有改动行均带 `PLD2026` 注释，全局搜索 `PLD2026` 可逐条审查。

## 传感器读取接口——零改动确认

- 编码器：仍是 `encoders[i].getTicks()`（`kinematics.update_motor_ticks(...)` 一行原样保留）
- IMU：官方 `imu.begin(12,13)` / `imu.update()` 原样保留；`imu_raw` 只是在同一 I2C 总线上**只读**原始寄存器，不初始化冲突（先探测 MPU6050 再探测 LSM6DS3，自动适配）
- 电机驱动对象 `motor`（Esp32McpwmMotor）不变，只是输入从 PID 输出换成遥控器油门

## 接线（H24 扩展排针）

| 信号 | GPIO | H24 位置 | 接到 |
|---|---|---|---|
| FPGA_UART TX | 42 | H24-1 | FPGA 排针 RX（需 3.3V bank） |
| FPGA_UART RX | 41 | H24-2 | FPGA 排针 TX |
| DR16 接收机信号 | 38 | H24-5 | 接收机 DBus 线 |
| 接收机供电 | — | H25(+5V) / H26(GND) | 接收机 VCC/GND |

## 编译

1. 用 VSCode + PlatformIO 打开本文件夹，环境 `fishbot_motion_control_four_driver_v2`
2. **首次编译警告**：`lib_deps` 里的 `micro_ros_platformio` 会从源码构建 libmicroros（colcon 流程），Windows 上耗时很长且易中断——这就是你之前遇到的"micro 出现问题"。建议：
   - 在**独立 PowerShell 窗口**运行 `pio run`，耐心等待，不要用 VSCode 任务（避免 "Operation cancelled by user"）
   - 失败重跑时**不要删 `.pio/libdeps`**，续建可复用已下载部分
3. 若报 MCPWM/PCNT legacy driver 相关错误（新版平台不兼容旧驱动），把 `platformio.ini` 的 `platform = espressif32` 改为 `platform = espressif32@6.5.0` 再编译
4. 编译成功后 `pio run -t upload` 烧录

## 上电验收顺序

1. 串口监视器 115200：应看到 `[PLD2026] IMU chip = 2`（LSM6DS3）或 `1`（MPU6050）；若为 0 检查 I2C
2. 不接遥控器：四轮不动（失控保护生效）
3. 接接收机、左拨杆拨到最下（解臂）：推左摇杆，车前进/转向；拨回中位立即停车
4. FPGA 侧 45 号工程：把 uart_rxd 约束改到排针脚后，应 100Hz 收到 `AA 55 01...` 帧，好帧回 `55 00 55` + LED0 亮

## 与 FPGA 联调要点

- 双方波特率先 115200 跑通，再同步升到 460800（改本工程 `fpga.begin(..., 460800, ...)` 与 FPGA uart_rx 的分频参数）
- 帧格式：小端 34 字节 `AA 55 | 01 | ts(2) | enc×4(16) | gyro×3(6) | acc×3(6) | CRC8`，CRC8/SMBUS(0x07) 覆盖前 33 字节
