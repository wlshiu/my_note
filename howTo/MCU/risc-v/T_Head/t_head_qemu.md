XuanTie Qemu
---

[Qemu for Xuantie RISC-V CPU](https://github.com/XUANTIE-RV/qemu)

# Ubuntu 22.04

## Dependency

```
$ sudo apt install -y python3-venv ninja-build iasl
$ sudo apt install -y libsdl2-dev
```

```
$ sudo apt install python3-pip
$ sudo pip install sphinx
```

## Building

```
$ mkdir build
$ cd build

# configure
$ ../configure --target-list=riscv32-softmmu,riscv32-linux-user --prefix=$HOME/qemu

$ make
```

# Trace source


