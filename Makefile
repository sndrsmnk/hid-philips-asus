KERNEL_VERSION ?= $(shell uname -r)
MDIR := /lib/modules/$(KERNEL_VERSION)
KDIR := $(MDIR)/build
PWD := $(shell pwd)


clean-files := Module.symvers modules.order Module.markers modules.order
obj-m += hid-philips-asus.o


all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean: 
	$(MAKE) -C $(KDIR) M=$(PWD) clean
