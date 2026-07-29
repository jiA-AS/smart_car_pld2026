# ESP32-S3-Matrix 手机遥控点阵

板卡：微雪 ESP32-S3-Matrix（板载 8×8 共 64 颗 WS2812，数据脚 **GPIO14**）

功能：ESP32-S3 开 WiFi 热点 + 网页服务器，手机浏览器直接控制点阵
（红 / 绿 / 蓝 / 白 / 彩虹流动 / 关闭），无需装 APP、无需路由器。

## 使用方法（VSCode + Espressif IDF 扩展）

1. 解压后用 VSCode **打开本文件夹**（Open Folder）
2. 底栏确认 Target 为 **esp32s3**（`sdkconfig.defaults` 已预设，一般不用动）
3. `Ctrl+E B` 构建 —— 首次会自动从组件仓库拉取 `espressif/led_strip`
4. `Ctrl+E F` 烧录（原生 USB 下载；失败则按住 BOOT 再按 RESET 进下载模式）
5. `Ctrl+E M` 监视，看到 `热点已开启` 日志即成功

## 手机控制

1. 手机 WiFi 连接 **ESP32S3-Matrix**，密码 `12345678`
2. 浏览器打开 **192.168.4.1**
3. 点按钮控制

## 注意事项

- `LED_VAL` 已限制在 30：官方明确警告满亮度会过热损坏板子，调高不要超过 80
- 加新灯效：在 `mode` 加分支 + 任务，网页里加一个按钮即可
- 若 IDF 版本为 4.x，把 `idf_component.yml` 中 led_strip 版本改为 `^1.0`

## 目录结构

```
matrix_led/
├── CMakeLists.txt        工程根构建文件
├── sdkconfig.defaults    预设目标 esp32s3
├── main/
│   ├── CMakeLists.txt    组件注册与依赖
│   ├── idf_component.yml led_strip 组件依赖
│   └── main.c            全部逻辑：WS2812 + SoftAP + HTTP + 彩虹任务
└── README.md
```
