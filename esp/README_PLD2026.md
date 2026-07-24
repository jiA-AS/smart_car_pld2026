# PLD2026 无ROS版固件说明（基于官方 fishbot_motion_control_microros_four_driver_v2 改造）

## 与官方版的差异

**一、彻底移除 micro-ROS**（竞赛架构中解算与显示均在 FPGA 端，ESP32 只做传感器采集与电机执行，ROS2 通信是死重）：

| 删除内容 | 说明 |
|---|---|
| `platformio.ini` 中 `micro_ros_platformio` 依赖 | **首次编译不再触发 colcon 源码构建**，从 40 分钟缩到约 5 分钟 |
| `board_microros_transport/distro` 配置行 | 随依赖一起移除 |
| `lib/MicroRosRwm/`、`extra_packages/`、`.config/` | micro-ROS 专属，已删除文件夹 |
| `fishbot.h` 中全部 rcl/rclc/micro_ros 头文件 | 已移除 |
| `fishbot.cpp` 中节点/发布者/订阅者/服务/传输状态机 | 约 400 行 micro-ROS 代码已移除 |
| `main.cpp` 中 transport 任务 | 不再创建，单任务运行 |

**二、PLD2026 功能改造**（与上一版一致）：

| 位置 | 改动 |
|---|---|
| `setup_fishbot()` 结尾 | `dbus.begin(Serial1, 38)` + `fpga.begin(Serial2, 41, 42, 115200, 12, 13)` |
| `loop_fishbot_control()` | 原 PID 速度环 → 遥控器开环直驱（失联/未解臂自动停车） |
| `imu.update()` 之后 | 读 4 路编码器累计值 + `fpga.send(ticks)`，100Hz 发 V1.0 帧 |
| `lib/dbus/`、`lib/imu_raw/`、`lib/fpga_link/` | 新增三个库 |

**三、保留的官方功能**（原样未动）：

- 电机驱动（Esp32McpwmMotor）、编码器驱动（Esp32PcntEncoder）、IMU 驱动（ImuDriver/MPU6050_light）
- 运动学对象（编码器里程累计）、OLED 屏幕、按键（单击换页/双击/长按）、电池电压检测
- **$command 串口控制台**：115200 下可发 `$command=read_config` 查看配置、`$command=restart` 重启（已移植为 `loop_fishbot_console()`）

## 编译

1. VSCode + PlatformIO 打开本文件夹 → Build（或 PowerShell 跑 `python -m platformio run`）
2. 平台已锁定 `espressif32@6.5.0`（鱼香电机/编码器库用 legacy 驱动，新版平台必报错，请勿改回）
3. **注意先清理旧缓存**：如果之前编译过带 micro-ROS 的版本，删掉工程下的 `.pio` 文件夹再编，避免旧的 libdeps 残留

## 接线（H24 扩展排针）

| 信号 | GPIO | 接到 |
|---|---|---|
| FPGA_UART TX | 42 (H24-1) | FPGA ATK-MODULE 插座 J1 的 UART2_RXD（E13） |
| FPGA_UART RX | 41 (H24-2) | 暂悬空（联调稳定后接 J1 UART2_TXD=D16） |
| DR16 接收机信号 | 38 (H24-5) | 接收机 DBus 线 |
| 接收机供电 | H25(+5V) / H26(GND) | 接收机 VCC/GND |
| **GND** | H26 | **必须与 FPGA 共地** |

## 上电验收顺序

1. 串口监视器 115200：看到 `[PLD2026] IMU chip = 2`（LSM6DS3）或 `1`（MPU6050）
2. 不接遥控器：四轮不动（失控保护）
3. 左拨杆最下（解臂）→ 推左摇杆：前进/转向；拨回：立即停车
4. FPGA 侧：45 工程改好 E13 约束并接线后，100Hz 收 `AA 55 01...` 帧，回 `55 00 55` + LED0
