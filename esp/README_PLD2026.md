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

**二、PLD2026 功能改造**（V4 三档双屏联动）：

| 版本 | 位置 | 改动 |
|---|---|---|
| V1 | `setup_fishbot()` 结尾 | `dbus.begin(Serial1, 38)` + `fpga.begin(Serial2, 41, 42, 115200, 12, 13)` |
| V1 | `loop_fishbot_control()` | 原 PID 速度环 → 遥控器开环直驱（失联/未解臂自动停车） |
| V1 | `imu.update()` 之后 | 读 4 路编码器累计值 + `fpga.send(ticks)`，100Hz 发 V1.0 帧 |
| V1 | `lib/dbus/`、`lib/imu_raw/`、`lib/fpga_link/` | 新增三个库 |
| V3 | `loop_fishbot_control()` | 互补滤波姿态解算（pitch/roll），送 OLED 姿态页 |
| **V4** | **协议升级 V1.0→V1.2** | **上行帧 34→35 字节，版本 0x01→0x03，新增 disp_mode 字节** |
| **V4** | **`fpga.send(ticks, dispMode)`** | **send() 新增 dispMode 参数，携带左拨杆 s1 档位** |
| **V4** | **`fishbot.cpp` s1→模式映射** | **s1上=0视角 / s1中=1轨迹 / s1下=2调试，失联强制 0** |
| **V4** | **`fishbot_display.cpp` 三页重排** | **上=[VIEW]接收页 / 中=[TRK]姿态页 / 下=[DBG]发送页** |
| **V4** | **`updateRcDebug()` 失联回视角** | **遥控器失联时强制回视角页（s1 数据不可信）** |

**三、保留的官方功能**（原样未动）：

- 电机驱动（Esp32McpwmMotor）、编码器驱动（Esp32PcntEncoder）、IMU 驱动（ImuDriver/MPU6050_light）
- 运动学对象（编码器里程累计）、OLED 屏幕、按键（单击换页/双击/长按）、电池电压检测
- **$command 串口控制台**：115200 下可发 `$command=read_config` 查看配置、`$command=restart` 重启（已移植为 `loop_fishbot_console()`）

## 协议版本

当前使用 **V1.2 上行协议**（35 字节，版本 0x03），与旧版 V1.0（34 字节，版本 0x01）**互不兼容**。

```
V1.0（34B）：AA 55 | 01 | ts(2) | enc×16 | gyro×6 | acc×6         | CRC8(31B)
V1.2（35B）：AA 55 | 03 | ts(2) | enc×16 | gyro×6 | acc×6 | mode(1) | CRC8(32B)
```

- 版本字节 0x01→0x03，CRC 覆盖 31→32 字节；
- **ESP 和 FPGA 必须同时更新**，只更一侧 → 版本/CRC 全拒 → FPGA 收不到任何帧；
- 下行 V1.1（FPGA→ESP，9 字节）不变。

## 三档双屏联动

遥控器左拨杆 s1 同时切换 FPGA 的 LCD 屏和 ESP32 的 OLED 屏：

| s1 档位 | 模式值 | FPGA LCD 屏 | ESP OLED 屏 |
|---|---|---|---|
| 上 | 0 视角 | 双目画面 + 全 HUD（距离/TTC/识别框/姿态速度行） | 接收页 `[VIEW]`：下行指令 mode/L/R + 四轮目标速度 |
| 中 | 1 轨迹 | **轨迹仪表盘突出**：窗外画面压暗一半 + 窗框青色高亮，右上"轨迹"标签 | 姿态页 `[TRK]`：大字 P/R(deg) + 轮速 + 编码器 |
| 下 | 2 调试 | 夜间阈值（弱光放宽）+ 左上 G1/G2 像素计数调试行 + 右上"夜间"标签 | 发送页 `[DBG]`：上行帧 HEX + IMU 原始值 + 链路计数 |

- 遥控器失联：ESP 端强制发模式 0，OLED 回视角页；
- ESP 不在线（0.5s 无好帧）：FPGA 自动退回 KEY0 按键循环（0→1→2），遥控恢复即夺回。

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
4. **OLED 三页测试**：s1 上/中/下 → `[VIEW]`/`[TRK]`/`[DBG]` 三页切换
5. **FPGA 侧**：V1.2 工程烧录后，100Hz 收 `AA 55 03...` 帧（35 字节），回 `55 AA 02...` + LED0
6. **双屏联动**：s1 中档 → FPGA LCD 窗外变暗 + 轨迹窗青框 + 右上"轨迹"；s1 下档 → 左上 G1/G2 + 右上"夜间"
7. **兜底测试**：拔掉 ESP→FPGA 的 TX 线（或关 ESP）0.5s 后，按 KEY0 应能循环切档；插回立刻恢复遥控档
8. **失联测试**：关遥控器 → OLED 回视角页、FPGA 回模式 0、车停车