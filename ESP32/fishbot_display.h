/**
 * @file fishbot_display.h
 * @author fishros (fishros@foxmail.com)
 * @brief FishBot显示类定义 (PLD2026 V4: s1三档双屏联动，页与FPGA模式同步)
 */
#ifndef __FISHBOT_DISPLAY_H__
#define __FISHBOT_DISPLAY_H__
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <TimeLib.h>
#include "../fpga_link/protocol_v1.h"

enum fishbot_wifi_status_t
{
    FISHBOT_WIFI_STATUS_OK,
    FISHBOT_WIFI_STATUS_NO_FOUND,
    FISHBOT_WIFI_STATUS_PASD_ERROR,
    FISHBOT_WIFI_STATUS_WAIT_CONNECT,
    FISHBOT_WIFI_STATUS_PING_FAILED,
    FISHBOT_WIFI_STATUS_GOT_IP,
    FISHBOT_WIFI_STATUS_UNKNOW,
};

class FishBotDisplay
{
private:
    Adafruit_SSD1306 _display;

    float battery_info_;
    String version_code_;
    uint8_t display_mode_;

    uint64_t last_update_time;
    uint64_t update_interval{200};

    // 姿态（PLD2026 V3：互补滤波，单位 deg）
    float    pitch_        = 0.0f;
    float    roll_         = 0.0f;

    // 遥控器 / 状态机 (s1 拨杆切换显示页面)
    uint8_t  s1_pos_       = 3;  // 默认中位
    bool     rc_online_    = false;
    String   mode_name_    = "???";
    float    target_speed_[4] = {0}; // 四轮目标速度

    // 编码器
    int32_t enc_[4] = {0};
    // IMU
    int16_t gyro_[3] = {0};
    int16_t acc_[3]  = {0};
    // 通信
    uint32_t tx_cnt_    = 0;
    uint32_t rx_ok_     = 0;
    uint32_t rx_err_    = 0;
    bool     rx_on_     = false;
    uint32_t tx_interval_ = 0;
    uint8_t  rx_raw_[9] = {0};
    uint8_t  tx_raw_[PROTO_FRAME_LEN] = {0};

public:
    void init();
    void updateDisplay();
    void updateStartupInfo();
    void updateBatteryInfo(float &battery_info);
    void updateVersionCode(String version_code);
    void updateMotionMode(String mode) { (void)mode; }
    void updateRcDebug(bool online, bool arm, bool unlock,
                       int16_t ch0, int16_t ch1, int16_t ch2, int16_t ch3,
                       uint8_t s1, uint8_t s2,
                       float lx, float ly, float az);
    void updateStateMachine(const String &modeName, const float targetSpeed[4]);
    void updateAttitude(float pitch, float roll);   // PLD2026 V3：姿态角（deg）
    void updateCommDebug(uint32_t txCnt, uint32_t rxOk, uint32_t rxErr,
                         bool rxOn, uint32_t txInterval,
                         const int32_t enc[4],
                         const int16_t gyro[3], const int16_t acc[3],
                         const uint8_t* rxRaw, const uint8_t* txRaw);
    void updateDisplayMode(uint8_t) {}
    void updateTransMode(String) {}
    void updateCurrentTime(int64_t) {}
    void updateBaudRate(uint32_t) {}
    void updateWIFIIp(String) {}
    void updateWIFIServerIp(String) {}
    void updateWIFIInfo(String, fishbot_wifi_status_t) {}
    void updateWIFISSID(String) {}
    void updateWIFIPSWD(String) {}
    void updateBotAngular(float&) {}
    void updateBotLinear(float&) {}
    void updateUltrasoundDist(float&) {}
    String twoDigits(int digits);
    FishBotDisplay();
    ~FishBotDisplay() = default;
};

#endif