#!/usr/bin/with-contenv bashio
# (c) Dale Phurrough. All rights reserved.

bashio::cache.flush_all

#echo "Starting rpi_hw_plus version $(bashio::addon.version)!"
echo "Running on os board=$(bashio::os.board)"
echo "Running on ha machine=$(bashio::info.machine)"
DEVTREE_MODEL=$(tr -d '\0' < /device-tree/model)
echo "device-tree model is: ${DEVTREE_MODEL}"
# /device-tree is /sys/firmware/devicetree/base

# determine led file
RPI_MODEL="RPI3B"
if [[ "$RPI_MODEL" == "RPI3B" ]]; then
    if [[ "$DEVTREE_MODEL" == "Raspberry Pi 3 Model B Rev 1.2" ]]; then
        ACT_LED_FILE="ACT"
        PWR_LED_FILE="PWR"
    else
        unset RPI_MODEL
    fi
#elif [ "$RPI_MODEL" == "RPI4B" ]; then
    #ACT_LED_FILE="led0"
    #PWR_LED_FILE="led1"
fi
if [[ -z "$RPI_MODEL" ]]; then
    echo "Unknown RPI model"
    exit 1
fi

# Enable/disable activity LED
ACTIVITY=$(bashio::config 'activity_led')
if [[ "$ACTIVITY" == "true" ]]; then
    echo "Enabling activity LED"
    #echo mmc0 > "/sys/class/leds/${ACT_LED_FILE}/trigger"
else
    echo "Disabling activity LED"
    #echo none > /sys/class/leds/${ACT_LED_FILE}/trigger
    #echo 0 > /sys/class/leds/${ACT_LED_FILE}/brightness
fi

# Enable/disable power LED
POWER=$(bashio::config 'power_led')
if [[ "$POWER" == "true" ]]; then
    echo "Enabling power LED"
    #echo input > /sys/class/leds/${PWR_LED_FILE}/trigger
else
    echo "Disabling power LED"
    #echo none > /sys/class/leds/${PWR_LED_FILE}/trigger
    #echo 0 > /sys/class/leds/${PWR_LED_FILE}/brightness
fi

# determine ethernet hardware
if lsusb | grep -q '0424:ec00'; then
    echo "found SMSC9512/9514 ethernet adapter"
    ETHERNET_MODEL="SMSC9512/9514"
elif lsusb | grep -q '0424:7800'; then
    echo "found LAN7800 ethernet adapter"
    ETHERNET_MODEL="LAN7800"
fi
if [[ -z "$ETHERNET_MODEL" ]]; then
    echo "Unknown Ethernet model"
    exit 1
fi

# Enable/disable Ethernet LEDs
# need to validate hardware ether chip
# cat /sys/firmware/devicetree/base/model
#      Raspberry Pi 3 Model B Rev 1.2
ETHERNET=$(bashio::config 'ethernet_leds')
if [[ "$ETHERNET" == "true" ]]; then
    echo "Enabling Ethernet LEDs"
    #lan951x-led-ctl --fdx=1 --lnk=1 --spd=1
else
    echo "Disabling Ethernet LEDs"
    #lan951x-led-ctl --fdx=0 --lnk=0 --spd=0
fi

#python3 -m pip list
python3 /listdevs.py

python3 -m http.server 8000
