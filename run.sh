#!/usr/bin/with-contenv bashio

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

echo "Running on os board=$(bashio::os.board)"
echo "Running on ha machine=$(bashio::info.machine)"

# Enable/disable activity and power LEDs
NEXT_ACTIVITY=$(bashio::config '"Activity LED trigger"')
[[ "$(bashio::config '"Power LED"')" == "true" ]] && NEXT_POWER="on" || NEXT_POWER="off"
echo "HA configuration activity LED trigger: ${NEXT_ACTIVITY}"
echo "HA configuration power LED trigger: ${NEXT_POWER}"
./led-rpi.sh -v -a "${NEXT_ACTIVITY}" -p "${NEXT_POWER}"

# Determine ethernet hardware
if lsusb | grep -q '0424:ec00'; then
    echo "Found LAN951x ethernet"
    ETHER_APP="/led-lan951x.py"
elif lsusb | grep -q '0424:7800'; then
    echo "Found LAN7800 ethernet"
    #ETHER_APP="/led-lan7800.py"
else
    echo "No known ethernet"
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
        $ETHER_APP -d 1 -l 1 -s 1
    else
        echo "Disabling ethernet LEDs"
        $ETHER_APP -d 0 -l 0 -s 0
    fi
else
    echo "No app available to control ethernet LEDs"
fi

#echo "whoami: $(whoami)"
#echo "My IP address is $(hostname -i)"
#python3 -m http.server 8099 --bind 172.30.33.3
