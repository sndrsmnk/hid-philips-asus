hid-philips-asus
================

Import of a source tree for a 'hid-philips-asus.ko' kernel module that enables
the use of the "PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS" infra red
remote device with id 0471:206C in XBMC through the USB HID layer.

There have been small tweaks to the code so this compiles with kernels >=3.8
and it is now a DKMS-package for Debian(-derivative) systems.


Manual quick install guide:
---------------------------

You will need some build-essential tools installed, and the headers for your
current running kernel:

```sh
apt-get install build-essential linux-headers-$(uname -r)
```

Then continue:

```sh
git clone https://github.com/sndrsmnk/hid-philips-asus.git
cd hid-philips-asus
make all
```

You must manually copy the resulting _hid-philips-asus.ko_ file to your
kernel's _/lib/modules/$(uname -r)/updates/_ directory.


Make debian package
-------------------
This codebase was intended to build a debian package that integrates with
DKMS (Dynamic Kernel Module Support Framework) on Debian(-derivative) systems.

To build the package, there's various ways to do so, one of which is:

```sh
apt-get install debhelper dkms fakeroot
git clone https://github.com/sndrsmnk/hid-philips-asus.git
cd hid-philips-asus
fakeroot debian/rules binary
```

This should leave you with a package _../hid-philips-asus_20161024-1_all.deb_
which you can _dpkg -i_ and have dkms build the module for your current kernel.


mceusb
------

Kernels >3.8 come with a 'mceusb.ko' module which claims this device
but does not support it with this specific piece of hardware. Perhaps
it does work with other hardware claiming to be this USB ID. This
module needs to be blacklisted.
It is also important to load the hid-philips-asus module BEFORE usbhid
loads, or it can't claim the device, so i'm adding a 'softdep'end on
the usbhid module to preload hid-philips-asus:

```sh
cat >/etc/modprobe.d/hid-philips-asus-local.conf <<EOT
# Place this file in /etc/modprobe.d/hid-philips-asus.conf
#
# Module mceusb claims to support this device but doesnt (fully).
blacklist mceusb
#
# Make sure hid-philips-asus is loaded before other HID modules.
softdep usbhid pre: hid-philips-asus
softdep hid-generic pre: hid-philips-asus
EOT

chmod 644 /etc/modprobe.d/hid-philips-asus.local
```


udev device symlink
-------------------
To provide a stable device name for a possibly changing eventN device i'm telling udev to create a symlink:

```sh
cat >>/etc/udev/rules.d/10-local.rules <<EOT
# Automatic symlink irremote to eventN device node.
KERNEL=="event*",ATTRS{idVendor}=="0471",ATTRS{idProduct}=="206c",SYMLINK="input/irremote"
EOT

chmod 644 /etc/udev/rules.d/10-local.rules
service udev reload
```

Now, ether unload mceusb and usbhid, then reload usbhid, or simply reboot at
this point. Then ensure the symlink /dev/input/irremote exists after reloading
the modules or plugging the device.

XBMC needs Lirc to work with this setup so i'm installing it:

```sh
apt-get install lirc
/etc/init.d/lirc stop

mv /etc/lirc /etc/lirc.OLD
mkdir /etc/lirc
cp contrib/lirc/* /etc/lirc/

/etc/init.d/lirc start
```

I can test with 'irw' if buttons pressed on the remote present any activity in Lirc:

```sh
irw
# press buttons on remote, should show up on console.
# control-c to quit
```

To enable a good set of functions, copy the XBMC configuration files:
```sh
# copy the contents of ../xbmc/ to your '.xbmc' data directory
# the user that runs your xbmc process has this in its homedirectory
cp -a contrib/xbmc/* ~xbmc/.xbmc/

# (re)start XBMC, it should Just Work
```



How can you tell it's working?
------------------------------

### When the device is plugged in, dmesg will show:
(confirm that philips_asus shows before usbhid does)
```sh
usb 2-1: new low-speed USB device number 3 using uhci_hcd
usb 2-1: New USB device found, idVendor=0471, idProduct=206c
usb 2-1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
usb 2-1: Product: MCE USB IR Receiver- Spinel plusf0r ASUS
usb 2-1: Manufacturer: PHILIPS
input: PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS as /devices/[ .. ]/input/inputNN
philips_asus 000x:0471:206C.000x: input: USB HID v1.00 Keyboard [PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS] on usb-[ .. ]/inputN
usbcore: registered new interface driver usbhid
usbhid: USB HID core driver
```

### A symlink to the 'eventN'-node should exist:
```
# ls -la /dev/input/{irremote,event7}
crw-r----- 1 root root 13, 71 Jan  2 10:04 event7
lrwxrwxrwx 1 root root      6 Jan  2 17:52 irremote -> event7
```

### When XBMC starts, look in dmesg:
(this line may occur each time XBMC (re)connects to lircd, that's okay)
```sh
input: PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS (lircd bypass) as /devices/virtual/input/inputNN
```
