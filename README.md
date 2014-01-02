hid-philips-asus
================

Import of a source tree for a 'hid-philips-asus.ko' kernel module that enables
the use of the "PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS" infra red
remote device with id 0471:206C in XBMC through the USB HID layer.

It was imported as-is. There have been small tweaks to the Makefile so this
code compiles with kernels >=3.8. It was confirmed to work with kernels
3.12.0-7-generic (Ubuntu Saucy) and 3.11.0-14-generic (Ubuntu Raring).



Quick install guide:
--------------------

You will need some build-essential tools installed, and the headers for your
current running kernel:
<pre>
apt-get install build-essential linux-headers-$(uname -r)
</pre>

Then continue:
<pre>
git clone https://github.com/sndrsmnk/hid-philips-asus.git

cd hid-philips-asus/src
make install
</pre>

Kernels >3.8 come with a 'mceusb.ko' module which claims this device
but does not support it with this specific piece of hardware. Perhaps
it does work with other hardware claiming to be this USB ID. This
module needs to be blacklisted.
It is also important to load the hid-philips-asus module BEFORE usbhid
loads, or it can't claim the device, so i'm adding a 'softdep'end on
the usbhid module to preload hid-philips-asus:
<pre>
cat &gt;/etc/modprobe.d/hid-philips-asus-local.conf &lt;&lt;EOT
# Module mceusb claims to support this device but doesnt
blacklist mceusb
# Module hid-philips-asus needs to be loaded before usbhid
softdep usbhid pre: hid-philips-asus
EOT

chmod 644 /etc/modprobe.d/hid-philips-asus.local
</pre>

To provide a stable device name for a possibly changing eventN device
i'm telling udev to create a symlink:
<pre>
cat &gt;&gt;/etc/udev/rules.d/10-local.rules &lt;&lt;EOT
# Automatic symlink irremote to eventN device node.
KERNEL=="event&#42;",ATTRS{idVendor}=="0471",ATTRS{idProduct}=="206c",SYMLINK="input/irremote"
EOT

chmod 644 /etc/udev/rules.d/10-local.rules
service udev reload
</pre>

Now, ether unload mceusb and usbhid, then reload usbhid, or simply reboot at
this point. Then ensure the symlink /dev/input/irremote exists after reloading
the modules or plugging the device.

XBMC needs Lirc to work with this setup so i'm installing it:
<pre>
apt-get install lirc
/etc/init.d/lirc stop

rm -rf /etc/lirc/&#42;
cp ../lirc/&#42; /etc/lirc/

/etc/init.d/lirc start
</pre>

I can test with 'irw' if buttons pressed on the remote present any activity in Lirc:
<pre>
irw
# press buttons on remote, should show up on console.
# control-c to quit
</pre>

To enable a good set of functions, copy the XBMC configuration files:
<pre>
# copy the contents of ../xbmc/ to your '.xbmc' data directory
# the user that runs your xbmc process has this in its homedirectory
cp -a ../xbmc/&#42; ~xbmc/.xbmc/

# (re)start XBMC, it should Just Work
</pre>



How can you tell it's working?
------------------------------

### When the device is plugged in, dmesg will show:
(confirm that philips_asus shows before usbhid does)
<pre>
usb 2-1: new low-speed USB device number 3 using uhci_hcd
usb 2-1: New USB device found, idVendor=0471, idProduct=206c
usb 2-1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
usb 2-1: Product: MCE USB IR Receiver- Spinel plusf0r ASUS
usb 2-1: Manufacturer: PHILIPS
input: PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS as /devices/[ .. ]/input/inputNN
philips_asus 000x:0471:206C.000x: input: USB HID v1.00 Keyboard [PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS] on usb-[ .. ]/inputN
usbcore: registered new interface driver usbhid
usbhid: USB HID core driver
</pre>

### A symlink to the 'eventN'-node should exist:
<pre>
# ls -la /dev/input/{irremote,event7}
crw-r----- 1 root root 13, 71 Jan  2 10:04 event7
lrwxrwxrwx 1 root root      6 Jan  2 17:52 irremote -> event7
</pre>

### When XBMC starts, check dmesg again and look for:
<pre>
input: PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS (lircd bypass) as /devices/virtual/input/inputNN
</pre>



Original, somewhat outdated README below:
-----------------------------------------

### hid-philips-asus
This is the driver for the "PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS"
remote device with id 0471:206C.

### Configure
Edit mappings.h to assign your custom button mappings.

### Compile and install
To compile and install do:

 make
 sudo make install

This will compile and install the hid-philips-asus driver under your kernels
directory:

 /lib/modules/$(uname -r)/updates/

### Loading hid-philips-asus
Run:
 sudo modprobe hid-philips-asus

or add hid-philips-asus to etc/modules and reboot

IMPORTANT:
The module depends on usbhid but it has to be loaded *before* the usbhid module,
in order to claim the device. Otherwise usbhid claims the device and
hid-philips-asus can not act on it.

The problem is that other loaded hid modules might depend on usbhid,
so you cannot just unload it.
As a workaround there is the script 'load-module.sh' which unloads all loaded
hid modules, loads hid-philips-asus and then reloads the rest of previously
loaded hid modules.
The script has to be run as root:
 sudo sh contrib/load-module.sh

I suggest executing this script from /etc/rc.local.
You can add there the line above before the exit command.

If you use lirc then you might want to restart it after executing this script.

### Supported kernels
This driver has been tested to compile in 2.6.32
