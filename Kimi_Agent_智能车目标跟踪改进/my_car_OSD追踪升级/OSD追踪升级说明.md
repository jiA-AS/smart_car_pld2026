# my_car OSD + 追踪升级说明（PLD2026）

基于仓库最新代码（commit `2a5dddd`，含 `green_detect.v` / `tracker_ctrl.v` / 右屏识别框版 `lcd_disply.v`）实现两点需求：

1. **屏幕标注**：识别框旁显示该相机内目标位置坐标；中央偏下显示双目距离（mm）；中央偏上显示编码器/陀螺仪原始数据。
2. **丢失停车**：识别不到目标时不再原地转圈，立即静止停车，屏幕正中央显示红色"目标丢失"。

---

## 一、文件清单

### 新增（放入 `my_car/rtl/`，并在 Vivado 里 Add Sources）
| 文件 | 作用 |
|---|---|
| `新增文件/stereo_dist.v` | 双目视差测距：`dist = F_PIX × BASELINE_MM / |u_cam2 − u_cam1|`，自由运行顺序除法器 |
| `新增文件/osd_overlay.v` | AR 叠加层：cam2 绿框、双质心红十字、框旁 `(u,v)` 坐标、距离行、数据栏、"目标丢失" |
| `新增文件/osd_font.v` | 字符点阵 ROM（8×16 ASCII + 16×16 中文：编码器/陀螺仪/距离/目标丢失） |

### 替换（覆盖同名文件）
| 文件 | 位置 | 改动 |
|---|---|---|
| `替换文件/tracker_ctrl.v` | `my_car/rtl/tracker_ctrl.v` | **丢失→停车**：删除 S_LOST/S_SEARCH 转圈，丢失当拍 `mode=0, left=right=0`；上电默认停车。端口与参数不变，`sensor_link` 不用动（`SEARCH_SPD/LOST_LIM` 参数保留但弃用） |
| `替换文件/lcd_rgb_top.v` | `my_car/rtl/lcd_rgb_top/lcd_rgb_top.v` | 新增端口（cam1 质心、cam2 检测、距离、编码器/陀螺仪）；例化 `osd_overlay` 串在 `lcd_disply` 之后 |
| `替换文件/top_dual_ov5640_lcd.v` | `my_car/rtl/top_dual_ov5640_lcd.v` | 例化第二路 `green_detect`（cam_pclk_2）、`stereo_dist`；双目融合后送 tracker；`sensor_link` 解包数据接入 LCD |

### 不用动
`green_detect.v`（两路复用同一模块）、`sensor_link` 全部文件、`lcd_disply.v`（右屏红框保持）、其余原子原文件。

---

## 二、数据流

```
cam1 ─ green_detect(已有) ─┐ gd_found/gd_u/...      ┌─→ 双目融合(any_found,u_comb) ─→ sensor_link
cam2 ─ green_detect(新增) ─┘                        │    (tracker_ctrl: 丢失停车)
        │ u_cam1, u_cam2 ──→ stereo_dist(新增) ── dist_mm ─┐
ESP32 ─ sensor_link ── enc0~3, gyro ──────────────────────┤
                                                          ▼
                              lcd_rgb_top: lcd_driver → lcd_disply(右屏红框)
                                                       → osd_overlay(新增) → LCD
```

- **双目融合**：任一相机看到目标即追踪，质心取平均；丢失（两个都看不到）→ tracker 停车 + OSD 显示"目标丢失"。
- **坐标系**：检测在相机坐标（0~399），cam1=右半屏（+400 映射）、cam2=左半屏（原样），均由 OSD 内部换算。

---

## 三、屏幕布局（800×480，分辨率自适应）

```
        ┌──────────────────────────────────────┐
        │      编码器 E0:XXXXXXXX ... E3:XXXXXXXX │ ← 中央偏上 (v/8)
        │      陀螺仪 GX:XXXX GY:XXXX GZ:XXXX     │
        │                                       │
        │  ┌─┐uuu,vvv              ┌─┐uuu,vvv   │ ← cam2绿框+坐标 / cam1红框+坐标
        │  └─┘(左屏cam2)           └─┘(右屏cam1)│    质心处红十字
        │            目 标 丢 失                 │ ← 丢失时正中央红色
        │                                       │
        │           距离:1234mm                  │ ← 中央偏下 (3/4 高度)
        └──────────────────────────────────────┘
```

---

## 四、必须标定的参数

| 参数 | 位置 | 标定方法 |
|---|---|---|
| `BASELINE_MM` | 顶层 `u_stereo_dist` | 尺子量两镜头**中心距**（mm），直接填 |
| `F_PIX` | 顶层 `u_stereo_dist` | 绿灯放正前方已知距离 Z0（如 500mm），看屏显 D，则 `F_new = F_old × Z0 / D` |
| `TH_G / TH_RB` | 两个 `green_detect` | 现场光照调绿色阈值（`gd_cnt` 可接 ILA 观察） |
| `H_REF / H_ARRIVE` | `sensor_link` 内 tracker | 包围盒高度标定（原有流程，不变） |

**注意**：双目测距只在**两个相机都看到目标**时有效（否则显示 `距离:----mm`），所以两个镜头要尽量平行、朝向一致，视场重叠区才测得准。

---

## 五、验证清单

1. Vivado 添加 3 个新源文件，替换 3 个旧文件，重新综合 → 生成比特流；
2. 上电无目标：车静止，屏幕中央红字"目标丢失"，数据栏编码器/陀螺仪十六进制刷新；
3. 绿灯入视野：双屏出现识别框+红十字+坐标，"目标丢失"消失，中央偏下显示距离；拿尺核对 300/500/800mm 三点，按第四节标定 `F_PIX`；
4. 遮挡绿灯：车立即停（不转圈），"目标丢失"出现；
5. 若距离恒为 `----`：检查两相机是否都框到目标（MIN_AREA 是否过大）、视差是否 < MIN_DISP=6（目标太远时正常）。

## 六、技术备注

- `osd_overlay` 输出为**组合逻辑**（坐标打 1 拍与 `lcd_disply` 输出对齐），像素链零额外延迟，画面不会右移；若时序不通过，可把输出和 `pixel_in` 各打 1 拍，代价是整画面右移 1px。
- 所有跨时钟信号（检测结果、传感器值）在 OSD/测距模块内做了 2 级触发器同步；这些都是帧级准静态信号，安全。
- 字库用 unifont 点阵生成，要加字（如"加速度"）告诉我即可重新生成。
