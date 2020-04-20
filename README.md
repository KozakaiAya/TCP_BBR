# TCP_BBR

BBR implementation and research resources.

Enhanced BBR is modified by Yankee@hostloc and nanqinglang.

This repository keeps track of [tcp_bbr.c](https://elixir.bootlin.com/linux/latest/source/net/ipv4/tcp_bbr.c) from Elixir Bootlin.

## Installation

### Automated installation

1. Download [install.sh](https://raw.githubusercontent.com/KozakaiAya/TCP_BBR/master/install.sh).
2. Download the source code of your desired congestion control algorithm w.r.t. your kernel version.
3. Put the source code in the same directory as `install.sh`.
4. Run `./install.sh <algo>` as root.

`<algo>` should be chosen from `bbr`, `tsunami`, `nanqinlang` or `bbrplus` (deprecated in v5.1+). The script assumes that the corresponding source code for `<algo>` is `tcp_<algo>.c`.

### Manual installation (deprecated)

```Bash
wget -O ./tcp_tsunami.c https://raw.githubusercontent.com/KozakaiAya/TCP_BBR/master/v5.5/tcp_bbr.c
echo "obj-m:=tcp_tsunami.o" > Makefile
make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
cp tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/drivers/
echo 'tcp_tsunami' | sudo tee -a /etc/modules
depmod
modprobe tcp_tsunami
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=tsunami" >> /etc/sysctl.conf
sysctl -p
```

**Special note for Linux Kernel 4.15 & gcc 7.3**

For some strange reasons, the compiler cannot find necessary header files. Therefore, ```echo "ccflags-y=-I/usr/lib/gcc/x86_64-linux-gnu/7/include" >> Makefile``` is needed.

## Supported Ubuntu versions

| Ubuntu |  GA  |  HWE | HWE-Edge |
|:------:|:----:|:----:|:--------:|
|  16.04 | N/A                                                                  | [4.15](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v4.15)  | [4.15](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v4.15)  |
|  18.04 | [4.15](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v4.15) | [5.3](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v5.3)    | [5.3](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v5.3)    |
|  20.04 | [5.4](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v5.4)   | [5.4](https://github.com/KozakaiAya/TCP_BBR/tree/master/code/v5.4)    | TBA   |

Ubuntu kernel version is obtained from [Ubuntu Packages](https://packages.ubuntu.com/search?suite=all&arch=arm64&searchon=names&keywords=linux-generic). Other supported version of BBR code can be found [here](https://github.com/KozakaiAya/TCP_BBR/tree/master/code).

## Research Resources

Please refer to [research/README.md](https://github.com/KozakaiAya/TCP_BBR/blob/master/research/README.md).

## Remark

Since Linux Kernel v5.1, `bbrplus` no longer needs to be updated, because most of its ideas have been merged to the mainline kernel.

## Future Plan

- [ ] Port enhanced BBR from Kernel v5.0 to higher version without merging `bbrplus`.