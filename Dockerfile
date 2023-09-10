# (c) Dale Phurrough. All rights reserved.

ARG BUILD_FROM
FROM $BUILD_FROM

# Install python for dev-only
#RUN \
#  apk add --no-cache \
#    python3

WORKDIR /

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

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
