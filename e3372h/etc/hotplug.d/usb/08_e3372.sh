#!/bin/sh

# Huawei E3372h CDC_NCM mode detector
# https://4pda.ru/forum/index.php?showtopic=582284&view=findpost&p=100309827
# Pls, report issues at https://github.com/vortigont/openwrt-more/

[ "$ACTION" = add -a "$DEVTYPE" = usb_interface ] || [ "$ACTION" = remove -a "$DEVTYPE" = usb_interface ] || exit 0

# detect Huawei E3372 in CDC_NCM mode
ID='12d1/155e'
NCM_DEVNAME='1-1:1.3'

#hvid=12d1
#hpid=155e
#ttydev="/dev/ttyUSB2"

. /lib/functions.sh
. /lib/netifd/netifd-proto.sh

# check for E3372 NCM interface 
[ "$PRODUCT" != "${PRODUCT#$ID}" ] || exit 0
[ "$DEVICENAME" = "$NCM_DEVNAME" ] || exit 0

logger -t DEBUG "hotplug usb: Huawei E3372 status changed"

find_wwan_iface() {
	local cfg="$1"
	local proto
	config_get proto "$cfg" proto
	[ "$proto" = ncm ] || return 0
	if [ "$ACTION" = add ]; then
		proto_set_available "$cfg" 1
		ifup $cfg
		logger -t DEBUG "Enabling interface $cfg"
	else
		proto_set_available "$cfg" 0
                # https://bugs.openwrt.org/index.php?do=details&task_id=1726
                #logger -t DEBUG "Killing netifd due to wwan interface down bug"
                #killall netifd
		logger -t DEBUG "Disabling interface $cfg"
                #ifdown $cfg
	fi
	exit 0
}

config_load network
config_foreach find_wwan_iface interface
