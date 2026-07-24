// ============================================================================
// dbus.cpp —— DBus 协议解析实现
// 帧同步策略：利用帧间 >3ms 的空隙对齐（18字节帧本体仅约 2ms）
// ============================================================================
#include "dbus.h"

void DbusReceiver::begin(HardwareSerial &serial, int rxPin) {
    serial_ = &serial;
    // 100000bps 8E1，RX 反相（第 5 个参数 invert=true），TX 不用
    serial.begin(100000, SERIAL_8E1, rxPin, -1, true);
}

void DbusReceiver::update() {
    while (serial_->available()) {
        uint8_t  b   = (uint8_t)serial_->read();
        uint32_t now = micros();
        if (now - lastByteUs_ > 3000) idx_ = 0;   // 字节间隔 >3ms：新帧开始
        lastByteUs_ = now;
        if (idx_ < DBUS_FRAME_LEN) buf_[idx_++] = b;
        if (idx_ == DBUS_FRAME_LEN) {
            if (parseFrame_(buf_)) lastFrameMs_ = millis();
            idx_ = 0;
        }
    }
}

bool DbusReceiver::isOnline() const {
    return (millis() - lastFrameMs_) <= DBUS_TIMEOUT_MS;
}

bool DbusReceiver::parseFrame_(const uint8_t *f) {
    DbusData d;
    // 标准 DR16 位解包（4×11bit 通道 + 2×2bit 开关）
    d.ch[0] = ((int16_t)f[0]        | ((int16_t)f[1] << 8)) & 0x07FF;
    d.ch[1] = (((int16_t)f[1] >> 3) | ((int16_t)f[2] << 5)) & 0x07FF;
    d.ch[2] = (((int16_t)f[2] >> 6) | ((int16_t)f[3] << 2) | ((int16_t)f[4] << 10)) & 0x07FF;
    d.ch[3] = (((int16_t)f[4] >> 1) | ((int16_t)f[5] << 7)) & 0x07FF;
    d.s1    = (uint8_t)(((f[5] >> 4) & 0x0C) >> 2);
    d.s2    = (uint8_t)((f[5] >> 4) & 0x03);
    // 合法性检查：任一通道超出范围则丢弃整帧
    for (int i = 0; i < 4; i++)
        if (d.ch[i] < 200 || d.ch[i] > 1800) return false;
    data_ = d;
    return true;
}
