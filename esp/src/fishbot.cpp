/**
 * @file fishbot.cpp
 * @author fishros (fishros@foxmail.com)
 * @brief 核心文件，硬件控制（PLD2026 无ROS版：已移除全部 micro-ROS 通信代码）
 * @version V1.0.0-noros
 * @date 2023-01-04
 *
 * @copyright Copyright (c) fishros.com & fishros.org.cn 2023
 *
 * PLD2026 说明：
 *   本版删除了 micro-ROS 节点/发布者/订阅者/服务/传输状态机的全部代码
 *   （竞赛架构中解算与显示均在 FPGA 端，ESP32 只做传感器采集与电机执行）。
 *   保留：电机/编码器/IMU 驱动、运动学对象、屏幕显示、按键、电池检测、
 *         $command 串口控制台（loop_fishbot_console）、PLD2026 遥控与 FPGA 链路。
 */
#include "fishbot.h"
#include "dbus.h"      // PLD2026: DT7/DR16 遥控器接收（DBus 协议）
#include "fpga_link.h" // PLD2026: ESP32 -> FPGA 传感器帧发送（V1.0 协议）

DbusReceiver dbus; // PLD2026: 遥控器接收机对象
FpgaLink     fpga; // PLD2026: 通向 FPGA 的传感器帧发送对象

/*========================FishBot控制相关====================*/
PidController pid_controller[4]; // PID 控制器数组（PLD2026 遥控开环下未使用，保留供控制台调参）
Esp32PcntEncoder encoders[4];    // ESP32 PCNT 编码器数组，读取四个电机的旋转角度
Esp32McpwmMotor motor;           // ESP32 MCPWM 电机对象，控制四个电机
Kinematics kinematics;           // 机器人的运动学模型（编码器里程累计仍由它维护）
FishBotConfig config;            // 配置信息（NVS 存储）
FishBotDisplay display;          // OLED 状态显示
float battery_voltage;           // 电池电压
OneButton button(0, true);       // 板载按键（GPIO0）
MPU6050 mpu(Wire);               // MPU6050 对象（官方 IMU 驱动，原样保留）
ImuDriver imu(mpu);              // Imu 对象（官方 IMU 驱动，原样保留）
imu_t imu_data;                  // IMU 数据对象

// 长按按键：切换 差速/麦克纳姆 运动模式并重启
void longPressClick()
{
    fishlog_debug("key", "longPressClick() detected.");
    if (config.motion_mode() == CONFIG_MOTION_MODE_MECANUM)
    {
        config.config("motion", CONFIG_MOTION_MODE_DIFFERENTIAL);
    }
    else
    {
        config.config("motion", CONFIG_MOTION_MODE_MECANUM);
    }
    esp_restart();
}

// 双击按键：切换 microros_mode 配置项并重启（无ROS版下仅为保留的官方行为，配置项不影响运行）
void doubleClick()
{
    fishlog_debug("key", "doubleClick() detected.");
    if (config.microros_transport_mode() == CONFIG_TRANSPORT_MODE_WIFI_UDP_CLIENT)
    {
        config.config("microros_mode", "serial");
    }
    else
    {
        config.config("microros_mode", "udp_client");
    }
    esp_restart();
}

// 单击按键：切换屏幕显示页面
void oneClick()
{
    static uint8_t display_mode = 0;
    display.updateDisplayMode(display_mode++);
}

bool setup_fishbot()
{
    // 1.初始化
    Serial.begin(115200);
    fishlog_set_target(Serial);
    config.init(CONFIG_NAME_NAMESPACE);
    Serial.println(FIRST_START_TIP);
    Serial.println(config.config_str());
    // 初始化LED
    pinMode(48, OUTPUT);
    // 初始化显示
    display.updateVersionCode(VERSION_CODE);
    display.init();
    display.updateTransMode(config.microros_transport_mode());
    display.updateBaudRate(config.serial_baudrate());
    display.updateStartupInfo();
    display.updateMotionMode(config.motion_mode());
    // 初始化按键
    button.attachDoubleClick(doubleClick);
    button.attachClick(oneClick);
    button.attachLongPressStop(longPressClick);
    // 初始化IMU
    imu.begin(12, 13);
    // 2.设置IO 电机&编码器
    motor.attachMotor(0, 5, 4);
    motor.attachMotor(1, 15, 16);
    motor.attachMotor(2, 3, 8);
    motor.attachMotor(3, 46, 9);
    encoders[0].init(0, 6, 7);
    encoders[1].init(1, 18, 17);
    encoders[2].init(2, 20, 19);
    encoders[3].init(3, 11, 10);
    // 3.设置PID
    for (int i = 0; i < 4; i++)
    {
        pid_controller[i].update_target(0.0);
        pid_controller[i].update_pid(config.kinematics_pid_kp(), config.kinematics_pid_ki(), config.kinematics_pid_kd());
        pid_controller[i].out_limit(-config.kinematics_pid_out_limit(), config.kinematics_pid_out_limit());
        kinematics.set_motor_param(i, (config.motion_mode() == CONFIG_MOTION_MODE_MECANUM ? config.motor_param_mspeed_factor() : config.motor_param_dspeed_factor()) * 1000);
    }
    // 4.设置运动学参数
    kinematics.set_kinematic_calib(config.kinematics_calib_mx(), config.kinematics_calib_dx(), config.kinematics_calib_myaw(), config.kinematics_calib_dyaw());
    kinematics.set_motion_model(config.motion_mode() == CONFIG_MOTION_MODE_MECANUM ? MOTION_OMNIDIRECTIONAL : MOTION_DIFFERENTIAL_DRIVE);
    kinematics.set_kinematic_param(config.kinematics_wheel_distance());
    kinematics.set_kinematic_param(config.kinematics_wheel_distance_a(), config.kinematics_wheel_distance_b());
    // 5.设置电压测量引脚
    pinMode(14, INPUT);
    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);
    battery_voltage = 5.02 * ((float)analogReadMilliVolts(14) * 1e-3);
    // ================= PLD2026 改造：遥控器 + FPGA 链路初始化 =================
    dbus.begin(Serial1, 38);                     // DR16 接收机信号线 -> H24 排针 GPIO38
    fpga.begin(Serial2, 41, 42, 115200, 12, 13); // FPGA UART -> H24 排针 TX=42 RX=41；I2C(12,13) 只读 IMU 原始值
    Serial.printf("[PLD2026] IMU chip = %d (0=未找到 1=MPU6050 2=LSM6DS3)\n", fpga.imuChip());
    return true;
}

// $command 控制台命令处理（官方原逻辑，与 micro-ROS 无关）
static void deal_command(char key[32], char value[32])
{
    if (strcmp(key, "command") == 0)
    {
        if (strcmp(value, "restart") == 0)
        {
            esp_restart();
        }
        else if (strcmp(value, "read_config") == 0)
        {
            Serial.print(config.config_str());
        }
        return;
    }
    else
    {
        if (strcmp(key, "pid_kp") == 0)
        {
            float kp = atof(value);
            for (size_t i = 0; i < 4; i++)
            {
                pid_controller[i].update_pid(kp, config.kinematics_pid_ki(), config.kinematics_pid_kd());
            }
        }
        else if (strcmp(key, "pid_ki") == 0)
        {
            float ki = atof(value);
            for (size_t i = 0; i < 4; i++)
            {
                pid_controller[i].update_pid(config.kinematics_pid_kp(), ki, config.kinematics_pid_kd());
            }
        }
        else if (strcmp(key, "pid_kd") == 0)
        {
            float kd = atof(value);
            for (size_t i = 0; i < 4; i++)
            {
                pid_controller[i].update_pid(config.kinematics_pid_kp(), config.kinematics_pid_ki(), kd);
            }
        }
        String recv_key(key);
        String recv_value(value);
        config.config(recv_key, recv_value);
        Serial.print("$result=ok\n");
    }
}

// PLD2026: $command 串口控制台（取自官方 loop_fishbot_transport 的串口解析部分）
void loop_fishbot_console()
{
    static char result[10][32];
    static int config_result;
    while (Serial.available())
    {
        int c = Serial.read();
        config_result = config.loop_config_uart(c, result);
        if (config_result == CONFIG_PARSE_OK)
        {
            deal_command(result[0], result[1]);
        }
        else if (config_result == CONFIG_PARSE_ERROR)
        {
            Serial.print("$result=error parse\n");
        }
    }
}

void loop_fishbot_control()
{
    static float out_motor_speed[4];
    static uint8_t index = 0;
    kinematics.update_motor_ticks(micros(), encoders[0].getTicks(), encoders[1].getTicks(), encoders[2].getTicks(), encoders[3].getTicks());
    // ================= PLD2026 改造：遥控器麦轮运动学逆解 + PID 闭环 =================
    // 协议对齐 dart_mcu：拨杆 1=UP 3=MID 2=DOWN
    //   右拨杆(s2): UP(1)=保护/停车  MID(3)=遥控模式  DOWN(2)=比赛模式
    //   左拨杆(s1): UP(1)/MID(3)=安全锁定  DOWN(2)=解臂
    dbus.update();
    static float target_motor_speed1, target_motor_speed2, target_motor_speed3, target_motor_speed4;
    bool rc_online  = dbus.isOnline();
    bool s2_arm     = (dbus.data().s2 == 2 || dbus.data().s2 == 3); // 右拨杆非 UP = 使能
    bool s1_unlock  = (dbus.data().s1 == 2);                          // 左拨杆 DOWN = 解臂
    // 始终计算运动学输入（未解臂时为 0，供 OLED 调试显示）
    float linear_x  = (rc_online && s2_arm && s1_unlock) ? dbus_map_channel(dbus.data().ch[3], 1000) : 0.0f;
    float linear_y  = (rc_online && s2_arm && s1_unlock) ? dbus_map_channel(dbus.data().ch[0], 1000) : 0.0f;
    float angular_z = (rc_online && s2_arm && s1_unlock) ? -dbus_map_channel(dbus.data().ch[2], 5.0f) : 0.0f;
    if (rc_online && s2_arm && s1_unlock)
    {
        kinematics.kinematic_inverse(linear_x, linear_y, angular_z,
                                     target_motor_speed1, target_motor_speed2,
                                     target_motor_speed3, target_motor_speed4);
    }
    else
    {
        // 接收机失联、右拨杆保护、或左拨杆未解臂 -> 停车（失控保护）
        target_motor_speed1 = 0;
        target_motor_speed2 = 0;
        target_motor_speed3 = 0;
        target_motor_speed4 = 0;
    }
    // 更新 PID 控制器目标值
    pid_controller[0].update_target(target_motor_speed1);
    pid_controller[1].update_target(target_motor_speed2);
    pid_controller[2].update_target(target_motor_speed3);
    pid_controller[3].update_target(target_motor_speed4);
    // PID 闭环控制各轮速度（与原版 loop_fishbot_control 一致）
    for (index = 0; index < 4; index++)
    {
        if (pid_controller[index].target_ == 0)
        {
            out_motor_speed[index] = 0;
        }
        else
        {
            out_motor_speed[index] = pid_controller[index].update(kinematics.motor_speed(index));
        }
        motor.updateMotorSpeed(index, out_motor_speed[index]);
    }
    // 电量信息：电机速度为零时读取电池电压
    if (out_motor_speed[0] == 0 && out_motor_speed[1] == 0)
    {
        battery_voltage = 5.02 * ((float)analogReadMilliVolts(14) * 1e-3);
        display.updateBatteryInfo(battery_voltage);
    }
    // 更新系统信息（无ROS版：用本地 millis，原为 rmw_uros_epoch_millis）
    display.updateCurrentTime(millis());
    // ================= PLD2026 调试：OLED 实时显示遥控器状态 =================
    {
        const DbusData &d = dbus.data();
        display.updateRcDebug(rc_online, s2_arm, s1_unlock,
                              d.ch[0], d.ch[1], d.ch[2], d.ch[3],
                              d.s1, d.s2,
                              linear_x, linear_y, angular_z);
    }
    // 串口输出完整摇杆/拨杆调试信息（每 2000ms 一次，减少刷屏）
    {
        static uint32_t last_rc_print = 0;
        if (millis() - last_rc_print > 2000) {
            last_rc_print = millis();
            const DbusData &d = dbus.data();
            Serial.printf("[RC] ch0=%d ch1=%d ch2=%d ch3=%d s1=%d s2=%d online=%d arm=%d unlock=%d | "
                          "lx=%.0f ly=%.0f az=%.2f t1=%.0f t2=%.0f t3=%.0f t4=%.0f\n",
                          d.ch[0], d.ch[1], d.ch[2], d.ch[3], d.s1, d.s2, rc_online, s2_arm, s1_unlock,
                          linear_x, linear_y, angular_z,
                          target_motor_speed1, target_motor_speed2, target_motor_speed3, target_motor_speed4);
        }
    }
    // 刷新显示屏幕
    display.updateDisplay();
    // 处理按钮事件
    button.tick();
    imu.update();
    // ================= PLD2026 改造：向 FPGA 发送传感器帧（100Hz） =================
    // 编码器累计计数沿用官方 encoders 对象（读取方式不变）；
    // IMU 原始值由 imu_raw 库通过同一 I2C 总线只读获取（不改动官方 imu 驱动）。
    {
        int32_t ticks[4];
        for (int i = 0; i < 4; i++) ticks[i] = (int32_t)encoders[i].getTicks();
        fpga.send(ticks); // 内部 10ms 节流，实际发送频率 100Hz
    }

    // ================= PLD2026 改造：FPGA 下行 V1.1 接收 + 看门狗 =================
    fpga.receive();
    // 看门狗触发：200ms 无合法下行帧 → 立即停车（安全保护）
    if (fpga.cmdWatchdog()) {
        target_motor_speed1 = 0;
        target_motor_speed2 = 0;
        target_motor_speed3 = 0;
        target_motor_speed4 = 0;
        for (int i = 0; i < 4; i++) {
            pid_controller[i].update_target(0);
            motor.updateMotorSpeed(i, 0);
        }
        Serial.println("[FPGA] WATCHDOG: 200ms 无下行帧，已停车！");
    }

    // ================= PLD2026: OLED 通信调试数据更新 =================
    {
        static uint32_t last_tx_cnt = 0;
        static uint32_t last_tx_ms  = 0;
        uint32_t now = millis();
        uint32_t tx_interval = 0;
        if (fpga.txCount() != last_tx_cnt) {
            if (last_tx_ms != 0) tx_interval = now - last_tx_ms;
            last_tx_ms  = now;
            last_tx_cnt = fpga.txCount();
        }
        int32_t enc[4];  for (int i=0;i<4;i++) enc[i] = fpga.txEnc(i);
        int16_t gyro[3]; for (int i=0;i<3;i++) gyro[i] = fpga.txGyro(i);
        int16_t acc[3];  for (int i=0;i<3;i++) acc[i]  = fpga.txAcc(i);
        display.updateCommDebug(
            fpga.txCount(), fpga.rxOkCount(), fpga.rxCrcErr(),
            fpga.cmdOnline(), tx_interval,
            enc, gyro, acc,
            fpga.cmdRaw(), fpga.txRaw()
        );
    }
}
