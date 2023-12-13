RISC-V OpenSBI [[Back]](note_riscv_simulation.md#OpenSBI-Practice)
---

SBI(Supervisor Binary Interface), 是特權態軟體和運行機器的一套二進制介面.

SBI 是在 `M-mode`下運行的特定於平台韌體, 與 bootloader 引導載入程序, 以及在 S-mode 或 HS-mode 模式下, 運行的 hypervisor 或通用作業系統之間的介面

如果要支援 Linux 等現代作業系統, RISC-V 必須提供三種工作模式:
> + Machine Mode
> + Supervisor Mode
> + User Mode

Supervisor 和 User 分別用於運行我們常見的 Linux kernel/user space.
而 Machine Mode 則用於運行 Bootloader 並裝載和執行 OS

### Firmware of OpenSBI

為了相容不同的運行需求, OpenSBI 支援三種類型的 Firmware, 分別為:
> + dynamic: 從上一級 Boot Stage 獲取下一級 Boot Stage 的入口資訊, 以 struct fw_dynamic_info 結構體通過 a2 暫存器傳遞
> + jump: 假設下一級 Boot Stage Entry 為固定地址, 直接跳轉過去運行
> + payload: 在 jump 的基礎上, 直接打包進來下一級 Boot Stage 的 Binary

下一級通常是 Bootloader 或 OS, e.g. U-Boot, Linux.

> Firmware 相關的原始碼在 OpenSBI 的 firmware/ 下


## Build Bin

+ riscv64

    ```
    exorpt PLATFORM_RISCV_XLEN=64
    export CROSS_COMPILE=<64-bits toolchain prefix>
    ```

+ riscv32
    > 建議使用 `$ source setup.env`

    ```
    # save as setup.env
    exorpt PLATFORM_RISCV_XLEN=32
    export CROSS_COMPILE=<32-bits toolchain prefix>
    ```


+ Kconfig interactive

    ```
    $ make PLATFORM=<platform_subdir> menuconfig
    $ make PLATFORM=<platform_subdir> PLATFORM_DEFCONFIG=<platform_custom_defconfig>
    ```

### Build OpenSBI

```
$ make PLATFORM=generic PLATFORM_RISCV_XLEN=32 CROSS_COMPILE=riscv-nuclei-elf-
$ make PLATFORM=generic PLATFORM_RISCV_XLEN=64 CROSS_COMPILE=riscv64-unknown-elf-
```

+ Generate map file

    ```
    # at .../opensbi-1.3.1/firmware/objects.mk
    ...
    firmware-asflags-y +=
    firmware-ldflags-y += -Wl,-Map=$(platform_build_dir)/firmware/fw_xxx.map
    ...
    ```

+ Dump disassembly

    ```
    $ riscv-nuclei-elf-objdump -S --disassemble fw_jump.elf > fw_jump.dump
    ```

### Build with u-boot

```
$ make PLATFORM=generic \
    PLATFORM_RISCV_XLEN=32 \
    CROSS_COMPILE=riscv-nuclei-elf- \
    FW_PAYLOAD_PATH=<uboot_build_directory>/u-boot.bin
```

### Build with linux kernel

```
$ make PLATFORM=generic \
    PLATFORM_RISCV_XLEN=32 \
    CROSS_COMPILE=riscv-nuclei-elf- \
    FW_PAYLOAD_PATH=<linux_build_directory>/arch/riscv/boot/Image
```

## Simulation

+ Run on Qemu

    ```
    $ qemu-system-riscv32 -M virt -m 256M -nographic \
        -bios build/platform/generic/firmware/fw_payload.bin
    ```

+ Run on Qemu and bring-up u-boot


    ```
    $ qemu-system-riscv32 -M virt -m 256M -nographic \
        -bios build/platform/generic/firmware/fw_jump.bin \
        -kernel <uboot_build_directory>/u-boot.bin
    ```

+ Run on Qemu and bring-up kernel

    ```
    $ qemu-system-riscv32 -M virt -m 256M -nographic \
        -bios build/platform/generic/firmware/fw_jump.bin \
        -kernel <linux_build_directory>/arch/riscv/boot/Image \
        -drive file=<path_to_linux_rootfs>,format=raw,id=hd0 \
        -device virtio-blk-device,drive=hd0 \
        -append "root=/dev/vda rw console=ttyS0"
    ```

## Debug environment (GDB)

+ Qemu Server

    ```
    $ qemu-system-riscv32 -M virt -m 256M -nographic \
        -bios build/platform/generic/firmware/fw_payload.bin \
        -gdb tcp::1234 \
        -S
    ```

+ Qemu clint (DUT)

    ```
    $ riscv-nuclei-elf-gdb build/platform/generic/firmware/fw_payload.elf \
        -ex 'target remote localhost:1234'
    ```

## Overview



# Reference

+ [riscv-software-src/opensbi](https://github.com/riscv-software-src/opensbi/tree/master)
    - [opensbi/qemu_virt](https://github.com/riscv-software-src/opensbi/blob/master/docs/platform/qemu_virt.md)
+ [RISC-V OpenSBI 快速上手 - 泰曉科技](https://tinylab.org/riscv-opensbi-quickstart/)

+ [opensbi入門 - LightningStar - 部落格園](https://www.cnblogs.com/harrypotterjackson/p/17558399.html)
