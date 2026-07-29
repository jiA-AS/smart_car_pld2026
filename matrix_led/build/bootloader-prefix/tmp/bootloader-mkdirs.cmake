# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "D:/DevEnv/Espressif/frameworks/esp-idf-v5.1.2/components/bootloader/subproject"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/tmp"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/src/bootloader-stamp"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/src"
  "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/src/bootloader-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/src/bootloader-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "E:/FPGA/project/smart_car_pld2026/matrix_led/build/bootloader-prefix/src/bootloader-stamp${cfgdir}") # cfgdir has leading slash
endif()
