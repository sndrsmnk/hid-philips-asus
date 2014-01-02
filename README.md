hid-philips-asus
================

Import of a source tree for a 'hid-philips-asus.ko'-driver that enables the
use of the "PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS" remote device
with id 0471:206C in XBMC, for example.

This source tree was shipped with the hardware on a CD, if i recall correctly.
It was imported as-is. There have been small tweaks to the Makefile so this
code compiles with kernels >=3.8.

Confirmed to work on 3.12.0-7-generic (Ubuntu Saucy) w. XBMC and lirc.
Documentation on this will be added to this repository.

Quick install guide:

<pre>
git clone https://github.com/sndrsmnk/hid-philips-asus.git

cd hid-philips-asus/src
make install

cat &gt;/etc/modprobe.d/hid-philips-asus.local &lt;&lt;EOT
# Module mceusb claims to support this device but doesnt
blacklist mceusb
# Module hid-philips-asus needs to be loaded before usbhid
softdep usbhid pre: hid-philips-asus
EOT

cat &gt;&gt;/etc/udev/rules.d/10-local.rules &lt;&lt;EOT
# Automatic symlink irremote to eventN device node.
KERNEL=="event\*",ATTRS{idVendor}=="0471",ATTRS{idProduct}=="206c",SYMLINK="input/irremote"
EOT

chmod 644 /etc/modprobe.d/hid-philips-asus.local
chmod 644 /etc/udev/rules.d/10-local.rules
</pre>

Either unload usbhid and reload it, or reboot. The device /dev/input/irremote
should now always point to the eventN for the IR-receiver.



Original, somewhat outdated README contents:

=========================

hid-philips-asus
----------------

This is the driver for the "PHILIPS MCE USB IR Receiver- Spinel plusf0r ASUS"
remote device with id 0471:206C.

Configure
------------------
Edit mappings.h to assign your custom button mappings.

Compile and install
------------------

To compile and install do:

 make
 sudo make install

This will compile and install the hid-philips-asus driver under your kernels
directory:

 /lib/modules/$(uname -r)/updates/

Loading hid-philips-asus
------------
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

Supported kernels
----------------

This driver has been tested to compile in 2.6.32
