#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate






#以下是我的代码
# 为 A3004NS 适配 32M 闪存（如果硬改了32M）
sed -i '/define Device\/iptime_a3004ns-dual/,/endef/ s/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 32128k/' target/linux/ramips/mt7621/mt7621.mk

# 添加 A3004NS 设备树的 broken-flash-reset（可选，防止软重启异常）
sed -i '/spi-max-frequency/a\\t\tbroken-flash-reset;' target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts
