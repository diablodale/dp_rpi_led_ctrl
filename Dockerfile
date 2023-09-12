# (c) Dale Phurrough. All rights reserved.

ARG BUILD_FROM
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install python for dev-only: py3-pip, py3-usb, py3-libusb1
RUN apk add --no-cache python3 py3-usb
#RUN apk add --no-cache py3-pip
# build libusb1 since no alpine package available for release branch
#RUN pip3 install --upgrade libusb1
#RUN apk add --no-cache libusb

WORKDIR /

# Copy data for add-on
COPY run.sh led-lan951x.py /
RUN chmod a+x /run.sh /led-lan951x.py

CMD [ "/run.sh" ]
