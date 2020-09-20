#!/bin/sh
# Use ConfigFS to create USB composite gadget device and bind to a USB Device Controller (UDC) from userspace
#
# Before running this script on RaspberryPi, make sure:
# 1. Camera interface is enabled
# 2. /boot/config.txt has dtoverlay=dwc2
# 3. /boot/cmdline.txt has modules-load=dwc2,libcomposite

cd /sys/kernel/config/usb_gadget/

# Create gadget
mkdir -p iSight

# Set vendor and product IDs
cd iSight
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

# Create description
mkdir -p strings/0x409
echo "A1023" > strings/0x409/serialnumber
echo "Apple Inc." > strings/0x409/manufacturer
echo "iSight" > strings/0x409/product

# Create configuration with description
mkdir -p configs/c.1/strings/0x409
echo "iSight" > configs/c.1/strings/0x409/configuration
echo 500 > configs/c.1/MaxPower

# Create USB Video Class (UVC) functions
mkdir -p functions/uvc.0/control/header/h
ln -s functions/uvc.0/control/header/h functions/uvc.0/control/class/fs # fullspeed
ln -s functions/uvc.0/control/header/h functions/uvc.0/control/class/ss # superspeed

mkdir -p functions/uvc.0/streaming/mjpeg/m/720p
echo 5000000 > functions/uvc.0/streaming/mjpeg/m/720p/dwFrameInterval
echo 1280 > functions/uvc.0/streaming/mjpeg/m/720p/wWidth
echo 720 > functions/uvc.0/streaming/mjpeg/m/720p/wHeight
echo 10000000 > functions/uvc.0/streaming/mjpeg/m/720p/dwMinBitRate
echo 696254464 > functions/uvc.0/streaming/mjpeg/m/720p/dwMaxBitRate
echo 7372800 > functions/uvc.0/streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize

# Create headers
mkdir -p functions/uvc.0/streaming/header/h
ln -s functions/uvc.0/streaming/mjpeg/m functions/uvc.0/streaming/header/h/m
ln -s functions/uvc.0/streaming/header/h functions/uvc.0/streaming/class/fs/h #fullspeed
ln -s functions/uvc.0/streaming/header/h functions/uvc.0/streaming/class/hs/h #highspeed
ln -s functions/uvc.0/streaming/header/h functions/uvc.0/streaming/class/ss/h #superspeed

# Assign configuration to function
ln -s functions/uvc.0 configs/c.1/

# Wait 5 seconds for pending udev events to be handled in udev event queue
udevadm settle -t 5 || :

# Bind USB Device Controller (UDC)
ls /sys/class/udc > UDC

# To verify, after running this script, dmseg will have something like this:
# [    8.809590] dwc2 20980000.usb: 20980000.usb supply vusb_d not found, using dummy regulator
# [    8.870700] dwc2 20980000.usb: 20980000.usb supply vusb_a not found, using dummy regulator
# [    9.197453] dwc2 20980000.usb: EPs: 8, dedicated fifos, 4080 entries in SPRAM
# [    9.238694] dwc2 20980000.usb: DWC OTG Controller
# [    9.246950] dwc2 20980000.usb: new USB bus registered, assigned bus number 1
# [    9.327827] dwc2 20980000.usb: irq 33, io mem 0x20980000
# [  439.903836] configfs-gadget gadget: uvc: uvc_function_bind()
# [  439.910664] dwc2 20980000.usb: bound driver configfs-gadget
