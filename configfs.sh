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

# V2 module hardware spec can be found at the bottom of this page, section 6.3: https://picamera.readthedocs.io/en/latest/fov.html
#mkdir -p functions/uvc.0/streaming/mjpeg/m/1080p
#echo 333333 > functions/uvc.0/streaming/mjpeg/m/1080p/dwFrameInterval # 1/30fps*1000*1000*10 (not sure why needs *10)
#echo 1920 > functions/uvc.0/streaming/mjpeg/m/1080p/wWidth
#echo 1080 > functions/uvc.0/streaming/mjpeg/m/1080p/wHeight
#echo 17825792 > functions/uvc.0/streaming/mjpeg/m/1080p/dwMinBitRate # default is 17000000 (17Mbps, 17*1024*1024)
#echo 26214400 > functions/uvc.0/streaming/mjpeg/m/1080p/dwMaxBitRate # max is 25000000 (25Mbps, 25*1024*1024)
#echo 4147200 > functions/uvc.0/streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize # 1920*1080*2 (not sure why is 2, maybe YUV420?)

mkdir -p functions/uvc.0/streaming/mjpeg/m/720p
echo 166666 > functions/uvc.0/streaming/mjpeg/m/720p/dwFrameInterval # 1/60fps*1000*1000*10 (not sure why needs *10)
echo 1280 > functions/uvc.0/streaming/mjpeg/m/720p/wWidth
echo 720 > functions/uvc.0/streaming/mjpeg/m/720p/wHeight
echo 17825792 > functions/uvc.0/streaming/mjpeg/m/720p/dwMinBitRate # default is 17000000 (17Mbps, 17*1024*1024)
echo 26214400 > functions/uvc.0/streaming/mjpeg/m/720p/dwMaxBitRate # max is 25000000 (25Mbps, 25*1024*1024)
echo 1843200 > functions/uvc.0/streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize # 1280*720*2 (not sure why is 2, maybe YUV420?)

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
