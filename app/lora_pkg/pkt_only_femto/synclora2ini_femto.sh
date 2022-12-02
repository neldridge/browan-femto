#!/bin/sh

EEPM_CMD="/app/lora_pkg/pkt_only_femto/util_lgw_eeprom_femto"
END=5
SYNC_POWER="--w2ini-pwrt"
SYNC_RXOFS="--w2ini-rxofs"
SYNC_LBTOFS="--w2ini-lbtofs"

print_help()
{
	echo "Usage:"
	echo "$0 [id] [type] [oui] [path]"
	echo "    - id    { 0:loracard0, 1:loracard1 }"
	echo "    - type: { $SYNC_POWER | $SYNC_RXOFS | $SYNC_LBTOFS }"
	echo "    - oui:  { 3-byte or 5-byte | e.g. 1c497b or 00001c497b }"
	echo "    - path: { The specified file path (optional) | e.g. /app/boot0/cfg/lora_cfg.ini}"
	echo "e.g."
	echo "$0 0 $SYNC_POWER 1c497b"
	echo "$0 0 $SYNC_RXOFS 00001c497b"
	echo "$0 0 $SYNC_LBTOFS 1C497B"
	echo "$0 0 $SYNC_LBTOFS 1C497B /app/boot1/cfg/lora_cfg.ini"
	echo ""
}
do_main()
{
	if [ "$1" == "" -o "$2" == "" -o "$3" == "" ]
	then
		print_help
		exit 1
	fi
	
	if [ "$2" == "$SYNC_POWER" -o "$2" == "$SYNC_RXOFS" -o "$2" == "$SYNC_LBTOFS" ]
	then

		for i in $(seq 1 $END);
		do
			if [ "$4" == "" ]
			then
				$EEPM_CMD -d $1 $2 --oui $3
			else
				$EEPM_CMD -d $1 $2 --oui $3 -p $4
			fi	

			if [ "$?" == "0" ]
			then
				exit 0
			fi
			
		done
	else	
		print_help
	fi	

	exit 1
}

do_main $1 $2 $3 $4
