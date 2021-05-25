#/bin/sh
USBDISK_DEVICE="/dev/sda1"
SD_DEVICE="/dev/mmcblk0p1"
EMMC_DEVICE="/dev/mmcblk1"
XSPI_DEVICE="/dev/mtd0"
INI_FILE="/mnt/config.ini"


UPDATE_SOURCE=""
EMMC_IMAGE_NAME=""
EMMC_IMAGE_UPDATE=""
XSPI_IMAGE_NAME=""
XSPI_IMAGE_UPDATE=""


read_ini() {
    file=$1;section=$2;item=$3;
    val=$(awk -F '=' '/\['${section}'\]/{a=1} (a==1 && "'${item}'"==$1){a=0;print $2}' ${file}) 
    echo ${val} | tr -d '\n\r'
}
update_success()
{
	if [ $1 == "emmc" ]; then
		echo  -e '\033[0;33;1m Update system completed, The board can be booted from emmc now \033[0m'
	elif [ $1 == "xspi" ]; then
		echo  -e '\033[0;33;1m Update system completed, The board can be booted from xspi now \033[0m'
	fi
#	echo "timer" > /sys/class/leds/d22/trigger
#	echo "500" > /sys/class/leds/d22/delay_off
#	echo "500" > /sys/class/leds/d22/delay_on

}

update_fail()
{
	echo "Update system failed"
#	echo "timer" > /sys/class/leds/myd:green:user1/trigger
#	echo "100" > /sys/class/leds/myd:green:user1/delay_off
#	echo "100" > /sys/class/leds/myd:green:user1/delay_on

}
get_update_info_from_usb()
{
	if [ -b "$USBDISK_DEVICE" ]; then
		umount /mnt > /dev/null 2>&1
		mount $USBDISK_DEVICE /mnt > /dev/null 2>&1
		if [ -f "$INI_FILE" ]; then
			UPDATE_SOURCE="usb"
			EMMC_IMAGE_NAME=`read_ini $INI_FILE image-emmc name`
			EMMC_IMAGE_UPDATE=`read_ini $INI_FILE image-emmc update`
			XSPI_IMAGE_NAME=`read_ini $INI_FILE image-xspi name`
			XSPI_IMAGE_UPDATE=`read_ini $INI_FILE image-xspi update`
			echo  "===> read config file from USB"
		fi
		umount /mnt > /dev/null 2>&1
	else
		echo "===> can not found USB"
	fi
	
}
get_update_info_from_sd()
{
	if [ -b "$SD_DEVICE" ]; then
		umount /mnt > /dev/null 2>&1
		mount $SD_DEVICE /mnt > /dev/null 2>&1
		if [ -f $INI_FILE ]; then
			UPDATE_SOURCE="sd"
			EMMC_IMAGE_NAME=`read_ini $INI_FILE image-emmc name`
			EMMC_IMAGE_UPDATE=`read_ini $INI_FILE image-emmc update`
			XSPI_IMAGE_NAME=`read_ini $INI_FILE image-xspi name`
			XSPI_IMAGE_UPDATE=`read_ini $INI_FILE image-xspi update`
			echo  "===> read config file from SD"
		fi
		umount /mnt > /dev/null 2>&1
	else
		echo "===> can not found sd"
	fi	
}
update2emmc()
{
	if [ -b $1 ]; then
		mount $1 /mnt > /dev/null 2>&1
		if [ -f /mnt/$EMMC_IMAGE_NAME ]; then
			dd if=/mnt/$EMMC_IMAGE_NAME of=$EMMC_DEVICE bs=512 conv=fsync
			umount  /mnt > /dev/null 2>&1
			update_success "emmc"
	    else
			update_fail
		fi
	else
		update_fail 
	fi

}
update2xspi()
{
	if [ -b $1 ]; then
		mount $1 /mnt > /dev/null 2>&1
		echo "===> Update xspi form usb ......"
		if [ -f /mnt/$XSPI_IMAGE_NAME ]; then
			flash_erase $XSPI_DEVICE 0 0x400
			dd if=/mnt/$XSPI_IMAGE_NAME of=$XSPI_DEVICE
			umount  /mnt > /dev/null 2>&1
			update_success "xspi"
		else
			update_fail
		fi
	else
		update_fail
	fi
}
do_update_sys(){
	if [  ${EMMC_IMAGE_UPDATE} == "yes" ]; then
		echo "up emmc"
		if [ $1 == "usb" ]; then
			update2emmc $USBDISK_DEVICE
		else
			update2emmc $SD_DEVICE
		fi
		
	fi
	
	if [ ${XSPI_IMAGE_UPDATE} == "yes" ]; then
		echo "update xspi"
		if [ $1 == "usb" ]; then
			update2xspi $USBDISK_DEVICE
		else
			update2xspi $SD_DEVICE
		fi
		
	fi
}

if [ $# == 2 ]; then
	if [ $1 == "update2emmc" ]; then
		if [ $2 == "core" ]; then
			EMMC_IMAGE_NAME="myir-image-core-MYD-JLS1028.emmc.img"
			
			update2emmc $USBDISK_DEVICE
		elif [ $2 == "full" ]; then
			EMMC_IMAGE_NAME="myir-image-full-MYD-JLS1028.emmc.img"
			update2emmc $USBDISK_DEVICE
		fi
	elif [ $1 == "update2xspi" ]; then
			XSPI_IMAGE_NAME="myir-image-core-MYD-JLS1028.xspi.img"
			update2xspi $USBDISK_DEVICE
	
	fi

else
	get_update_info_from_usb
	get_update_info_from_sd

	if [ "$UPDATE_SOURCE" == "usb" ]; then
		do_update_sys usb
	elif [ "$UPDATE_SOURCE" == "sd" ]; then
		do_update_sys sd
	else
		echo "===> Normal boot"
    fi
fi



