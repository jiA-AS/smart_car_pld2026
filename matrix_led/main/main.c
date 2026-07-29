/*
 * ESP32-S3-Matrix 手机控制 8x8 RGB 点阵
 * WiFi 热点 + 网页控制：手机连 ESP32S3-Matrix，浏览器打开 192.168.4.1
 */
#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "esp_http_server.h"
#include "nvs_flash.h"
#include "led_strip.h"

#define MATRIX_GPIO   14    // ESP32-S3-Matrix 矩阵数据脚
#define NUM_LEDS      64    // 8x8
#define LED_VAL       30    // 亮度值(0-255)，官方警告：别调大，过亮会烧板子

static const char *TAG = "matrix";
static led_strip_handle_t strip;
static volatile int mode = 0;   // 0关 1红 2绿 3蓝 4白 5彩虹

/* ---------- 点阵填充 ---------- */
static void matrix_fill(uint8_t r, uint8_t g, uint8_t b)
{
    for (int i = 0; i < NUM_LEDS; i++)
        led_strip_set_pixel(strip, i, r, g, b);
    led_strip_refresh(strip);
}

static void apply_mode(int m)
{
    switch (m) {
        case 1:  matrix_fill(LED_VAL, 0, 0); break;
        case 2:  matrix_fill(0, LED_VAL, 0); break;
        case 3:  matrix_fill(0, 0, LED_VAL); break;
        case 4:  matrix_fill(20, 20, 20);    break;
        default: matrix_fill(0, 0, 0);       break;
    }
}

/* 彩虹流动任务：mode==5 时持续刷新 */
static void rainbow_task(void *arg)
{
    uint16_t hue = 0;
    while (1) {
        if (mode == 5) {
            for (int i = 0; i < NUM_LEDS; i++)
                led_strip_set_pixel_hsv(strip, i, (hue + i * 6) % 360, 255, LED_VAL);
            led_strip_refresh(strip);
            hue += 2;
            vTaskDelay(pdMS_TO_TICKS(30));
        } else {
            vTaskDelay(pdMS_TO_TICKS(100));
        }
    }
}

/* ---------- 网页 ---------- */
static const char index_html[] =
"<!DOCTYPE html><html><head>"
"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
"<meta charset=\"utf-8\"><title>Matrix</title>"
"<style>body{font-family:sans-serif;text-align:center;background:#222;color:#fff;padding-top:30px}"
"button{width:110px;height:56px;font-size:20px;margin:8px;border:none;border-radius:12px;color:#fff}</style>"
"</head><body><h2>ESP32-S3 Matrix</h2>"
"<button style=\"background:#d32f2f\" onclick=\"fetch('/m?m=1')\">红</button>"
"<button style=\"background:#388e3c\" onclick=\"fetch('/m?m=2')\">绿</button>"
"<button style=\"background:#1976d2\" onclick=\"fetch('/m?m=3')\">蓝</button><br>"
"<button style=\"background:#888\"    onclick=\"fetch('/m?m=4')\">白</button>"
"<button style=\"background:#7b1fa2\" onclick=\"fetch('/m?m=5')\">彩虹</button>"
"<button style=\"background:#444\"    onclick=\"fetch('/m?m=0')\">关闭</button>"
"</body></html>";

static esp_err_t root_handler(httpd_req_t *req)
{
    httpd_resp_set_type(req, "text/html");
    httpd_resp_sendstr(req, index_html);
    return ESP_OK;
}

static esp_err_t mode_handler(httpd_req_t *req)
{
    char buf[32], val[8];
    if (httpd_req_get_url_query_str(req, buf, sizeof(buf)) == ESP_OK &&
        httpd_query_key_value(buf, "m", val, sizeof(val)) == ESP_OK) {
        mode = atoi(val);
        if (mode != 5) apply_mode(mode);
    }
    httpd_resp_sendstr(req, "OK");
    return ESP_OK;
}

static void start_webserver(void)
{
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    httpd_handle_t server = NULL;
    ESP_ERROR_CHECK(httpd_start(&server, &config));
    httpd_uri_t root = { .uri = "/", .method = HTTP_GET, .handler = root_handler };
    httpd_uri_t m    = { .uri = "/m", .method = HTTP_GET, .handler = mode_handler };
    httpd_register_uri_handler(server, &root);
    httpd_register_uri_handler(server, &m);
}

/* ---------- WiFi 热点 ---------- */
static void wifi_init_softap(void)
{
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_ap();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    wifi_config_t ap_cfg = {
        .ap = {
            .ssid = "ESP32S3-Matrix",
            .ssid_len = strlen("ESP32S3-Matrix"),
            .password = "12345678",
            .channel = 1,
            .max_connection = 4,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK,
        },
    };
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &ap_cfg));
    ESP_ERROR_CHECK(esp_wifi_start());
    ESP_LOGI(TAG, "热点已开启：ESP32S3-Matrix / 12345678，手机访问 192.168.4.1");
}

void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());

    /* WS2812 初始化（RMT 后端） */
    led_strip_config_t strip_config = {
        .strip_gpio_num = MATRIX_GPIO,
        .max_leds = NUM_LEDS,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model = LED_MODEL_WS2812,
        .flags.invert_out = false,
    };
    led_strip_rmt_config_t rmt_config = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 10 * 1000 * 1000,
        .flags.with_dma = false,
    };
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&strip_config, &rmt_config, &strip));
    led_strip_clear(strip);

    wifi_init_softap();
    start_webserver();
    xTaskCreate(rainbow_task, "rainbow", 2048, NULL, 5, NULL);
}
