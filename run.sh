#!/usr/bin/with-contenv bashio
# (c) Dale Phurrough. All rights reserved.

#bashio::cache.flush_all

echo "Running on os board=$(bashio::os.board)"
echo "Running on ha machine=$(bashio::info.machine)"
PROC_MODEL=$(cat /proc/cpuinfo | grep -E 'Model\s+:' | cut -f 2 -d ':' | cut -c 2-)
if [[ -z "$PROC_MODEL" ]]; then
    echo "Aborting! The kernel is not exporting Raspberry Pi model to /proc/cpuinfo"
    exit 1
fi

# https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/raspberry-pi/revision-codes.adoc
#PROC_REVISION_HEX=$(cat /proc/cpuinfo | grep -E 'Revision\s+:' | cut -f 2 -d ':' | cut -c 2-)
#PROC_REVISION=$(( 16#$PROC_REVISION_HEX ))
#REVISION_NEWCODE=$(( ($PROC_REVISION >> 23) & 1 ))
#REVISION_TYPE=$(( ($PROC_REVISION >> 4) & 16#ff ))
#echo "RPi proc model is: ${PROC_MODEL}"
#echo "RPi proc revision is: 0x${PROC_REVISION_HEX}"
#echo "RPi revision newcode is: ${REVISION_NEWCODE}"
#echo "RPi revision type is: ${REVISION_TYPE}"

# Determine LED files
if [[ -f "/sys/class/leds/ACT/trigger" ]]; then
    ACT_LED_FILE="ACT"
elif [[ -f "/sys/class/leds/led0/trigger" ]]; then
    ACT_LED_FILE="led0"
else
    echo "Unable to control activity LED. No known /sys/class/leds/xxx directory."
fi
if [[ -f "/sys/class/leds/PWR/trigger" ]]; then
    PWR_LED_FILE="PWR"
elif [[ -f "/sys/class/leds/led1/trigger" ]]; then
    PWR_LED_FILE="led1"
else
    echo "Unable to control power LED. No known /sys/class/leds/xxx directory."
fi

# Activity LED
if [[ -n "$ACT_LED_FILE" ]]; then
    CURRENT_ACTIVITY=$(grep -Eo '\[\w+' "/sys/class/leds/${ACT_LED_FILE}/trigger" | cut -c 2-)
    echo "Current hardware activity LED trigger is ${CURRENT_ACTIVITY}"
    NEXT_ACTIVITY=$(bashio::config '"Activity LED trigger"')
    echo "HA configuration activity LED trigger is ${NEXT_ACTIVITY}"
    if [[ "$NEXT_ACTIVITY" != "$CURRENT_ACTIVITY" ]]; then
        #echo $NEXT_ACTIVITY > /sys/class/leds/${ACT_LED_FILE}/trigger
        if [[ "$NEXT_ACTIVITY" != "none" ]]; then
            echo "Enabling activity LED with trigger=${NEXT_ACTIVITY}"
        else
            echo "Disabling activity LED"
            #echo "0" > /sys/class/leds/${ACT_LED_FILE}/brightness
        fi
    fi
fi

# Power LED
if [[ -n "$PWR_LED_FILE" ]]; then
    CURRENT_POWER=$(grep -Eo '\[\w+' "/sys/class/leds/${PWR_LED_FILE}/trigger" | cut -c 2-)
    echo "Current hardware power LED trigger is ${CURRENT_POWER}"
    [[ "$(bashio::config '"Power LED"')" == "true" ]] && NEXT_POWER="input" || NEXT_POWER="none"
    echo "HA configuration power LED trigger is ${NEXT_POWER}"
    if [[ "$NEXT_POWER" != "$CURRENT_POWER" ]]; then
        #echo $NEXT_POWER > /sys/class/leds/${PWR_LED_FILE}/trigger
        if [[ "$NEXT_POWER" != "none" ]]; then
            echo "Enabling power LED with trigger=${NEXT_POWER}"
        else
            echo "Disabling power LED"
            #echo "0" > /sys/class/leds/${PWR_LED_FILE}/brightness
        fi
    fi
fi

# Determine ethernet hardware
if lsusb | grep -q '0424:ec00'; then
    echo "Found LAN951x ethernet"
    ETHER_APP="/led-lan951x.py"
elif lsusb | grep -q '0424:7800'; then
    echo "Found LAN7800 ethernet"
    #ETHER_APP="/led-lan7800.py"
else
    echo "No known ethernet found"
    exit 0
fi

# Enable/disable ethernet LEDs
if [[ -n "$ETHER_APP" ]]; then
    echo "Using ${ETHER_APP} to control ethernet LEDs"
    CURRENT_ETHER=$($ETHER_APP --read 16)
    echo "Current ethernet LED state is ${CURRENT_ETHER}"
    NEXT_ETHERNET=$(bashio::config '"Ethernet LEDs"')
    if [[ "$NEXT_ETHERNET" == "true" ]]; then
        echo "Enabling ethernet LEDs"
        # $ETHER_APP --fdx=1 --lnk=1 --spd=1
    else
        echo "Disabling ethernet LEDs"
        # $ETHER_APP --fdx=0 --lnk=0 --spd=0
    fi
else
    echo "No app available to control ethernet LEDs"
fi

#echo "My IP address is $(hostname -i)"
#python3 -m http.server 8099 --bind 172.30.33.3
