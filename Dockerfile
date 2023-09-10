# (c) Dale Phurrough. All rights reserved.

ARG BUILD_FROM
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install python for dev-only: py3-pip, py3-usb, py3-libusb1
RUN apk add --no-cache python3
RUN apk add --no-cache py3-pip
# build since no alpine package available for release branch
RUN pip3 install --upgrade libusb1
RUN apk add --no-cache libusb

WORKDIR /

# Copy data for add-on
COPY run.sh listdevs.py /
RUN chmod a+x /run.sh /listdevs.py

# for rpi B+, rpi 2, rpi 3B
#sudo apt-get install libusb-1.0-0-dev
# https://dominic.familie-radermacher.ch/computer/raspberry-pi/lan951x-led-ctl/
#git clone https://github.com/dumpsite/lan951x-led-ctl.git
#cd lan951x-led-ctl/
#make
# alternate app https://forums.raspberrypi.com//viewtopic.php?t=72070

# for rpi 3B+ need LAN7800 LED control
# https://dominic.familie-radermacher.ch/computer/raspberry-pi/lan7800-led-ctl/

#sudo apt-get install libusb-1.0-0-dev

CMD [ "/run.sh" ]
