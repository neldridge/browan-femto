#!/bin/sh

#. /app/lora_pkg/lora_common.sh

# Check /etc/config/boot_firmware
retouch_file=0

if [ -e /etc/config/boot_firmware ] ; then

	size_of_boot_firmware=`ls -al /etc/config/boot_firmware | awk -F " " '{printf$5}'`

	if [ "$size_of_boot_firmware" = "0" ] ; then
		retouch_file=1
	fi
fi

[[ ! -e /etc/config/boot_firmware || "$retouch_file" = "1" ]] && {
		touch /etc/config/boot_firmware
		uci set boot_firmware.fw_info='section'

		local cur_run_fw=`fw_printenv running_fw | cut -d'=' -f2`

		if [ "$cur_run_fw" = "firmware2" ]; then
			uci set boot_firmware.fw_info.primary="fw2"
		else
			uci set boot_firmware.fw_info.primary="fw1"
		fi

		uci set boot_firmware.fw_info.fw1_ver="-"
		uci set boot_firmware.fw_info.fw2_ver="-"

        }

# Setup fw_info section
uci set boot_firmware.fw_info='section'
if [ "$(uci get boot_firmware.fw_info.primary)" = "fw2" ]; then
	uci set boot_firmware.fw_info.fw2_ver=`cat /etc/version | cut -d" " -f 2`
else
	uci set boot_firmware.fw_info.fw1_ver=`cat /etc/version | cut -d" " -f 2`
fi
uci commit boot_firmware
uci -c /etc/config/ commit boot_firmware
