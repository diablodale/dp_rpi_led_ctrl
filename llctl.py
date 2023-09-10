import sys
import usb1
#import time

USB_CTRL_SET_TIMEOUT = 5000
NET_VENDOR_ID = 0x0424
NET_PRODUCT_ID = 0xec00

GPIDX = 0
DUPIDX = 0
LNKIDX = 1
SPDIDX = 2

# these values make LEDs reflect LAN status
DUP_LED = 0x001
LNK_LED = 0x010
SPD_LED = 0x100

# these values are for controlling LEDs individually
DUP_LED_OVR = 0x1
LNK_LED_OVR = 0x2
SPD_LED_OVR = 0x4

# bitmask for configuration register
DUP_MASK = DUP_LED << 16 | DUP_LED_OVR << 4
LNK_MASK = LNK_LED << 16 | LNK_LED_OVR << 4
SPD_MASK = SPD_LED << 16 | SPD_LED_OVR << 4

MODE_OFF = 0
MODE_ON = 1
MODE_STATUS = 2
MODE_TOGGLE = 3
MODE_KEEP = 15
MODE_WRITE = 16
MODE_READ = 17
MODE_ERR = -1

def substring(string, begin, length):
    if string == None or len(string) == 0 or len(string) < begin or len(string) < (begin+length):
        return None
    return string[begin:begin+length]

def show_err(errstr):
    print("Error: {}\n\n".format(errstr))
    usage()

# TODO need to examine this ai function
def set_led_mode(handle, index, mode):
    if mode == MODE_OFF:
        value = 0
    elif mode == MODE_ON:
        value = 0xffff
    elif mode == MODE_STATUS:
        value = 0x5555
    elif mode == MODE_TOGGLE:
        value = 0xaaaa
    elif mode == MODE_KEEP:
        return
    else:
        return MODE_ERR

    if index == DUPIDX:
        mask = DUP_MASK
    elif index == LNKIDX:
        mask = LNK_MASK
    elif index == SPDIDX:
        mask = SPD_MASK
    else:
        return MODE_ERR

    buf = [0] * 2
    buf[0] = mask & 0xff
    buf[1] = (mask >> 8) & 0xff
    handle.controlWrite(usb1.TYPE_VENDOR | usb1.RECIPIENT_DEVICE | usb1.ENDPOINT_OUT, 0x01, value, index, buf, USB_CTRL_SET_TIMEOUT)

def ledmode(str):
    mode = MODE_ERR
    if str[0] == '0':
        mode = MODE_OFF
    if str[0] == '1':
        mode = MODE_ON
    if str[0] == 's':
        mode = MODE_STATUS
    if str[0] == 't':
        mode = MODE_TOGGLE
    return mode

def parse_cmdline(str, cmd_arr):
    # parse command line
    # these commands are valid:
    # w<value>
    # write a raw value to the configuration register, value is expected to be hex
    # r
    # read the configuration register and print on screen
    #
    # commands consisting of two characters
    # the first character stands for the LED
    # d: duplex LED
    # l: link LED
    # f: fast etherne LED
    # the second character is the command
    # 0: switch off LED
    # 1: switch on LED
    # t: toggle LED (valid only if former status was 0 or 1, otherwise mode is not changed
    # s: LED reflects one LAN parameter

    index = -1

    if len(str) == 1 and str[0] == 'r':
        return MODE_READ

    if len(str) >= 2 and str[0] == 'w':
        index = GPIDX
        cmd_arr[index] = int(str[1:], 16)
        return MODE_WRITE

    if len(str) == 2:
        if str[0] == 'd':
            index = DUPIDX
        elif str[0] == 'l':
            index = LNKIDX
        elif str[0] == 'f':
            index = SPDIDX

        if index != -1:
            mode = ledmode(str[1:])
            if mode != MODE_ERR:
                cmd_arr[index] = mode
                return MODE_KEEP

    show_err("Invalid command line argument: {}".format(str))
    return MODE_ERR

def usage():
    print("Usage: llctl <command> [<command> ...]")
    print("<command> can be one of the following:")
    print("  r: read the configuration register and print on screen")
    print("  w<value>: write a raw value to the configuration register, value is expected to be hex")
    print("  <led><mod>")
    print("    <led> can be d, l, f")
    print("      d: duplex LED")
    print("      l: link LED")
    print("      f: fast ethernet LED")
    print("    <mod> can be  0, 1, s, t")
    print("      0: switch off LED")
    print("      1: switch on LED")
    print("      s: show status as designed for this LED")
    print("      t: toggle LED. If LED was set to 's' before, 't' does nothing")
    exit(1)

def main():
    with usb1.USBContext() as context:
        handle = context.openByVendorIDAndProductID(NET_VENDOR_ID, NET_PRODUCT_ID)
        if handle is None:
            print("Device not found")
            return

        handle.claimInterface(0)

        cmd_arr = [0] * 3

        for i in range(1, len(sys.argv)):
            mode = parse_cmdline(sys.argv[i], cmd_arr)
            if mode == MODE_ERR:
                handle.releaseInterface()
                return

            if mode == MODE_READ:
                buf = handle.controlRead(usb1.TYPE_VENDOR | usb1.RECIPIENT_DEVICE | usb1.ENDPOINT_IN, 0x02, 0, 0, 2, USB_CTRL_SET_TIMEOUT)
                print("Configuration register: 0x{:04x}".format((buf[1] << 8) | buf[0]))
            elif mode == MODE_WRITE:
                buf = [0] * 2
                buf[0] = cmd_arr[GPIDX] & 0xff
                buf[1] = (cmd_arr[GPIDX] >> 8) & 0xff
                handle.controlWrite(usb1.TYPE_VENDOR | usb1.RECIPIENT_DEVICE | usb1.ENDPOINT_OUT, 0x02, 0, 0, buf, USB_CTRL_SET_TIMEOUT)
            elif mode == MODE_KEEP:
                set_led_mode(handle, DUPIDX, cmd_arr[DUPIDX])
                set_led_mode(handle, LNKIDX, cmd_arr[LNKIDX])
                set_led_mode(handle, SPDIDX, cmd_arr[SPDIDX])

        handle.releaseInterface()

if __name__ == "__main__":
    main()
