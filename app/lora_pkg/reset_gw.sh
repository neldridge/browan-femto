#!/bin/sh

DEF_LORA_RESET_PIN0=`uci get lora.global.spi_reset_pin0`
if [[ "$DEF_LORA_RESET_PIN0" = "" || "$DEF_LORA_RESET_PIN0" = "NA" ]]; then
	DEF_LORA_RESET_PIN0=60
fi

DEF_LORA_RESET_PIN1=`uci get lora.global.spi_reset_pin1`
if [[ "$DEF_LORA_RESET_PIN1" = "" || "$DEF_LORA_RESET_PIN1" = "NA" ]]; then
	DEF_LORA_RESET_PIN1=27
fi

DEF_LORA_PWR_PIN0=`uci get lora.global.spi_pwr_pin0`
if [[ "$DEF_LORA_PWR_PIN0" = "" || "$DEF_LORA_PWR_PIN0" = "NA" ]]; then
	DEF_LORA_PWR_PIN0=30
fi

DEF_LORA_PWR_PIN1=`uci get lora.global.spi_pwr_pin1`
if [[ "$DEF_LORA_PWR_PIN1" = "" || "$DEF_LORA_PWR_PIN1" = "NA" ]]; then
	DEF_LORA_PWR_PIN1=32
fi


LORA_SPI_RESET_PIN_0="$DEF_LORA_RESET_PIN0"
LORA_SPI_RESET_PIN_1="$DEF_LORA_RESET_PIN1"

LORA_SPI_PWR_PIN_0="$DEF_LORA_PWR_PIN0"
LORA_SPI_PWR_PIN_1="$DEF_LORA_PWR_PIN1"

#General gpio setting
gpio_hl(){
	if [ "$2" = "h" ]; then
		/usr/bin/gpio l $1 0 4000 0 0 0
	else
		/usr/bin/gpio l $1 4000 0 0 0 0
	fi
}

#To reset LoRa Pin, low->high->low
do_reset(){
	if [[ "$1" = "" ||  "$1" = "0" ]]; then
		gpio_hl $LORA_SPI_RESET_PIN_0 l
		gpio_hl $LORA_SPI_RESET_PIN_0 h
sleep 1
		gpio_hl $LORA_SPI_RESET_PIN_0 l
	elif [ "$1" = "1" ]; then
		gpio_hl $LORA_SPI_RESET_PIN_1 l
		gpio_hl $LORA_SPI_RESET_PIN_1 h
		sleep 1
		gpio_hl $LORA_SPI_RESET_PIN_1 l
	fi	
}

#To power off/on LoRa Pin, high->low->high
do_pwr_onoff(){
	if [[ "$1" = "" ||  "$1" = "0" ]]; then
		gpio_hl $LORA_SPI_PWR_PIN_0 h
		gpio_hl $LORA_SPI_PWR_PIN_0 l
		sleep 1
		gpio_hl $LORA_SPI_PWR_PIN_0 h
	elif [ "$1" = "1" ]; then
		gpio_hl $LORA_SPI_PWR_PIN_1 h
		gpio_hl $LORA_SPI_PWR_PIN_1 l
sleep 1
		gpio_hl $LORA_SPI_PWR_PIN_1 h
	fi	
}

do_main(){
	if [[  "$1" != "" && "$1" != "0" && "$1" != "1" ]]; then
		echo "[$?]: This script only support 0/1 or 0 by default (no input)"
		return 0
	fi
	now_pwr_reset=`uci get lora.global.spi_pwr_reset_disable`
	if [ "$now_pwr_reset" = "0" ]; then
		do_pwr_onoff $1
	fi
	do_reset $1
}

do_main $1


