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
#!/bin/bash
# diy-part2.sh - 在 make 执行前运行

# 切换到目标设备树文件所在目录
TARGET_DTS_DIR="target/linux/ramips/dts"
cd openwrt || exit 1

# 备份原始 dts 文件（可选）
cp ${TARGET_DTS_DIR}/mt7621_iptime_a3004ns-dual.dts ${TARGET_DTS_DIR}/mt7621_iptime_a3004ns-dual.dts.bak

# 使用 sed 修改 firmware 分区的 reg 值（从 0x40000 0xfc0000 改为 0x40000 0x1fb0000）
sed -i 's/reg = <0x40000 0xfc0000>;/reg = <0x40000 0x1fb0000>;/' ${TARGET_DTS_DIR}/mt7621_iptime_a3004ns-dual.dts

echo "已修改 mt7621_iptime_a3004ns-dual.dts 的 firmware 分区大小为 32MB 布局"
