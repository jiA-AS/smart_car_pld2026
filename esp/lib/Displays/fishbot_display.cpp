/**
 * @file fishbot_display.cpp
 * @brief PLD2026: s1拨杆切换显示——上=接收数据, 中=发送数据
 */
#include "fishbot_display.h"

static void printHex(Adafruit_SSD1306 &d, uint8_t v) {
    if (v < 0x10) d.print('0');
    d.print(v, HEX);
}

void FishBotDisplay::init()
{
    Wire.begin(12, 13, 400000UL);
    _display = Adafruit_SSD1306(128, 64, &Wire);
    _display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
    _display.clearDisplay();
    _display.setTextSize(1);
    _display.setTextColor(SSD1306_WHITE);
    _display.setCursor(0, 0);
    _display.print("    ");
    _display.println(version_code_);
    _display.println("");
    _display.println("syetem starting...");
    _display.display();
}

FishBotDisplay::FishBotDisplay() {}

void FishBotDisplay::updateDisplay()
{
    if (millis() - last_update_time > update_interval)
    {
        last_update_time = millis();
        _display.clearDisplay();
        _display.setCursor(0, 0);
        _display.setTextSize(1);
        _display.setTextColor(SSD1306_WHITE);

        // ---- s1_pos_: 1=上, 3=中, 2=下 ----
        if (s1_pos_ == 1) {
            // ============ 左拨上：显示接收数据 (FPGA → ESP32) ============
            // 行1: 版本 + 状态机 + RX在线
            _display.print(version_code_);
            _display.print(" ");
            _display.print(mode_name_);
            _display.print(" R:");
            if (!rx_on_)
                _display.println("NO");
            else
                _display.println(rx_ok_);

            // 行2: 下行原始帧 (9字节HEX)
            _display.print("RX:");
            for (int i = 0; i < 9; i++) printHex(_display, rx_raw_[i]);

            // 行3: 下行 mode + left + right (从原始帧解析)
            // rx_raw_[3]=mode, rx_raw_[4..5]=left_speed (i16 LE), rx_raw_[6..7]=right_speed
            int16_t left  = (int16_t)(rx_raw_[4] | (rx_raw_[5] << 8));
            int16_t right = (int16_t)(rx_raw_[6] | (rx_raw_[7] << 8));
            _display.print("M:");
            _display.print(rx_raw_[3]);
            _display.print(" L:");
            _display.print(left);
            _display.print(" R:");
            _display.print(right);
            _display.println(" %");

            // 行4~5: FPGA 模式下四轮目标速度 (来自运动学解算)
            _display.print("T0:");
            _display.print((int)target_speed_[0]);
            _display.print(" T1:");
            _display.println((int)target_speed_[1]);
            _display.print("T2:");
            _display.print((int)target_speed_[2]);
            _display.print(" T3:");
            _display.println((int)target_speed_[3]);

            // 行6: TX计数 + TX间隔
            _display.print("TX:");
            _display.print(tx_cnt_);
            _display.print(" dt:");
            _display.print(tx_interval_);
            _display.println("ms");

            // 行7~8: 编码器 enc0~enc3 (确认电机真实转动)
            _display.print("E0:");
            _display.print(enc_[0]);
            _display.print(" E1:");
            _display.println(enc_[1]);
            _display.print("E2:");
            _display.print(enc_[2]);
            _display.print(" E3:");
            _display.println(enc_[3]);
        }
        else if (s1_pos_ == 3) {
            // ============ 左拨中：显示发送数据 (ESP32 → FPGA) ============
            // 行1: 版本 + 状态机 + TX/RX
            _display.print(version_code_);
            _display.print(" ");
            _display.print(mode_name_);
            _display.print(" T:");
            _display.print(tx_cnt_);
            _display.print(" R:");
            if (!rx_on_)
                _display.println("NO");
            else
                _display.println(rx_ok_);

            // 行2: 编码器 enc0 enc1
            _display.print("E0:");
            _display.print(enc_[0]);
            _display.print(" E1:");
            _display.println(enc_[1]);

            // 行3: 编码器 enc2 enc3
            _display.print("E2:");
            _display.print(enc_[2]);
            _display.print(" E3:");
            _display.println(enc_[3]);

            // 行4: 陀螺仪 gyro_x gyro_y gyro_z
            _display.print("GX:");
            _display.print(gyro_[0]);
            _display.print(" GY:");
            _display.print(gyro_[1]);
            _display.print(" GZ:");
            _display.println(gyro_[2]);

            // 行5: 加速度 acc_x acc_y acc_z
            _display.print("AX:");
            _display.print(acc_[0]);
            _display.print(" AY:");
            _display.print(acc_[1]);
            _display.print(" AZ:");
            _display.println(acc_[2]);

            // 行6: 上行帧前10字节 (AA 55 版本 timestamp enc0[0..3] enc0[0..1高])
            for (int i = 0; i < 10; i++) printHex(_display, tx_raw_[i]);

            // 行7: 上行帧第11~18字节 + 发送间隔
            for (int i = 10; i < 18; i++) printHex(_display, tx_raw_[i]);
            _display.print(" ");
            _display.print(tx_interval_);
            _display.println("ms");

            // 行8: 下行帧完整9字节
            _display.print("RX:");
            for (int i = 0; i < 9; i++) printHex(_display, rx_raw_[i]);
        }
        else {
            // 左拨下：与中相同 (备用)
            _display.print(version_code_);
            _display.print(" ");
            _display.print(mode_name_);
            _display.print(" T:");
            _display.print(tx_cnt_);
            _display.print(" R:");
            if (!rx_on_) _display.println("NO");
            else _display.println(rx_ok_);
            _display.print("E0:");
            _display.print(enc_[0]);
            _display.print(" E1:");
            _display.println(enc_[1]);
            _display.print("E2:");
            _display.print(enc_[2]);
            _display.print(" E3:");
            _display.println(enc_[3]);
            _display.print("GX:");
            _display.print(gyro_[0]);
            _display.print(" GY:");
            _display.print(gyro_[1]);
            _display.print(" GZ:");
            _display.println(gyro_[2]);
            _display.print("RX:");
            for (int i = 0; i < 9; i++) printHex(_display, rx_raw_[i]);
        }

        _display.display();
    }
}

void FishBotDisplay::updateVersionCode(String version_code)
{
    version_code_ = version_code;
}

void FishBotDisplay::updateBatteryInfo(float &battery_info)
{
    battery_info_ = battery_info;
}

void FishBotDisplay::updateStartupInfo()
{
    String timenow = String(hour()) + ":" + twoDigits(minute()) + ":" + twoDigits(second());
    last_update_time = millis();
    _display.clearDisplay();
    _display.setCursor(0, 0);
    _display.print("    ");
    _display.println(version_code_);
    _display.print("voltage:");
    _display.println(battery_info_);
    _display.println("");
    _display.println("syetem starting...");
    _display.display();
}

String FishBotDisplay::twoDigits(int digits)
{
    if (digits < 10) return "0" + String(digits);
    return String(digits);
}

void FishBotDisplay::updateRcDebug(bool online, bool arm, bool unlock,
                                   int16_t ch0, int16_t ch1, int16_t ch2, int16_t ch3,
                                   uint8_t s1, uint8_t s2,
                                   float lx, float ly, float az)
{
    (void)arm; (void)unlock; (void)ch0; (void)ch1; (void)ch2; (void)ch3;
    (void)s2; (void)lx; (void)ly; (void)az;
    rc_online_ = online;
    s1_pos_    = s1;   // 1=上, 3=中, 2=下 —— 控制显示页面
}

void FishBotDisplay::updateStateMachine(const String &modeName, const float targetSpeed[4])
{
    mode_name_ = modeName;
    memcpy(target_speed_, targetSpeed, sizeof(target_speed_));
}

void FishBotDisplay::updateCommDebug(uint32_t txCnt, uint32_t rxOk, uint32_t rxErr,
                                     bool rxOn, uint32_t txInterval,
                                     const int32_t enc[4],
                                     const int16_t gyro[3], const int16_t acc[3],
                                     const uint8_t* rxRaw, const uint8_t* txRaw)
{
    tx_cnt_ = txCnt;
    rx_ok_  = rxOk;
    rx_err_ = rxErr;
    rx_on_  = rxOn;
    tx_interval_ = txInterval;
    memcpy(enc_,  enc,  sizeof(enc_));
    memcpy(gyro_, gyro, sizeof(gyro_));
    memcpy(acc_,  acc,  sizeof(acc_));
    if (rxRaw) memcpy(rx_raw_, rxRaw, 9);
    if (txRaw) memcpy(tx_raw_, txRaw, PROTO_FRAME_LEN);
}