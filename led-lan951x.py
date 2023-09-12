#!/usr/bin/env python3

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
#   https://www.microchip.com/en-us/product/LAN9512
#   https://www.microchip.com/en-us/product/LAN9514
#   https://dominic.familie-radermacher.ch/computer/raspberry-pi/lan951x-led-ctl/

import argparse
from enum import Enum
import functools
import usb.core
import usb.util

TEST_USB_DEVICE = 'test'
LedMode = Enum('LedMode', ['OFF', 'ON', 'STATUS', 'KEEP'])

# vendor USB constants
USB_VENDOR_ID = 0x0424
USB_PRODUCT_ID = 0xEC00
USB_CTRL_REQ_TYPE_IN = usb.util.build_request_type(usb.util.CTRL_IN, usb.util.CTRL_TYPE_VENDOR, usb.util.CTRL_RECIPIENT_DEVICE)
USB_CTRL_REQ_TYPE_OUT = usb.util.build_request_type(usb.util.CTRL_OUT, usb.util.CTRL_TYPE_VENDOR, usb.util.CTRL_RECIPIENT_DEVICE)
USB_CTRL_REQ_WRITE_REG = 0xA0
USB_CTRL_REQ_READ_REG =	0xA1
USB_CTRL_DATA_SIZE = 4
USB_CTRL_TIMEOUT = 5000

# vendor GPIO configuration register
GPIO_LED_CFG_REGISTER = 0x24
GPIO_DATA_0 = 1 << 0
GPIO_DATA_1 = 1 << 1
GPIO_DATA_2 = 1 << 2
GPIO_DIR_0 = 1 << 4
GPIO_DIR_1 = 1 << 5
GPIO_DIR_2 = 1 << 6
GPIO_CTL_0 = 1 << 16
GPIO_CTL_1 = 1 << 20
GPIO_CTL_2 = 1 << 24

GPIO_DATA_ALL =	GPIO_DATA_0 | GPIO_DATA_1 | GPIO_DATA_2
GPIO_DIR_ALL = GPIO_DIR_0 | GPIO_DIR_1 | GPIO_DIR_2
GPIO_CTL_ALL = GPIO_CTL_0 | GPIO_CTL_1 | GPIO_CTL_2

GPIO_DUPLEX_MASK = GPIO_CTL_0 | GPIO_DIR_0 | GPIO_DATA_0
GPIO_LINK_MASK = GPIO_CTL_1 | GPIO_DIR_1 | GPIO_DATA_1
GPIO_SPEED_MASK = GPIO_CTL_2 | GPIO_DIR_2 | GPIO_DATA_2
GPIO_MASKS = [GPIO_DUPLEX_MASK, GPIO_LINK_MASK, GPIO_SPEED_MASK]

def str_to_led_mode(str):
    match str:
        case '0' | 'off':
            return LedMode.OFF
        case '1' | 'on':
            return LedMode.ON
        case 's' | 'status':
            return LedMode.STATUS
        case None:
            return LedMode.KEEP
    raise ValueError('invalid led mode')

def read_config(usb_device):
    if usb_device == TEST_USB_DEVICE:
        return 0x12345678
    bytes_raw = usb_device.ctrl_transfer(USB_CTRL_REQ_TYPE_IN, USB_CTRL_REQ_READ_REG, 0, GPIO_LED_CFG_REGISTER, USB_CTRL_DATA_SIZE, USB_CTRL_TIMEOUT)
    if len(bytes_raw) != USB_CTRL_DATA_SIZE:
        raise BrokenPipeError('Failed to read config')
    config = int.from_bytes(bytes_raw, byteorder='little')
    return config

def write_config(usb_device, config):
    if usb_device == TEST_USB_DEVICE:
        print('write: 0x{:08x}'.format(config))
        return
    bytes_raw = int.to_bytes(config, USB_CTRL_DATA_SIZE, byteorder='little')
    bytes_count = usb_device.ctrl_transfer(USB_CTRL_REQ_TYPE_OUT, USB_CTRL_REQ_WRITE_REG, 0, GPIO_LED_CFG_REGISTER, bytes_raw, USB_CTRL_TIMEOUT)
    if bytes_count != USB_CTRL_DATA_SIZE:
        raise BrokenPipeError('Failed to write config')

def get_usb_device(test):
    if test:
        return TEST_USB_DEVICE
    usb_device = usb.core.find(idVendor=USB_VENDOR_ID, idProduct=USB_PRODUCT_ID)
    if usb_device is None:
        raise KeyError('USB device not found. Do you have elevated/root privileges?')
    return usb_device

def main():
    # parse arguments; includes lan951x-led-ctl compatibility
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description='Control LAN951x LEDs\n(c) 2023 Dale Phurrough <dale@hidale.com>, GNU GPLv3.0 license', epilog='Hint: Usually requires elevated/root privileges')
    parser.add_argument('-r', '--read', nargs='?', const=16, type=int, choices=[2, 8, 10, 16], help='Output current LED configuration, little byte-order 32-bit, default base-16')
    parser.add_argument('-w', '--write', metavar='INT', type=functools.partial(int, base=0), help='Write value to LED configuration, little byte-order 32-bit')
    parser.add_argument('-d', '--duplex', '--fdx', choices=['0', 'off', '1', 'on', 's', 'status'], help='Full/duplex LED mode')
    parser.add_argument('-l', '--link', '--lnk', choices=['0', 'off', '1', 'on', 's', 'status'], help='Link activity LED mode')
    parser.add_argument('-s', '--speed', '--spd', choices=['0', 'off', '1', 'on', 's', 'status'], help='Ethernet speed LED mode')
    parser.add_argument('--test', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()

    # more validation of arguments
    if args.write is not None:
        if args.duplex or args.link or args.speed:
            raise ValueError('Cannot write and set individual LED modes at the same time')
        if not (0 <= args.write <= 0xFFFFFFFF):
            raise ValueError('Invalid write value {}'.format(args.write))

    # do actions
    led_config = None
    usb_device = get_usb_device(args.test)
    if args.read:
        led_config = read_config(usb_device)
        if args.read == 2:
            print('{:#032b}'.format(led_config))
        elif args.read == 8:
            print('{:#011o}'.format(led_config))
        elif args.read == 10:
            print('{:d}'.format(led_config))
        elif args.read == 16:
            print('{:#08x}'.format(led_config))

    if args.write is not None:
        write_config(usb_device, args.write)

    if args.duplex or args.link or args.speed:
        if led_config is None:
            led_config = read_config(usb_device)
        led_choices = [str_to_led_mode(args.duplex), str_to_led_mode(args.link), str_to_led_mode(args.speed)]
        for i in range(3):
            if led_choices[i] == LedMode.ON:
                led_config &= ~(GPIO_MASKS[i] & (GPIO_CTL_ALL | GPIO_DATA_ALL))
                led_config |= (GPIO_MASKS[i] & GPIO_DIR_ALL)
            if led_choices[i] == LedMode.OFF:
                led_config &= ~(GPIO_MASKS[i] & GPIO_CTL_ALL)
                led_config |= (GPIO_MASKS[i] & (GPIO_DIR_ALL | GPIO_DATA_ALL))
            if led_choices[i] == LedMode.STATUS:
                led_config &= ~(GPIO_MASKS[i] & (GPIO_DIR_ALL | GPIO_DATA_ALL))
                led_config |= (GPIO_MASKS[i] & GPIO_CTL_ALL)
        write_config(usb_device, led_config)

if __name__ == '__main__':
    main()
