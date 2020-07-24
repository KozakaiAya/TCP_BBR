#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: ./install.sh <algo>"
    echo "<algo>: bbr | tsunami | nanqinlang"
    exit 1
fi

algo=$1
bbr_file=tcp_$1
bbr_src=$bbr_file.c
bbr_obj=$bbr_file.o
bbr_kernelobj=$bbr_file.ko

gcc_version=$(gcc --version | grep ^gcc | sed 's/^.* //g')
include_path="ccflags-y=-I/usr/lib/gcc/x86_64-linux-gnu/$gcc_version/include"

if [ ! -f "./$bbr_src" ]; then
    echo "$bbr_src not found! Please download from https://github.com/KozakaiAya/TCP_BBR first"
    exit 1
fi

if [ $(id -u) -ne 0 ]; then 
    echo "Cowardly refuse to continue without root permission" 
    exit 1 
fi

echo "===== Start Compilation: $bbr_file ====="

echo "obj-m:=$bbr_obj" > Makefile
echo "$include_path" >> Makefile
make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc

if [ ! -f "./$bbr_kernelobj"]; then
    echo "Build failed, please check your environment"
    exit 1
fi

echo "===== Start Installation: $bbr_file ====="

cp $bbr_kernelobj /lib/modules/$(uname -r)/kernel/drivers/
echo "$bbr_file" | sudo tee -a /etc/modules
depmod
modprobe "$bbr_file"
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=$algo" >> /etc/sysctl.conf
sysctl -p

ret=$?
if [ $ret -eq 0 ]; then
    echo "===== Installation succeeded, enjoy! ====="
    exit 0
else
    echo "Something went wrong, please check your environment"
    exit 1
fi
