# Build Options
```Makefile
echo "obj-m:=sch_fq.o" > Makefile
make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
cp sch_fq.ko /lib/modules/$(uname -r)/kernel/drivers/
echo 'sch_fq' | sudo tee -a /etc/modules
depmod
modprobe sch_fq
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=tsunami" >> /etc/sysctl.conf
sysctl -p
```
