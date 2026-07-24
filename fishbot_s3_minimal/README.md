# FishBot 四驱 V2（ESP32-S3）最小工程 — PLD2026

为 PLD2026 智能小车竞赛定制的 ESP32-S3 固件：**DBus 遥控驾驶 + 编码器/IMU 采集 + V1.0 协议 100Hz 发帧给 FPGA**。不含 micro-ROS，不碰 ROS，编译快、依赖少。

> 重要：解压/存放路径**不要包含中文或空格**（PlatformIO 对非 ASCII 路径敏感）。

## 工程结构（标准 PIO）

```
fishbot_s3_minimal/
├── platformio.ini          # PIO 配置（锁定 espressif32@6.5.0，勿升级）
├── .gitignore
├── .vscode/
│   └── extensions.json     # 推荐 PlatformIO 插件
├── include/                # 头文件
│   ├── pins.h              #   全部引脚定义（改引脚只动这里）
│   ├── protocol_v1.h       #   V1.0 帧协议（结构体 + CRC8 + 发送）
│   ├── dbus.h              #   DBus 遥控器协议解析
│   ├── motor_ctrl.h        #   四驱差速混控
│   ├── imu_raw.h           #   MPU6050 原始值读取
│   └── README
├── lib/                    # 私有库目录（依赖自动下载，此目录留空）
│   └── README
├── src/                    # 源码
│   ├── main.cpp            #   主函数在这里
│   ├── dbus.cpp
│   ├── motor_ctrl.cpp
│   └── imu_raw.cpp
└── test/                   # 单元测试目录（可选）
    └── README
```

## 引脚映射（与鱼香官方固件一致）

| 功能 | GPIO |
|---|---|
| 电机 0 / 1 / 2 / 3 | 5,4 / 15,16 / 3,8 / 46,9 |
| 编码器 0 / 1 / 2 / 3 | 6,7 / 18,17 / 20,19 / 11,10 |
| IMU（I2C） | SDA=12, SCL=13 |
| 板载 LED | 48 |
| **FPGA 串口（Serial2）** | TX=21, RX=47（预留） |
| **DBus 接收机（Serial1）** | RX=2 |

## 接线

| 信号 | 接法 |
|---|---|
| ESP32 GPIO21 (TX) | → FPGA 的 uart_rxd（J4 扩展口） |
| ESP32 GND | → FPGA GND（**必须共地**） |
| DR16 接收机 信号 | → ESP32 GPIO2 |
| DR16 接收机 电源 | → 板上 5V + GND（DR16 支持 4~8.4V） |

注意：GPIO21/47/2 是从官方固件源码推出的空闲脚，**接线前用万用表确认板上确实为空**。

## 编译与烧录

1. VSCode + PlatformIO 插件，打开本工程文件夹；
2. 首次 Build（✓）会自动下载平台（约 1~2GB）和两个鱼香库，耐心等待；
3. 烧录（→）。若自动复位失败，按住板上 BOOT 键再点烧录；
4. 串口监视器 115200，应看到 `fishbot_s3_minimal ready.`。

## 遥控操作约定

| 控制 | 通道 | 说明 |
|---|---|---|
| 油门（前后） | 左摇杆上下 (ch3) | 中位死区 ±30 |
| 转向（差速） | 左摇杆左右 (ch2) | |
| **解臂开关** | s1 拨到**下** | 其他任何位置 = 停车 |
| 失联保护 | — | 200ms 无帧自动停车 |

速度上限 `MAX_SPEED=60`（满量程 ±100），在 `main.cpp` 顶部可调。

## 与 FPGA 的对接

- 协议 V1.0：34 字节帧 `AA 55 | 01 | ts(2) | enc[4] | gyro[3] | acc[3] | CRC8`，100Hz；
- 默认波特率 **115200**，联调通过后与 FPGA 一起改为 **460800**（改 `pins.h` 的 `FPGA_UART_BAUD`）；
- 验收：FPGA 的 LED0 常亮、串口助手（接 FPGA USB 串口）看到 `55 00 55` 滚动；
- 推车转动轮子，FPGA 解出的 enc 数据应随之变化（后续里程碑验证）。

## 常见问题

1. **编译报错 mcpwm.h / pcnt.h 找不到**：平台版本错了，确认 `platformio.ini` 是 `espressif32@6.5.0`（Arduino 2.x），不要用 7.x / Arduino 3.x；
2. **车轮转向反了**：改 `src/motor_ctrl.cpp` 顶部的 `MOTOR_DIR` 表，把对应电机的 `1` 改成 `-1`；
3. **左右侧反了（转向变反向）**：交换 `drive()` 里 `m[4]` 数组的左右分配；
4. **IMU 全为 0**：串口会打印 `[WARN] MPU6050 not found`，检查 I2C（12/13）；
5. **遥控无反应**：先确认 s1 拨到下（解臂）；再用监视器看 DBus 是否在线，检查接收机接线与 5V 供电。
