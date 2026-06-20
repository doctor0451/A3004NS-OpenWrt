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

# 替换 原装DTS + 32M闪存
cd target/linux/ramips/dts
cat > mt7621_iptime_a3004ns-dual.dts <<-'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
#include "mt7621.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	compatible = "iptime,a3004ns-dual", "mediatek,mt7621-soc";
	model = "ipTIME A3004NS-dual";

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
		broken-flash-reset;
		
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x20000>;
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

			partition@20000 {
				label = "config";
				reg = <0x20000 0x10000>;
				read-only;
			};

			partition@30000 {
				label = "factory";
				reg = <0x30000 0x10000>;
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

			partition@40000 {
				label = "firmware";
				reg = <0x40000 0x1fc0000>;
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
// 新增MT7621温度传感器节点
&thermal {
	compatible = "mediatek,mt7621-thermal";
	status = "okay";
};
EOF

cd -

# ==============================================
# 2. 32M 固件大小配置
# ==============================================
MK_FILE="target/linux/ramips/image/mt7621.mk"
sed -i '/define Device\/iptime_a3004ns-dual/,/endef/ {
    s/IMAGE_SIZE := .*/IMAGE_SIZE := 32512k/
}' "$MK_FILE"
