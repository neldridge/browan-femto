#! /bin/sh

EEPM_CMD="/app/lora_pkg/pkt_only_femto/util_lgw_eeprom_femto"
TEMP_EEPM="/tmp/lora_eeprom_cfg"

PWRTBL_FILE_0="/app/lora_pkg/pkt_only_femto/pwr_tables.ini"
CFG_PATH_0="/app/cfg/"
GJSON_NAME="global_conf.json"


read_pwrtb(){
		for i in `seq 0 15`
		do
				if [ "$i" = "1" ]; then
						PA_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						MIX_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						RF_POWER=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
						DIG_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				else
						PA_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						MIX_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						RF_POWER=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
						DIG_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				fi

				[ "$i" -lt "10" ]&& idx="0"$i || idx=$i
				#PA / MIX / RF/ DIG
				echo "[$idx]" $PA_GAIN $MIX_GAIN $RF_POWER $DIG_GAIN
				echo "----------------"

		done
}
write2global(){
		let a=89
		let b=90
		let c=91
		let d=92

		for i in `seq 0 15`
		do
				if [ "$i" = "1" ]; then
						PA_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						MIX_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						RF_POWER=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
						DIG_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				else
						PA_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						MIX_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
						RF_POWER=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
						DIG_GAIN=`cat $PWRTBL_FILE_0 | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				fi

				sed -i  "${a} s/.*/            \"pa_gain\": ${PA_GAIN},/g" $CFG_PATH_0$GJSON_NAME
				sed -i  "${b} s/.*/            \"mix_gain\": ${MIX_GAIN},/g" $CFG_PATH_0$GJSON_NAME
				sed -i  "${c} s/.*/            \"rf_power\": ${RF_POWER},/g" $CFG_PATH_0$GJSON_NAME
				sed -i  "${d} s/.*/            \"dig_gain\": ${DIG_GAIN}/g" $CFG_PATH_0$GJSON_NAME

				let a=$a+6
				let b=$b+6
				let c=$c+6
				let d=$d+6

		done
}
cmp_global_eeprom(){

		let i=33
		let sum=0
		while [ "$i" -le "153" ]
		do
				a=$i
				let b=$i+1
				let c=$i+2
				let d=$i+3
				let e=$i+4
				let f=$i+5
				let g=$i+6
				let h=$i+7

				DIG_GAIN_E=`echo "$(cat $TEMP_EEPM|cut -c $a-$b)"| awk '{printf("%d","0x"$0"")}'`
				PA_GAIN_E=`echo "$(cat $TEMP_EEPM|cut -c $c-$d)"| awk '{printf("%d","0x"$0"")}'`
				MIX_GAIN_E=`echo "$(cat $TEMP_EEPM|cut -c $e-$f)"| awk '{printf("%d","0x"$0"")}'`
				RF_POWER_E=`echo "$(cat $TEMP_EEPM|cut -c $g-$h)"| awk '{printf("%d","0x"$0"")}'`

				PA_GAIN_G=`jq ".SX1301_conf.tx_lut_$sum.pa_gain"  $CFG_PATH_0$GJSON_NAME`
				MIX_GAIN_G=`jq ".SX1301_conf.tx_lut_$sum.mix_gain" $CFG_PATH_0$GJSON_NAME`
				RF_POWER_G=`jq ".SX1301_conf.tx_lut_$sum.rf_power" $CFG_PATH_0$GJSON_NAME`
				DIG_GAIN_G=`jq ".SX1301_conf.tx_lut_$sum.dig_gain" $CFG_PATH_0$GJSON_NAME`

				[ "$sum" -lt "10" ]&& idx="0"$sum || idx=$sum
				echo "[$idx] E:" $PA_GAIN_E $MIX_GAIN_E $RF_POWER_E $DIG_GAIN_E
				echo "     G:" $PA_GAIN_G $MIX_GAIN_G $RF_POWER_G $DIG_GAIN_G
				echo "--------------------------"

				let i=i+8
				let sum++

		done
}
read_eeprom(){

	let i=33
	let sum=0
	echo "   "   "PA" "MIX" "RF" "DIG"
	while [ "$i" -le "153" ]
	do
		let a=$i
		let b=$i+1
		let c=$i+2
		let d=$i+3
		let e=$i+4
		let f=$i+5
		let g=$i+6
		let h=$i+7

		temp_1=`echo "$(cat $TEMP_EEPM|cut -c $a-$b)"| awk '{printf("%d","0x"$0"")}'`
		temp_2=`echo "$(cat $TEMP_EEPM|cut -c $c-$d)"| awk '{printf("%d","0x"$0"")}'`
		temp_3=`echo "$(cat $TEMP_EEPM|cut -c $e-$f)"| awk '{printf("%d","0x"$0"")}'`
		temp_4=`echo "$(cat $TEMP_EEPM|cut -c $g-$h)"| awk '{printf("%d","0x"$0"")}'`
		[ "$sum" -lt "10" ]&& idx="0"$sum || idx=$sum
		# PA / MIX / RF/ DIG
		echo "[$idx]"  "$temp_2" "$temp_3" "$temp_4" "$temp_1"

		echo "----------------"

		let i=i+8
		let sum++
	done



}


do_main(){


		if [ "$1" = "pwrtb" ]; then
			echo "====POWER TABLE===="
			read_pwrtb
			echo "====POWER TABLE===="

		elif [ "$1" = "compare" ]; then
			rmmod gmspi_module
			insmod gmspi_module SPI_SPEED=6
			$EEPM_CMD -d 0 -r 128 > /dev/null 2>&1
			echo "===EEPROM and GlobalJSON==="
			cmp_global_eeprom
			echo "===EEPROM and GlobalJSON==="
			rmmod gmspi_module
			insmod gmspi_module SPI_SPEED=4

		elif [ "$1" = "eeprom" ]; then
			rmmod gmspi_module
			insmod gmspi_module SPI_SPEED=6
			$EEPM_CMD -d 0 -r 128 > /dev/null 2>&1
			echo "=====EEPROM====="
			read_eeprom
			echo "=====EEPROM====="
			rmmod gmspi_module
			insmod gmspi_module SPI_SPEED=4

		elif [ "$1" = "write" ]; then
			write2global
		else
			echo "==============================================="
			echo "This script is used for showing the power value"
			echo "from global_conf.json / pwr_tables.ini / eeprom"
			echo "====================Usage:====================="
			echo "EX. $0" [option]
			echo
			echo "OPTION:"
			echo "pwrtb"  "    -show pwr_tables.ini"
			echo "compare""   -compare eeprom with global_conf.json"
			echo "eeprom" "   -show the power value from eeprom"
			echo "write"  "    -read from pwrtb write to global json"
		fi


}
do_main $1
