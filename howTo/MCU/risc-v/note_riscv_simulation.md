RISC-V Simulation [[Back](note_riscv_quick_start.md)]
---

# 工具介紹

## Toolchain

[riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain)

+ `riscv64-­unknown-­elf-gcc`是使用newlib, 主要用於靜態編譯的獨立的程序或者單機嵌入式程序, RTOS 等等

+ `riscv64-unknown-­linux-­gnu-­gcc`使用的glibc, 可以編譯動態連結程序, 例如 Linux 等等

如果編譯選項加上`-nostartfiles -nostdlib -nostdinc`, 則兩個編譯版本一致

## spike (RISC-V simulator)

[spike](https://github.com/riscv-software-src/riscv-isa-sim) 是一個開放原始碼的 RISC-V 的指令模擬器, 實現了一個和多個 RISC-V harts 的功能,
提供了豐富的系統模擬, 在RISC-V架構指令集擴展層面有著非常好的實現.
> 其名稱來自於 Golden Spike, 是第一條橫貫美國大陸的鐵路

## [Qemu with RISC-V](note_riscv_qemu.md)

+ Dependency

    ```bash
    $ sudo apt-get install -y git build-essential pkg-config zlib1g-dev libglib2.0-0 libglib2.0-dev \
      libsdl1.2-dev libpixman-1-dev libfdt-dev autoconf automake libtool librbd-dev libaio-dev flex bison make
    ```


+ Build Qemu with riscv32

    ```bash
    $git clone git@github.com:qemu/qemu.git
    $ cd qemu
    $ git checkout v6.0.0
    $ mkdir build
    $ cd build
    $ ../configure --prefix=/home/my/riscv/qemu --target-list=riscv32-softmmu,riscv64-softmmu \
        --enable-debug-tcg --enable-debug --enable-debug-info
    $ make -j8
    $ make install
    ```

    - export to environment

        ```
        export PATH=/home/my/riscv/qemu/bin/:$PATH
        ```

+ Run Qemu

    ```bash
    $ qemu-system-riscv64 -nographic \
        -machine virt -kernel linux/arch/riscv/boot/Image \
        -append "root=/dev/vda rw console=ttyS0" \
        -drive file=rootfs/root.bin,format=raw,id=hd0 \
        -device virtio-blk-device,drive=hd0
    ```

    - Install Busybox in kernel

        ```
        > /bin/busybox --install -s
        ```

## RISC-V Porxy Kernel

RISC-V Proxy Kernel and Boot Loader, 簡稱 [RISCV-PK](https://github.com/riscv/riscv-pk),
是一個輕量級的應用程式的可執行環境, 可以載入靜態的 RISCV ELF 的可執行檔案.
> 主要兩個功能, 代理和引導啟動, 可以作為引導啟動 RISC-V 的 Linux 的環境, 其性質類似 u-boot

## OpenSBI

[OpenSBI](https://github.com/riscv-software-src/opensbi.git) 本身就是一個 bootloade,
因此可以不使用 uboot 引導 linux kernel, 通過 opensbi 的 jump fw, 可以直接跳轉到 kernel 啟動

opensbi 生成的 F/w 有三種類型:
> + fw_dynamic: 帶有動態資訊的韌體
> + fw_jump: 指定下一級的 boot 地址跳轉
>> OpenSBI 運行後, 可以直接跳轉到 kernel 運行
> + fw_payload: 包含下一級 boot 的二進制內容, 通常是 uboot/linux

+ OpenSBI 直接跳 u-boot

    ```bash
    $ qemu-system-riscv64 \
        -machine virt -nographic -m 2048 -smp 4 \
        -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
        -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
        -device virtio-net-device,netdev=eth0 -netdev user,id=eth0 \
        -drive file=ubuntu-20.04.2-preinstalled-server-riscv64.img,format=raw,if=virtio
    ```

+ OpenSBI 直接跳 kernel

    ```shell
    #!/bin/bash
    # start-qemu.sh

    qemu-system-riscv64 -M virt \
        -bios fw_jump.elf \
        -kernel home/my/linux/Image \
        -append "rootwait root=/dev/vda ro" \
        -drive file=rootfs.ext2,format=raw,id=hd0 \
        -device virtio-blk-device,drive=hd0 \
        -netdev user,id=net0 -device virtio-net-device,netdev=net0 -nographic
    ```


運行`start-qemu.sh`啟動 RISC-V Linux

### [OpenSBI Practice](note_riscv_opensbi.md)

## buildroot

buildroot 已經可以幫我們搭建一套完整環境, 包括 toolchain, opensbi, linux, file-syztem, qemu 等等

```
$ cd buildroot-2022.02.6
$ make qemu_riscv64_virt_defconfig
$ make -j
```




# Reference

+ [想要嘗試riscv開發, 如何搭建qemu環境？](https://www.zhihu.com/question/421757389/answer/2937412514)
+ [基於qemu-riscv從0開始建構嵌入式linux系統_Quard_D的部落格](https://blog.csdn.net/weixin_39871788/category_11180842.html)
    - [基於qemu-riscv從0開始建構嵌入式linux系統ch2. 新增qemu模擬板——Quard-Star板](https://quard.blog.csdn.net/article/details/118469138?ydreferer=aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl8zOTg3MTc4OC9jYXRlZ29yeV8xMTE4MDg0Mi5odG1s)

