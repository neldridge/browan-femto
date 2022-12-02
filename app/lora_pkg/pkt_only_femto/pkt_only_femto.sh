#!/bin/sh

CFG_PATH='/app/lora_pkg/pkt_only_femto/'
GJSON_NAME='global_conf.json'
PWR_TABLE='pwr_tables.ini'
BK_PWR_TABLE='BK_pwr_tables.ini'
FLAG_SLASH=''
LORA_INI='lora_WLRGFM-100.ini'

if [ "$1" == "-h" ]; then

	echo "Usage:"
	echo ""
	echo "###Example###"
	echo "sh pkt_only_femto.sh"
	echo ""
	exit 1

else

	conf_manager &
	chmod 777 $CFG_PATH/synclora2ini_femto.sh
	chmod 777 $CFG_PATH/util_lgw_eeprom_femto
	#cp -f $PWR_TABLE $CFG_PATH$PWR_TABLE
	[ ! -s  "$CFG_PATH/$PWR_TABLE"  ] && cp -f $CFG_PATH/$BK_PWR_TABLE $CFG_PATH/$PWR_TABLE

	rmmod gmspi_module
	insmod gmspi_module SPI_SPEED=6
	echo "[pkt_only_odu.sh] Sync power table form card 0..."

	mac1=`uci -c /mnt/data/config/ get mfg.system.lora_ee_cnt_0|cut -c 5-10`
	$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-pwrt $mac1  $CFG_PATH$PWR_TABLE
	if [ "$?" = "1" ]; then
		$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-pwrt $mac1  $CFG_PATH$PWR_TABLE
	fi
	
	mac2=`echo "$mac1" | tr 'a-z' 'A-Z'`
	$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-lbtofs $mac2 $CFG_PATH$GJSON_NAME
	if [ "$?" = "1" ]; then
		$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-lbtofs $mac2 $CFG_PATH$GJSON_NAME
	fi
	
	mac3="0000""$mac1"
	$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-rxofs $mac3 $CFG_PATH$GJSON_NAME
	if [ "$?" = "1" ]; then
		$CFG_PATH/synclora2ini_femto.sh 0 --w2ini-rxofs $mac3 $CFG_PATH$GJSON_NAME
	fi

fi
/app/lora_pkg/pkt_only_femto/util_lgw_eeprom_femto -d 0 -r 8
rmmod gmspi_module
insmod gmspi_module SPI_SPEED=4
#Detect /* start

slash=`cat $CFG_PATH$GJSON_NAME | grep "/\*" | awk '{print$1}' | grep "/\*" | sed -n '1p'`

if [ "$slash" = "" ]; then
	FLAG_SLASH=0
else
	FLAG_SLASH=1
fi

#Detect End

echo "[pkt_only_odu.sh] Sync power table into global json file..."

sx127x_1nd=`grep -n "rssi_offset" $CFG_PATH$GJSON_NAME | sed -n '1p' | awk '{print$1}' | sed 's/:.*$//g'`
radio_0=`grep -n "rssi_offset" $CFG_PATH$GJSON_NAME | sed -n '2p' | awk '{print$1}' | sed 's/:.*$//g'`
radio_1=`grep -n "rssi_offset" $CFG_PATH$GJSON_NAME | sed -n '3p' | awk '{print$1}' | sed 's/:.*$//g'`
tx_lut_1nd=`grep -n "tx_lut_0" $CFG_PATH$GJSON_NAME | awk '{print$1}' | sed 's/:.*$//g'`
tx_lut_last=`grep -n "},"  $CFG_PATH$GJSON_NAME | tail -n 1 | awk '{print$1}' | sed 's/:.*$//g'`
file_last=`grep -n "}"  $CFG_PATH$GJSON_NAME | tail -n 1 | awk '{print$1}' | sed 's/:.*$//g'`

head -n $(($sx127x_1nd-1)) $CFG_PATH$GJSON_NAME > /tmp/global_conf_1
head -n $(($radio_0-1)) $CFG_PATH$GJSON_NAME | tail -n +$(($sx127x_1nd+1)) > /tmp/global_conf_2
head -n $(($radio_1-1)) $CFG_PATH$GJSON_NAME | tail -n +$(($radio_0+1)) > /tmp/global_conf_3
head -n $(($tx_lut_1nd-1)) $CFG_PATH$GJSON_NAME | tail -n +$(($radio_1+1)) > /tmp/global_conf_4
head -n $file_last $CFG_PATH$GJSON_NAME | tail -n +$tx_lut_last > /tmp/global_conf_5

if [ "$FLAG_SLASH" = "0" ]; then

	for i in `seq 0 15`
	do

			if [ "$i" = "1" ]; then
				PA_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				MIX_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				RF_POWER=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
				DIG_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
			else
				PA_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep pa_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				MIX_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep mix_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
				RF_POWER=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep rf_power | sed 's/^.* "//g' | sed  's/";.*$//g'`
				DIG_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep dig_gain | sed 's/^.* "//g' | sed  's/";.*$//g'`
			fi

			echo "        \"tx_lut_$i\": {" >> /tmp/global_conf_tx_lut
			echo "            \"pa_gain\": $PA_GAIN," >> /tmp/global_conf_tx_lut
			echo "            \"mix_gain\": $MIX_GAIN," >> /tmp/global_conf_tx_lut
			echo "            \"rf_power\": $RF_POWER," >> /tmp/global_conf_tx_lut
			echo "            \"dig_gain\": $DIG_GAIN" >> /tmp/global_conf_tx_lut
			echo "        }," >> /tmp/global_conf_tx_lut

	done

	sx_offset=`cat /tmp/sx127x_offset`
	ra0_offset=`cat /tmp/radio0_offset`
	ra1_offset=`cat /tmp/radio1_offset`
	echo "            \"sx127x_rssi_offset\": $sx_offset" > /tmp/sx_offset
	echo "            \"rssi_offset\": $ra0_offset," > /tmp/ra0_offset
	echo "            \"rssi_offset\": $ra1_offset," > /tmp/ra1_offset

elif [ "$FLAG_SLASH" = "1" ]; then

	for i in `seq 0 15`
	do

			if [ "$i" = "1" ]; then
				PA_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep pa_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
				MIX_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep mix_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
				RF_POWER=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep rf_power | sed 's/^.* "//g' | sed 's/";.*$//g'`
				DIG_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | sed -n '1,7p' | grep dig_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
			else
				PA_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep pa_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
				MIX_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep mix_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
				RF_POWER=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep rf_power | sed 's/^.* "//g' | sed 's/";.*$//g'`
				DIG_GAIN=`cat $CFG_PATH$PWR_TABLE | grep -A114 SX1301_GW_MAC_1 | grep -A6 tx_lut_$i | grep dig_gain | sed 's/^.* "//g' | sed 's/";.*$//g'`
			fi

			echo "        \"tx_lut_$i\": {" >> /tmp/global_conf_tx_lut
			echo "            /* TX gain table, index $i */" >> /tmp/global_conf_tx_lut
			echo "            \"pa_gain\": $PA_GAIN," >> /tmp/global_conf_tx_lut
			echo "            \"mix_gain\": $MIX_GAIN," >> /tmp/global_conf_tx_lut
			echo "            \"rf_power\": $RF_POWER," >> /tmp/global_conf_tx_lut
			echo "            \"dig_gain\": $DIG_GAIN" >> /tmp/global_conf_tx_lut
			echo "        }," >> /tmp/global_conf_tx_lut

	done

	sx_offset=`cat /tmp/sx127x_offset`
	ra0_offset=`cat /tmp/radio0_offset`
	ra1_offset=`cat /tmp/radio1_offset`
	echo "            \"sx127x_rssi_offset\": $sx_offset /* dB */" > /tmp/sx_offset
	echo "            \"rssi_offset\": $ra0_offset," > /tmp/ra0_offset
	echo "            \"rssi_offset\": $ra1_offset," > /tmp/ra1_offset

fi

mid_num=`cat /tmp/global_conf_tx_lut | grep -n "}," | tail -n 1 | awk '{print$1}' | sed 's/:.*$//g'`

cat /tmp/global_conf_tx_lut | head -n $(($mid_num-1)) >> /tmp/global_conf_tx_lut_0
echo "        }" >> /tmp/global_conf_tx_lut_0
rm /tmp/global_conf_tx_lut
mv /tmp/global_conf_tx_lut_0 /tmp/global_conf_tx_lut

#create complete global_conf_0.json
cat /tmp/global_conf_1 >> /tmp/$GJSON_NAME
cat /tmp/sx_offset >> /tmp/$GJSON_NAME
cat /tmp/global_conf_2 >> /tmp/$GJSON_NAME
cat /tmp/ra0_offset >> /tmp/$GJSON_NAME
cat /tmp/global_conf_3 >> /tmp/$GJSON_NAME
cat /tmp/ra1_offset >> /tmp/$GJSON_NAME
cat /tmp/global_conf_4 >> /tmp/$GJSON_NAME
cat /tmp/global_conf_tx_lut >> /tmp/$GJSON_NAME
cat /tmp/global_conf_5 >> /tmp/$GJSON_NAME

cp /tmp/$GJSON_NAME  $CFG_PATH$GJSON_NAME


GWID=`uci -c /mnt/data/config/ get mfg.system.lora_ee_cnt_0|cut -c 1-16`
[ -z "$GWID" ]&&{
	GWID=`cat /tmp/lora_eeprom_cfg|tr -dc "0-9a-zA-z"`
}
string=`grep  "gateway_ID" $CFG_PATH$GJSON_NAME |awk -F ":"  '{print $2}'|tr -d -c '0-9A-Za-z'`
sed -i 's/'"$string"'/'"$GWID"'/g' $CFG_PATH$GJSON_NAME

#/usr/bin/jq ".gateway_conf.gateway_ID=\"$GWID\"" $CFG_PATH$GJSON_NAME | /usr/bin/sponge $CFG_PATH$GJSON_NAME


rm /tmp/global_conf_*
rm /tmp/sx127x_offset
rm /tmp/radio0_offset
rm /tmp/radio1_offset
rm /tmp/sx_offset
rm /tmp/ra0_offset
rm /tmp/ra1_offset
rm /tmp/global_conf_tx_lut
rm /tmp/$GJSON_NAME

killall conf_manager

echo "[pkt_only_odu.sh] Done!"
exit 0
