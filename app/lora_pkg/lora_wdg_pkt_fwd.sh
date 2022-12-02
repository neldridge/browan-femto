#!/bin/sh

WDG_PROC_LOG="/tmp/lorawdg_proc_log"
SVR_CHECK_PATH="/tmp/lorawdg_svr_chk"
GW_CHECK_PATH="/tmp/lorawdg_gw_chk"
SVR_KILLED_INFO_PATH="/tmp/lorawdg_svr_killed_info"
GW_KILLED_INFO_PATH="/tmp/lorawdg_gw_killed_info"
DMS_KILLED_INFO_PATH="/tmp/lorawdg_dms_killed_info"
ALERT_KILLED_INFO_PATH="/tmp/lorawdg_alert_killed_info"
MQTT_KILLED_INFO_PATH="/tmp/lorawdg_mqtt_killed_info"
CONF_KILLED_INFO_PATH="/tmp/lorawdg_conf_manager_killed_info"
P2P_KILLED_INFO_PATH="/tmp/lorawdg_p2p_killed_info"
LORA_INFO_PATH="/tmp/lorawdg_ini_info"

CWMPC_RETRY_INFO_PATH="/mnt/lora_cwmpc_retry.txt"
SVR_RETRY_INFO_PATH="/mnt/lora_svr_retry.txt"
GW_RETRY_INFO_PATH="/mnt/lora_gw_retry.txt"
BK_RETRY_INFO_PATH="/mnt/backup_retry.txt"
P2P_RETRY_INFO_PATH="/mnt/lora_p2p_retry.txt"

LORA_WDG_DBG_FILE="/tmp/lorawdg_dbg_file"
LORA_WDG_DBG_ENABLE="1"
LORA_WDG_RECUE_MODE="/tmp/lorawdg_in_rescue_mode"
LORA_FAIL_PROCESS_CNT=0
LORA_FAIL_PROCESS_CNT_MAX=4
RUN_LATEST_GNMS_RESCUE=1

reinit_max=5
gw_cnt=1
lora_retry=3
lora_retry_sleep=3
chk_period=5
loragw_flag=1
cfg_flag=0
cur_boot_link=""
boot_lora=""

LORA_GW_RETRY_ENABLE=1
LORA_GW_RETRY_TAG=0
LORA_GW_RETRY_MAX=5
LORA_GW_RETRY_NOW=0

LORA_CFG_DIR="/app/cfg"
LORA_EXE_PATH="/app/lora_pkg/"
LORA_GW_EXE="lora_pkt_fwd"
CFG_NAME="global_conf.json"

save_log_to_flash(){

	date_info=`date`
	rm -rf $BK_RETRY_INFO_PATH

	case $1 in

	"lora_gw")
		if [ -e $GW_RETRY_INFO_PATH ]; then
			line_num=`wc -l $GW_RETRY_INFO_PATH | awk -F ' ' '{print $1}'`
			if [ "$line_num" -lt "1000" ]; then
				echo "[$date_info] LORA_GW_RETRY_NOW=$LORA_GW_RETRY_NOW ; LORA_GW_RETRY_TAG=$LORA_GW_RETRY_TAG" >> $GW_RETRY_INFO_PATH
			elif [ "$line_num" -eq "1000" ]; then
				cat $GW_RETRY_INFO_PATH | sed -n '2,1000p' > $BK_RETRY_INFO_PATH
				cat $BK_RETRY_INFO_PATH > $GW_RETRY_INFO_PATH
				rm -rf $BK_RETRY_INFO_PATH
				echo "[$date_info] LORA_GW_RETRY_NOW=$LORA_GW_RETRY_NOW ; LORA_GW_RETRY_TAG=$LORA_GW_RETRY_TAG" >> $GW_RETRY_INFO_PATH
			fi
		else
			echo "[$date_info] LORA_GW_RETRY_NOW=$LORA_GW_RETRY_NOW ; LORA_GW_RETRY_TAG=$LORA_GW_RETRY_TAG" > $GW_RETRY_INFO_PATH
		fi
	;;
	esac
}

stop_lora_gw(){
	if [[ "$(pidof $LORA_GW_EXE)" != "" ]];then
		kill -9 $(pidof $LORA_GW_EXE)
	fi
	gtk_led_ctl.sh lora off

}

stop_process(){
	if ps | grep -v "grep" | grep -q "$1" ; then
		if [ "$(pidof $1)" != "" ] ; then
			killall $1
		fi
		return 0
	else
		echo "The process you are trying to stop is not running!"
		return 1
	fi
}

restart_gw(){
	echo "Restart LoRa GW..."
	MODULE=`uci -c /mnt/data/config/ get mfg.system.lora_ee_cnt_0 | cut -c5-16 | tr -d '\n'`
	$LORA_EXE_PATH/reset_gw.sh
	#Make sure the module is not running
	if ! ps | grep -v grep | grep -q "$LORA_GW_EXE" ; then
		$LORA_EXE_PATH$LORA_GW_EXE -m $MODULE -d /dev/semtech0 -c $LORA_CFG_DIR/$CFG_NAME &
	fi
	gtk_led_ctl.sh lora on
}

check_exe_status(){
	local exe_fail_cnt=0
	if [ "$1" = "loragw" ]; then
		loragw_flag=0

		chk_ps=`pidof $LORA_GW_EXE`
		gw_running_cnt=`ps | grep $LORA_GW_EXE | grep -v grep | wc -l`
		if [ "$gw_cnt" = "0" ]; then
			echo "Don't have to check LoRa GW, since GW#=0"
			return 0
		fi
		if [[ "$chk_ps" != "" && "$gw_running_cnt" = "$gw_cnt" ]]; then
			rm -f $GW_CHECK_PATH
			LORA_GW_RETRY_NOW=0
			LORA_GW_RETRY_TAG=0
			return 0
		else
			if [ "$2" = "restart" ]; then
				echo "[LORA_WATCHDOG]: $LORA_GW_EXE has stopped!!! Re-launching it now..."
				date '+%c' >> $GW_KILLED_INFO_PATH
				stop_process $LORA_GW_EXE
				restart_gw
				LORA_GW_RETRY_NOW=0
				LORA_GW_RETRY_TAG=0
				return 0
			fi

			while [ $exe_fail_cnt -lt $lora_retry ]
			do
				chk_ps=`pidof $LORA_GW_EXE`
				gw_running_cnt=`ps | grep "$LORA_GW_EXE" | grep -v grep | wc -l`
				if [[ "$chk_ps" = "" || "$gw_running_cnt" != "$gw_cnt" ]]; then
					let exe_fail_cnt=$exe_fail_cnt+1
					sleep 1
					echo "Re-check loragw...($exe_fail_cnt)"
				else
					break
				fi
			done
			if [ "$exe_fail_cnt" = "$lora_retry" ]; then
				while [ 1 ]
				do
					if [[ "$LORA_GW_RETRY_ENABLE" = "1" && "$LORA_GW_RETRY_TAG" = "0" ]]; then
						echo "[LORA_WATCHDOG]: $LORA_GW_EXE has stopped!!! Re-try it now..."
						let LORA_GW_RETRY_NOW=$LORA_GW_RETRY_NOW+1
						#echo "LORA_GW_RETRY_NOW=$LORA_GW_RETRY_NOW ; LORA_GW_RETRY_TAG=$LORA_GW_RETRY_TAG" >> $GW_RETRY_INFO_PATH
						#date >> $GW_RETRY_INFO_PATH
						save_log_to_flash lora_gw
						if [ "$LORA_GW_RETRY_NOW" = "$LORA_GW_RETRY_MAX" ]; then
							LORA_GW_RETRY_TAG=1
							LORA_GW_RETRY_NOW=0
						else
							stop_process $LORA_GW_EXE
							restart_gw
							sleep 5

							chk_ps=`pidof $LORA_GW_EXE`
							gw_running_cnt=`ps | grep $LORA_GW_EXE | grep -v grep | wc -l`
							if [[ "$chk_ps" != "" && "$gw_running_cnt" = "$gw_cnt" ]]; then
								LORA_GW_RETRY_NOW=0
								LORA_GW_RETRY_TAG=0
								return 0
							fi
						fi
					else
						break
					fi
				done
				loragw_flag=1
				return 1
			else
				LORA_GW_RETRY_NOW=0
				LORA_GW_RETRY_TAG=0
				rm -f $GW_CHECK_PATH
				return 0
			fi
		fi
	else	
		echo "[check_lora_status]: Argument error!"
		return 1
	fi
}


do_main(){

	#To log lora error
	rm -f $LORA_WDG_DBG_FILE
	
	echo "Enable watchdog daemon for LoRa GW."
	
	#restart_conf_manager
	check_exe_status loragw restart

	
	#while [ 1 ]
	#do
	#	sleep $chk_period
	#	check_exe_status loragw restart
	#done
}

do_main $1
