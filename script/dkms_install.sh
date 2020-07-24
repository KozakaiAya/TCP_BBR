#!/bin/sh

echo "Please refer to https://github.com/KozakaiAya/TCP_BBR/tree/master/code for available BBR variants"

if [ $(id -u) -ne 0 ]; then 
    echo "Cowardly refuse to continue without root permission" 
    exit 1 
fi

read -p "Enter desired kernel version (4.15, 5.4, etc.): " kernel_ver
read -p "Enter BBR variant (bbr, tsunami, tsunamio, etc.): " algo

prefix=bbr
mkdir -p $prefix
cd $prefix

bbr_file=tcp_$algo
bbr_src=$bbr_file.c
bbr_obj=$bbr_file.o

mkdir -p src
cd src
wget -O ./$bbr_src https://raw.githubusercontent.com/KozakaiAya/TCP_BBR/master/code/v$kernel_ver/$bbr_src

if [ ! $? -eq 0 ]; then
    echo "Download Error"
    cd ../..
    rm -rf $prefix
    exit 1
fi

echo "===== Succussfully downloaded $bbr_src ====="

# Create Makefile
cat > ./Makefile << EOF
obj-m:=$bbr_obj
default:
    make -C /lib/modules/\$(shell uname -r)/build M=\$(PWD)/src modules
clean:
    -rm modules.order
    -rm Module.symvers
    -rm .[!.]* ..?*
    -rm $bbr_file.mod
    -rm $bbr_file.mod.c
    -rm *.o
    -rm *.cmd
EOF

# Create dkms.conf
cd ..
cat > ./dkms.conf << EOF
MAKE="'make' -C src/"
CLEAN="make -C src/ clean"
BUILT_MODULE_NAME=$bbr_file
BUILT_MODULE_LOCATION=src/
DEST_MODULE_LOCATION=/updates/net/ipv4
PACKAGE_NAME=$algo
PACKAGE_VERSION=$kernel_ver
REMAKE_INITRD=yes
EOF

# Start dkms install
echo "===== Start installation ====="

cp -R ./$prefix /usr/src/$algo-$kernel_ver

dkms add -m $algo -v $kernel_ver
if [ ! $? -eq 0 ]; then
    echo "DKMS add failed"
    dkms remove -m $algo/$kernel_ver --all
    exit 1
fi

dkms build -m $algo -v $kernel_ver
if [ ! $? -eq 0 ]; then
    echo "DKMS build failed"
    dkms remove -m $algo/$kernel_ver --all
    exit 1
fi

dkms install -m $algo -v $kernel_ver
if [ ! $? -eq 0 ]; then
    echo "DKMS install failed"
    dkms remove -m $algo/$kernel_ver --all
    exit 1
fi

# Test loading module
modprobe $bbr_file

if [ ! $? -eq 0 ]; then
    echo "modprobe failed, please check your environment"
    echo "Please use \"dkms remove -m $algo/$kernel_ver --all\" to remove the dkms module"
    exit 1
fi

sysctl -w net.core.default_qdisc=fq

if [ ! $? -eq 0 ]; then
    echo "sysctl test failed, please check your environment"
    echo "Please use \"dkms remove -m $algo/$kernel_ver --all\" to remove the dkms module"
    exit 1
fi

sysctl -w net.ipv4.tcp_congestion_control=$algo

if [ ! $? -eq 0 ]; then
    echo "sysctl test failed, please check your environment"
    echo "Please use \"dkms remove -m $algo/$kernel_ver --all\" to remove the dkms module"
    exit 1
fi

# Auto-load kernel module at system startup

echo $bbr_file | sudo tee -a /etc/modules
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = $algo" >> /etc/sysctl.conf
sysctl -p

if [ ! $? -eq 0 ]; then
    echo "sysctl failed, please check your environment"
    echo "Please use \"dkms remove -m $algo/$kernel_ver --all\" to remove the dkms module"
    exit 1
fi

echo "===== Installation succeeded, enjoy! ====="
