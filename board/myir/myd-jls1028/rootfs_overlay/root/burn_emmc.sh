#!/bin/sh
PART=1
EMMC_NODE=/dev/mmcblk${PART}

BOOT_FILE=/root/mfgimage/firmware_ls1028amyir_uboot_emmcboot.img 
KERNEL_DTB_DIR=/root/mfgimage/bootpartition_LS_arm64_lts_5.4.tgz
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs_lsdk2012_ubuntu_main_arm64.tgz

MYD_NAME="MYD-JLS1028"

HOSTNAME=`cat /etc/hostname`

if [ x"$HOSTNAME" == x"$MYD_NAME" ];then
  led1=d22
elif [ x"$HOSTNAME" == x"$MYS_NAME" ];then
  led1=user
  led2=cpu
fi

LED_PID=-1
time=0.2

ECHO_TTY="/dev/ttyS0"
check_run_count(){
	if ! mkdir /tmp/myscript.lock 2>/dev/null; then
	echo "Myscript is already running." >&2
	exit 0
	fi
}
burn_start_ing(){

	echo "***********************************************" >> ${ECHO_TTY} 
	echo "*************    SYSTEM UPDATE    *************" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
    echo "*************   Update starting   *************" >> ${ECHO_TTY}  
    echo "***********************************************" >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 

	#核心板上的绿灯闪烁则烧写中
	echo 0 > /sys/class/leds/${led1}/brightness

	while [ 1 ]
	do
		echo 1 > /sys/class/leds/${led1}/brightness
		sleep $time
		echo 0 > /sys/class/leds/${led1}/brightness
		sleep $time
        echo "*************   Updating   *************" >> ${ECHO_TTY} 
	done
}

burn_faild(){
    kill $LED_PID

	# 熄灭
	echo 0 > /sys/class/leds/${led1}/brightness

    echo "Update faild..."   >> ${ECHO_TTY} 
    echo "Update faild..."   >> ${ECHO_TTY} 
    echo "Update faild..."   >> ${ECHO_TTY} 
	echo $'>>>[100]{\"step\":\"firmware\",\"result\":{\"bootloader\":\"2\",\"kernel\":\"2\",\"rootfs\":\"2\",\"data\":\"2\"}}\r\n'
}

burn_succeed(){
    
    kill $LED_PID

	# 常亮
	echo 1 > /sys/class/leds/${led1}/brightness

	echo "***********************************************" >> ${ECHO_TTY} 
	echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
    echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
    echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
    echo "***********************************************" >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
 echo $'>>>[86]{\"step\":\"firmware\",\"result\":{\"bootloader\":\"0\",\"kernel\":\"0\",\"rootfs\":\"0\",\"data\":\"0\"}}\r\n'

}

echo_fun(){
	echo "***********************************************" >> ${ECHO_TTY} 
	echo "********    "$1 "  ***********" >> ${ECHO_TTY}
    echo "***********************************************" >> ${ECHO_TTY} 
}

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo "$2 failed!"   >> ${ECHO_TTY}
        echo "$2 failed!"   >> ${ECHO_TTY}
        echo "$2 failed!"   >> ${ECHO_TTY}
		burn_faild 
		
        exit -1
	fi
}

mksdcard(){
flex-installer -i pf -d /dev/mmcblk1 -p 4P=128M:2G:64M:-1
#flex-installer -i pf -d ${EMMC_NODE}
sleep 2

}

enable_bootpart(){
    mmc bootpart enable 1 1 /dev/mmcblk${PART}
}

burn_bootloader(){
    #echo 0 > /sys/block/mmcblk${PART}boot0/force_ro
	flex-installer -f ${BOOT_FILE} -d  /dev/mmcblk1
    cmd_check $? "boot faild"
    sleep 2
   

    #echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}
check_sh_run(){
	n=`ps -ef|grep "update_time.sh"|grep -v grep|wc -l`
	if [ $n -gt 2 ]; then
	exit 0
	fi	
}
burn_kernel_dtb(){

  flex-installer -b ${KERNEL_DTB_DIR} -r ${ROOTFS_FILE_EXT4} -d /dev/mmcblk1
    cmd_check $? "burn kernel dtb faild"
    sync
    umount /mnt
    sleep 1
}


reszie2fs_mmc(){
    resize2fs /dev/mmcblk${PART}p4
    cmd_check $? "reszi    sync"
}

check_rootfs(){
    mount /dev/mmcblk${PART}p4 /mnt/
    rootfs_hostname=`cat /mnt/etc/hostname`
    echo_fun "rootfs_hostname:$rootfs_hostname"

    if [ x"$rootfs_hostname" != x"localhost" ];then
       echo_fun "not equal"
       reboot
    else
       echo_fun "equal"
    fi
  umount /mnt

}
check_run_count
burn_start_ing &
LED_PID=$!
sleep 1
echo_fun "start format mmc "
echo "${EMMC_NODE}"
mksdcard 
echo_fun "start burn uboot "
burn_bootloader
echo_fun "start burn kernel and rootfs"
burn_kernel_dtb
reszie2fs_mmc
check_rootfs
burn_succeed
