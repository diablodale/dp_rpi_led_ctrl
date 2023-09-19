#!/usr/bin/env bash

# Copyright (C) 2023 Dale Phurrough <dale@hidale.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# References:
#   https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/raspberry-pi/revision-codes.adoc

# TODO: add support for arbitrary activity triggers like cpu, timer, heartbeat, etc.

# Parse command line arguments
while getopts ":a:hp:v" options; do
    case "${options}" in
        a)
            NEXT_ACTIVITY=${OPTARG}
            ;;
        h)
            echo -e "usage: led-rpi.sh [-a {0,off,1,on}] [-p {0,off,1,on}] [-v] [-h]\n"
            echo "Control Raspberry Pi LEDs"
            echo -e "(c) 2023 Dale Phurrough <dale@hidale.com>, GNU GPLv3.0 license\n"
            echo "optional arguments:"
            echo "  -a {0,off,1,on}       activity LED mode"
            echo "  -p {0,off,1,on}       power LED mode"
            echo "  -v                    verbose"
            echo -e "  -h                    show this help message and exit\n"
            echo "Hint: Usually requires elevated/root privileges"
            exit 0
            ;;
        p)
            NEXT_POWER=${OPTARG}
            ;;
        v)
            VERBOSE=1
            ;;
        :)
            echo "Error: -${OPTARG} requires an argument"
            exit 1
            ;;
        *)
            echo "Error: unknown option -${OPTARG}"
            exit 1
            ;;
    esac
done
if [[ -z "$NEXT_ACTIVITY" && -z "$NEXT_POWER" ]]; then
    exit 0
fi

# Probe Raspberry Pi information
PROC_MODEL=$(cat /proc/cpuinfo | grep -E 'Model\s+:' | cut -f 2 -d ':' | cut -c 2-)
PROC_REVISION_HEX=$(cat /proc/cpuinfo | grep -E 'Revision\s+:' | cut -f 2 -d ':' | cut -c 2-)
if [[ -z "$PROC_MODEL" || -z "$PROC_REVISION_HEX" ]]; then
    echo "Aborting! The kernel is not exporting Raspberry Pi info to /proc/cpuinfo"
    exit 1
fi
PROC_REVISION=$(( 16#$PROC_REVISION_HEX ))
REVISION_NEWCODE=$(( ($PROC_REVISION >> 23) & 1 ))
REVISION_TYPE=$(( ($PROC_REVISION >> 4) & 16#ff ))

# Validate support for Raspberry Pi model
if [[ "$REVISION_NEWCODE" -eq 1 ]]; then
    case "$REVISION_TYPE" in
        2|3|4)
            RPI_CLASS="Raspberry Pi A+, B+, 2B"
            DEFAULT_ACTIVITY="mmc0"
            DEFAULT_POWER="input"
            ;;
        8)
            RPI_CLASS="Raspberry Pi 3B"
            DEFAULT_ACTIVITY="mmc0"
            DEFAULT_POWER="input"
            ;;
        9)
            #RPI_CLASS="Raspberry Pi Zero"
            # TODO need to validate, one article suggests brightness is inverted so 0=on, 1=off
            # DEFAULT_ACTIVITY="mmc0"
            ;;
        13|14)
            #RPI_CLASS="Raspberry Pi 3A+, 3B+"
            ;;
        17)
            RPI_CLASS="Raspberry Pi 4B"
            DEFAULT_ACTIVITY="mmc0"
            DEFAULT_POWER="default-on"
            ;;
    esac
fi
[[ "$VERBOSE" == "1" ]] && echo "RPi proc model: ${PROC_MODEL}"
[[ "$VERBOSE" == "1" ]] && echo "RPi proc revision code: 0x${PROC_REVISION_HEX}"
[[ "$VERBOSE" == "1" ]] && echo "RPi revision newcode: ${REVISION_NEWCODE}"
[[ "$VERBOSE" == "1" ]] && echo "RPi revision type: ${REVISION_TYPE}"
[[ "$VERBOSE" == "1" ]] && echo "RPi class: ${RPI_CLASS}"
if [[ -z "$RPI_CLASS" ]]; then
    echo "Error: no support for this Raspberry Pi revision type ${REVISION_TYPE}"
    exit 1
fi

# map option values to triggers
case "${NEXT_ACTIVITY}" in
    on|mmc0|1)
        NEXT_ACTIVITY="$DEFAULT_ACTIVITY"
        ;;
    off|none|0)
        NEXT_ACTIVITY="none"
        ;;
    '')
        unset NEXT_ACTIVITY
        ;;
    *)
        echo "Error: unknown activity ${NEXT_ACTIVITY}"
        exit 1
        ;;
esac
case "${NEXT_POWER}" in
    on|1)
        NEXT_POWER="$DEFAULT_POWER"
        ;;
    off|0)
        NEXT_POWER="none"
        ;;
    '')
        unset NEXT_POWER
        ;;
    *)
        echo "Error: unknown power ${NEXT_POWER}"
        exit 1
        ;;
esac

# Determine LED files; kernel 6.1 changed from led0 -> ACT, led1 -> PWR
if [[ -f "/sys/class/leds/ACT/trigger" ]]; then
    ACTIVITY_LED_FILE="ACT"
elif [[ -f "/sys/class/leds/led0/trigger" ]]; then
    ACTIVITY_LED_FILE="led0"
else
    echo "Unable to control activity LED. No known /sys/class/leds/xxx directory."
fi
if [[ -f "/sys/class/leds/PWR/trigger" ]]; then
    POWER_LED_FILE="PWR"
elif [[ -f "/sys/class/leds/led1/trigger" ]]; then
    POWER_LED_FILE="led1"
else
    echo "Unable to control power LED. No known /sys/class/leds/xxx directory."
fi

# Activity LED
if [[ -n "$NEXT_ACTIVITY" && -n "$ACTIVITY_LED_FILE" ]]; then
    CURRENT_ACTIVITY=$(grep -Eo '\[[^]]+' "/sys/class/leds/${ACTIVITY_LED_FILE}/trigger" | cut -c 2-)
    [[ "$VERBOSE" == "1" ]] && echo "Current   activity LED trigger: ${CURRENT_ACTIVITY}"
    [[ "$VERBOSE" == "1" ]] && echo "Candidate activity LED trigger: ${NEXT_ACTIVITY}"
    if [[ "$NEXT_ACTIVITY" != "$CURRENT_ACTIVITY" ]]; then
        echo $NEXT_ACTIVITY > /sys/class/leds/${ACTIVITY_LED_FILE}/trigger
        if [[ "$NEXT_ACTIVITY" != "none" ]]; then
            [[ "$VERBOSE" == "1" ]] && echo "Enabling activity LED with trigger: ${NEXT_ACTIVITY}"
        else
            [[ "$VERBOSE" == "1" ]] && echo "Disabling activity LED"
            echo "0" > /sys/class/leds/${ACTIVITY_LED_FILE}/brightness
        fi
    fi
fi

# Power LED
if [[ -n "$NEXT_POWER" && -n "$POWER_LED_FILE" ]]; then
    CURRENT_POWER=$(grep -Eo '\[[^]]+' "/sys/class/leds/${POWER_LED_FILE}/trigger" | cut -c 2-)
    [[ "$VERBOSE" == "1" ]] && echo "Current   power LED trigger: ${CURRENT_POWER}"
    [[ "$VERBOSE" == "1" ]] && echo "Candidate power LED trigger: ${NEXT_POWER}"
    if [[ "$NEXT_POWER" != "$CURRENT_POWER" ]]; then
        echo $NEXT_POWER > /sys/class/leds/${POWER_LED_FILE}/trigger
        if [[ "$NEXT_POWER" != "none" ]]; then
            [[ "$VERBOSE" == "1" ]] && echo "Enabling power LED with trigger: ${NEXT_POWER}"
        else
            [[ "$VERBOSE" == "1" ]] && echo "Disabling power LED"
            echo "0" > /sys/class/leds/${POWER_LED_FILE}/brightness
        fi
    fi
fi
