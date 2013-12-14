#!/dev/sh
cat system.bin > /dev/xdevcfg
modprobe cryptodev
rmmod sha1_zynq
insmod sha1_zynq.ko
lsmod

