/**
 * @file fishbot_display.cpp
 * @author fishros (fishros@foxmail.com)
 * @brief FishBotOLED显示控制类
 * @version V1.0.0
 * @date 2023-01-05
 *
 * @copyright Copyright (c) fishros.com & fishros.org.cn 2023
 *
 */
#include "fishbot_display.h"

void FishBotDisplay::init()
{
    Wire.begin(12, 13, 400000UL);
    _display = Adafruit_SSD1306(128, 64, &Wire);
    _display.begin(SSD1306_SWITCHCAPVCC, 0x3C); // 设置OLED的I2C地址
    _display.clearDisplay();                    // 清空屏幕
    _display.setTextSize(1);                    // 设置字体大小
    _display.setTextColor(SSD1306_WHITE);       // 设置字体颜色
    _display.setCursor(0, 0);                   // 设置开始显示文字的坐标
    _display.print("    ");
    _display.println(version_code_); // 输出的字符
    _display.println("");
    _display.println("syetem starting...");
    _display.display();
}

FishBotDisplay::FishBotDisplay()
{
}

void FishBotDisplay::updateDisplay()
{
    if (millis() - last_update_time > update_interval)
    {
        last_update_time = millis();
        _display.clearDisplay();
        _display.setCursor(0, 0);
        _display.setTextSize(1);
        _display.setTextColor(SSD1306_WHITE);

        // ==================== PLD2026: 统一 RC 调试页面（不使用 WiFi/UDP） ====================
        // 行1: 版本 + RC 状态
        _display.print(version_code_);
        _display.print(" ");
        if (!rc_online_)
            _display.println("RC:LOST");
        else if (!rc_arm_)
            _display.println("RC: SAFE");
        else if (!rc_unlock_)
            _display.println("RC: LOCK");
        else
            _display.println("RC: GO!");
        // 行2: 拨杆 s1/s2
        _display.print("S1:");
        _display.print(rc_s1_ == 1 ? "UP " : (rc_s1_ == 2 ? "DN " : "MID"));
        _display.print(" S2:");
        _display.println(rc_s2_ == 1 ? "UP" : (rc_s2_ == 2 ? "DN" : "MID"));
        // 行3: ch0 ch1 (右摇杆)
        _display.print("ch0:");
        _display.print(rc_ch0_);
        _display.print(" ch1:");
        _display.println(rc_ch1_);
        // 行4: ch2 ch3 (左摇杆)
        _display.print("ch2:");
        _display.print(rc_ch2_);
        _display.print(" ch3:");
        _display.println(rc_ch3_);
        // 行5: 运动学输入 LX / LY
        _display.print("LX:");
        _display.print(rc_lx_, 0);
        _display.print(" LY:");
        _display.println(rc_ly_, 0);
        // 行6: AZ + 电池电压
        _display.print("AZ:");
        _display.print(rc_az_, 2);
        _display.print(" V:");
        _display.println(battery_info_, 1);
        // 行7: 运动模式
        _display.print("motion:");
        _display.println(motion_mode_);
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
void FishBotDisplay::updateUltrasoundDist(float &ultrasound_distance)
{
    ultrasound_distance_ = ultrasound_distance;
}
void FishBotDisplay::updateBotAngular(float &bot_angular)
{
    bot_angular_ = bot_angular;
}
void FishBotDisplay::updateBotLinear(float &bot_linear)
{
    bot_linear_ = bot_linear;
}
void FishBotDisplay::updateTransMode(String mode)
{
    mode_ = mode;
}
void FishBotDisplay::updateWIFIServerIp(String server_ip)
{
    wifi_server_ip_ = server_ip;
}
void FishBotDisplay::updateWIFIIp(String ip)
{
    if (wifi_ip_ != ip)
    {
        wifi_ip_ = ip;
    }
    // 判断LocalIP 和 Server IP 是否在同一个子网，不在则 WARN
}
void FishBotDisplay::updateWIFIInfo(String info, fishbot_wifi_status_t status)
{
    if (wifi_info_ != info)
    {
        wifi_info_ = info;
    }
    wifi_status_ = status;
}
void FishBotDisplay::updateCurrentTime(int64_t current_time_)
{
    current_time = current_time_;
}
String FishBotDisplay::twoDigits(int digits)
{
    if (digits < 10)
    {
        String i = '0' + String(digits);
        return i;
    }
    else
    {
        return String(digits);
    }
}

void FishBotDisplay::updateBaudRate(uint32_t baudrate)
{
    baudrate_ = baudrate;
}
void FishBotDisplay::updateMotionMode(String mode)
{
    motion_mode_ = mode;
}

void FishBotDisplay::updateRcDebug(bool online, bool arm, bool unlock,
                                   int16_t ch0, int16_t ch1, int16_t ch2, int16_t ch3,
                                   uint8_t s1, uint8_t s2,
                                   float lx, float ly, float az)
{
    rc_online_ = online;
    rc_arm_    = arm;
    rc_unlock_ = unlock;
    rc_ch0_ = ch0; rc_ch1_ = ch1; rc_ch2_ = ch2; rc_ch3_ = ch3;
    rc_s1_  = s1;  rc_s2_  = s2;
    rc_lx_  = lx;  rc_ly_  = ly;  rc_az_  = az;
}

void FishBotDisplay::updateStartupInfo()
{
    String timenow = String(hour()) + ":" + twoDigits(minute()) + ":" + twoDigits(second());
    last_update_time = millis();
    _display.clearDisplay();
    _display.setCursor(0, 0);
    _display.print("    ");
    _display.println(version_code_); // 输出的字符
    _display.print("mode:");
    _display.println(mode_);
    _display.print("voltage:");
    _display.println(battery_info_);
    _display.println("");
    _display.println("syetem starting...");
    _display.display();
}

void FishBotDisplay::updateDisplayMode(uint8_t display_mode)
{
    display_mode_ = display_mode;
}

void FishBotDisplay::updateWIFISSID(String ssid)
{
    wifi_ssid_ = ssid;
}
void FishBotDisplay::updateWIFIPSWD(String pswd)
{
    wifi_pswd_ = pswd;
}