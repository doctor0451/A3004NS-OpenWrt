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






###############以下是我的代码###############

#!/bin/bash

# 注意：执行此脚本时，当前目录已经在 openwrt 源码根目录
# 不要再 cd openwrt 或进入其他不存在的目录！

echo "正在修改设备树文件以适配 32MB 闪存..."

# 目标文件路径（相对于 openwrt 根目录）
DTS_FILE="target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts"

# 检查文件是否存在
if [ ! -f "$DTS_FILE" ]; then
    echo "错误：找不到 $DTS_FILE"
    echo "当前目录：$(pwd)"
    ls -la target/linux/ramips/dts/ | head -20
    exit 1
fi

# 备份原文件
cp "$DTS_FILE" "$DTS_FILE.bak"

# 修改 firmware 分区大小：从 0xfc0000 (16MB) 改为 0x1fb0000 (~31.5MB)
sed -i 's/reg = <0x40000 0xfc0000>;/reg = <0x40000 0x1fb0000>;/' "$DTS_FILE"

# 验证修改是否成功
if grep -q "reg = <0x40000 0x1fb0000>" "$DTS_FILE"; then
    echo "✅ 成功修改 firmware 分区大小为 32MB 布局"
else
    echo "❌ 修改失败，请检查原文件格式"
    exit 1
fi

echo "diy-part2.sh 执行完成"
