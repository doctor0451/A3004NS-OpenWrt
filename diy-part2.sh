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
# 在编译前添加自定义补丁

# 修复32M闪存软重启问题
echo "Applying 32M flash soft reboot fix..."

# 创建补丁目录
mkdir -p target/linux/ramips/patches-5.15

# 创建软重启修复补丁
cat > target/linux/ramips/patches-5.15/999-fix-32m-soft-reboot.patch << 'EOF'
--- a/arch/mips/ralink/mt7621.c
+++ b/arch/mips/ralink/mt7621.c
@@ -123,6 +123,11 @@
 
 void __init ralink_clk_init(void)
 {
+       /* Fix for 32M flash soft reboot issue */
+       if (IS_ENABLED(CONFIG_MT7621_32M_FLASH_FIX)) {
+               pr_info("MT7621: Applying 32M flash soft reboot workaround\n");
+               iowrite32(0x34, ioremap_nocache(0xbe006000, 0x100) + 0x034);
+       }
+
 #ifdef CONFIG_MT7621_FIX_32M_FLASH
        /* Do something if needed */
 #endif
EOF

# 修改内核配置，添加32M闪存支持
echo "CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=y" >> target/linux/ramips/mt7621/config-5.15
echo "CONFIG_MT7621_32M_FLASH_FIX=y" >> target/linux/ramips/mt7621/config-5.15

# 修改DTS文件以支持32M闪存分区
echo "Modifying DTS for 32M flash..."

# 备份原始DTS
if [ -f target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts ]; then
        cp target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts.bak
fi

# 修改分区表
cat > target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts << 'DTS_EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	compatible = "iptime,a3004ns-dual", "mediatek,mt7621-soc";
	model = "ipTIME A3004NS-dual (32M MOD)";

	aliases {
		led-boot = &led_cpu;
		led-failsafe = &led_cpu;
		led-running = &led_cpu;
		led-upgrade = &led_cpu;
	};

	leds {
		compatible = "gpio-leds";

		led_cpu: cpu {
			function = LED_FUNCTION_CPU;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
		};

		usb {
			function = LED_FUNCTION_USB;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio 7 GPIO_ACTIVE_LOW>;
			trigger-sources = <&xhci_ehci_port1>;
			linux,default-trigger = "usbport";
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 4 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};

		wps {
			label = "wps";
			gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_WPS_BUTTON>;
		};
	 };
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;
		m25p,fast-read;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x50000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					macaddr_uboot_1fc20: macaddr@1fc20 {
						reg = <0x1fc20 0x6>;
					};

					macaddr_uboot_1fc40: macaddr@1fc40 {
						reg = <0x1fc40 0x6>;
					};
				};
			};

			partition@50000 {
				label = "config";
				reg = <0x50000 0x30000>;
				read-only;
			};

			partition@80000 {
				label = "factory";
				reg = <0x80000 0x40000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					eeprom_factory_0: eeprom@0 {
						reg = <0x0 0x200>;
					};

					eeprom_factory_8000: eeprom@8000 {
						reg = <0x8000 0x200>;
					};
				};
			};

			partition@c0000 {
				label = "firmware";
				reg = <0xc0000 0x1f40000>;
				compatible = "denx,uimage";
			};
		};
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_uboot_1fc20>;
	nvmem-cell-names = "mac-address";
};

&gmac1 {
	status = "okay";
	label = "wan";
	phy-handle = <&ethphy0>;

	nvmem-cells = <&macaddr_uboot_1fc40>;
	nvmem-cell-names = "mac-address";
};

&ethphy0 {
	/delete-property/ interrupts;
};

&switch0 {
	ports {
		port@1 {
			status = "okay";
			label = "lan1";
		};

		port@2 {
			status = "okay";
			label = "lan2";
		};

		port@3 {
			status = "okay";
			label = "lan3";
		};

		port@4 {
			status = "okay";
			label = "lan4";
		};
	};
};

&pcie {
	status = "okay";
};

&pcie0 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		nvmem-cells = <&eeprom_factory_8000>;
		nvmem-cell-names = "eeprom";
		ieee80211-freq-limit = <5000000 6000000>;

		led {
			led-sources = <2>;
			led-active-low;
		};
	};
};

&pcie1 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		nvmem-cells = <&eeprom_factory_0>;
		nvmem-cell-names = "eeprom";
		ieee80211-freq-limit = <2400000 2500000>;

		led {
			led-sources = <2>;
			led-active-low;
		};
	};
};

&state_default {
	gpio {
		groups = "wdt", "i2c", "uart3";
		function = "gpio";
	};
};
DTS_EOF

echo "32M flash DTS patch applied"

# 添加额外的内核参数以修复软重启
echo "net.core.bpf_jit_enable=1" >> package/base-files/files/etc/sysctl.conf

# 重启问题修复脚本
cat > package/base-files/files/etc/init.d/reboot_fix << 'INIT_EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=99

reboot_fix() {
    # 强制清理缓存，防止重启卡死
    echo 1 > /proc/sys/vm/drop_caches
    echo 3 > /proc/sys/vm/drop_caches
}

boot() {
    reboot_fix
    return 0
}
INIT_EOF

chmod +x package/base-files/files/etc/init.d/reboot_fix
