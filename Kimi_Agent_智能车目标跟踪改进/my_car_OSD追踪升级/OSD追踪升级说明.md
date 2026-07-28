# my_car 升级说明 V2：三模式追踪 + 单位化显示 + ESP32 对齐

覆盖四点：① ESP32 左右反修复；② 单目/双目/未识别三模式；③ 协议单位与可调参数约定；④ OLED/LCD 带单位人性化显示。

---

## 一、ESP32 左右反的根因与修复（ESP32/fishbot.cpp，替换 esp/src/）

**根因**：Match 分支原来直接写电机：
```cpp
// 原代码（错误）：左侧 = motor0+1，右侧 = motor2+3
target_motor_speed1 = left_spd;   // motor0
target_motor_speed2 = left_spd;   // motor1 ← 运动学里这是右轮！
```
而 `Kinematics::kinematic_inverse`（Remote 模式在用的同一套）的约定是 **motor0/2=左侧，motor1/3=右侧**（差速与麦轮正解公式一致：w₁、w₃ 带左轮符号）。左右各有一个轮子拿错指令，转向当然不对。

**修复**：Match 分支不再直接写电机，改成和 Remote 一样走运动学逆解，左右映射天然一致：
```cpp
float l = fpga.cmdLeft() * 0.01f, r = fpga.cmdRight() * 0.01f;   // % → -1~1
linear_x  = (l + r) * 0.5f * MATCH_LINEAR_MAX_MMS;  // mm/s
angular_z = (r - l) * 0.5f * MATCH_YAW_MAX_RADS;    // rad/s（左轮快→右转→负）
kinematics.kinematic_inverse(linear_x, 0, angular_z, ...4个电机);
```
文件顶部新增两个可调常数 `MATCH_LINEAR_MAX_MMS`（默认 600mm/s）、`MATCH_YAW_MAX_RADS`（默认 3.0），先保守后调。

**OLED 人性化**：`mode_name` 带跟随子状态直接显示：`MATCH:DUAL`（双目对接）/ `MATCH:MONO`（单目跟随）/ `MATCH:LOST`（未识别停车），走原有的 `updateStateMachine`，不用动显示类。

---

## 二、三模式识别与控制（FPGA，自动化体现在 MATCH）

| 识别情况 | tracker 状态 | V1.1 mode | 行为 |
|---|---|---|---|
| 未识别（双目都无） | S_STOP | **0** | 静止停车（不转圈），LCD 中央红字"目标丢失" |
| 单目识别（仅一路） | S_MONO | **1** | 低速跟随（`MONO_V`），方位加偏移补偿 `MONO_OFFS`（仅右路看到→目标实际更偏右） |
| 双目识别 | S_MATCH | **2** | 自动对接：距离环用双目测距 `dist_mm`，到 `DIST_ARRIVE` mm 自动停车 |

- 距离来源优先级：`stereo_dist` 双目视差（`dist_src=2`）> 单目尺寸法（`dist_src=1`，`Z = F_PIX × H_LIGHT_MM / 灯高`）> 无效。
- **`H_LIGHT_MM` 是给你留的光源尺寸参数**——光源实际高度定了直接填，单目测距即刻生效；双目都在但视差太小（远处）时也自动用它兜底。
- ESP32 端 `fpga.cmdMode()` 就能拿到 0/1/2，OLED 已据此显示子状态。

---

## 三、协议单位与可调参数约定（V1.2 补充，建议写进协议文档）

| 量 | 单位 | 说明 |
|---|---|---|
| left/right | **%**（-100~+100，int16 补码） | 100% = `MATCH_LINEAR_MAX_MMS` mm/s |
| mode | 枚举 | 0=停车 1=单目跟随 2=双目对接 |
| 编码器 enc0~3 | **cnt**（int32 累计脉冲） | LCD 带符号十进制显示 |
| 陀螺仪 | **dps**（°/s） | 原始 LSB ÷ `GYRO_LSB_PER_DPS`（MPU6050@±250dps=131；LSM6DS3≈114） |
| 距离 | **mm**（0~9999） | dist_src 区分单/双目来源 |

**FPGA 可调参数集中处**：
- `stereo_dist`：`F_PIX`、`BASELINE_MM`、`MIN_DISP`、`H_LIGHT_MM`（光源尺寸）、`H_MIN_PIX`
- `tracker_ctrl`（在 sensor_link 例化处调）：`V_MAX`、`MONO_V`、`MONO_OFFS`、`DIST_ARRIVE`、`KD_NUM`、`H_REF`/`H_ARRIVE`（退化路径）
- ESP32：`MATCH_LINEAR_MAX_MMS`、`MATCH_YAW_MAX_RADS`

---

## 四、FPGA 文件清单

| 文件 | 位置 | 说明 |
|---|---|---|
| `FPGA/新增/vision/stereo_dist.v` | `rtl/vision/` | 双目+单目双模式测距 |
| `FPGA/新增/lcd_rgb_top/osd/osd_overlay.v` | `rtl/lcd_rgb_top/osd/` | AR 叠加层 V2 |
| `FPGA/新增/lcd_rgb_top/osd/osd_font.v` | 同上 | 字库（+未识别/单目跟踪/双目对接 汉字） |
| `FPGA/替换/sensor_link/tracker_ctrl.v` | `rtl/sensor_link/` | 三模式控制器（移入 sensor_link 文件夹，层次对齐） |
| `FPGA/替换/sensor_link/sensor_link.v` | 同上 | 透传 f1/f2/距离 |
| `FPGA/替换/lcd_rgb_top/lcd_rgb_top.v` | `rtl/lcd_rgb_top/` | 新端口 + 例化 osd |
| `FPGA/替换/top_dual_ov5640_lcd.v` | `rtl/` | 第二路检测 + 测距 + 连线 |
| `ESP32/fishbot.cpp` | `esp/src/` | Match 修复 + OLED 子状态 |

**LCD 布局**：中央偏上 = `编码器 E0:+00012345 … cnt` / `陀螺仪 GX:-250 … dps`；识别框旁 = `uuu,vvvpx`；中央偏下 = `双目对接:1234mm`（绿）/ `单目跟踪:1234mm`（黄）；丢失 = 中央红字"目标丢失"。

---

## 五、标定与验证

1. `BASELINE_MM` 量两镜头中心距；`F_PIX` 用已知距离反推（`F_new = F_old × 真实距离 / 显示距离`）；
2. 光源尺寸定后填 `H_LIGHT_MM`，再校 `MONO_OFFS`（单目时的方位偏差）；
3. 上车先验证 ESP 修复：目标偏右 → 车应右转；不对就只可能是电机接线/极性，调 `MATCH_YAW_MAX_RADS` 符号；
4. 三模式切换验证：遮挡双目→"目标丢失"+停车；只露一目→`MATCH:MONO` 低速跟随；双目→`MATCH:DUAL` 自动接近到 300mm 停车。

**注意**：Vivado 添加 3 个新文件（Add Sources，别勾 Copy）；tracker_ctrl.v 若从根目录挪进 sensor_link/，先把旧条目 Remove File from Project 再按新路径添加。
