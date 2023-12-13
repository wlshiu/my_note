Qemu RISC-V [[Back]](note_riscv_simulation.md#Qemu-with-RISC-V)
---


# Ubuntu of RISC-V with Qemu

## Dependency

    ```
    $ sudo apt install qemu-system-misc opensbi u-boot-qemu qemu-utils
    ````

## Ubuntu img

    ```
    https://cdimage.ubuntu.com/releases/20.04.4/release/
    ```

    ```
    $ wget https://old-releases.ubuntu.com/releases/focal/ubuntu-20.04.2-preinstalled-server-riscv64.img.xz
    ```

## Qemu

+ Run Qemu

    ```
    $ qemu-system-riscv64 \
        -machine virt -nographic -m 2048 -smp 4 \
        -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
        -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
        -device virtio-net-device,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::3333-:22 \
        -drive file=ubuntu-20.04.2-preinstalled-server-riscv64.img,format=raw,if=virtio
    ```

+ log account

    ```
    username: ubuntu
    password: ubuntu
    ```

+ Extern img
    > 進入虛擬機器, 可看到`/dev/vda1` 根目錄, 因此可按需進行擴容, 本次擴容至 20G

    - 下載虛擬機器磁碟管理工具和相關依賴

        ```
        $ sudo apt install libguestfs-tools linux-image-generic
        ```

    - Create extern img

        ```
        $ sudo truncate -r ubuntu-20.04.2-preinstalled-server-riscv64.img ubuntu-20.04.02-20g.img
        $ sudo truncate -s 20G ubuntu-20.04.02-20g.img
        $ sudo virt-resize -v -x --expand /dev/vda1 ubuntu-20.04.2-preinstalled-server-riscv64.img ubuntu-20.04.02-20g.img
        ```

    - Run Qemu

        ```
        $ qemu-system-riscv64 \
            -machine virt -nographic -m 2048 -smp 4 \
            -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
            -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
            -device virtio-net-device,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::3333-:22 \
            -drive file=ubuntu-20.04.02-20g.img,format=raw,if=virtio
        ```

+ MISC reference

    - riscv-probe
        > Simple machine mode program to probe RISC-V control and status registers

        ```
        $ git clond https://github.com/michaeljclark/riscv-probe.git
        $ make [CROSS_COMPILE=riscv64-unknown-elf-]   # [] 表示 optional
        ```

        1. run spike

            ```
            $ spike --isa=RV32IMAFDC build/bin/rv32imac/spike/probe
            $ spike --isa=RV32IMAFDC build/bin/rv32imac/spike/probe
            ```

        1. run qemu

            ```
            $ qemu-system-riscv32 -nographic -machine spike_v1.10 -kernel build/bin/rv32imac/spike/probe
            $ qemu-system-riscv64 -nographic -machine spike_v1.10 -kernel build/bin/rv64imac/spike/probe
            $ qemu-system-riscv32 -nographic -machine virt -kernel build/bin/rv32imac/virt/probe
            $ qemu-system-riscv32 -nographic -machine sifive_e -kernel build/bin/rv32imac/qemu-sifive_e/probe
            $ qemu-system-riscv32 -nographic -machine sifive_u -kernel build/bin/rv32imac/qemu-sifive_u/probe
            ```

# Reference

+ [基於qemu-riscv從0開始建構嵌入式linux系統](https://blog.csdn.net/weixin_39871788/category_11180842.html)
+ [基於RISC-V的QEMU + FreeRTOS開發環境建構](https://blog.csdn.net/qq_42357476/article/details/127315647?spm=1001.2101.3001.6650.15&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-127315647-blog-129293478.235%5Ev28%5Epc_relevant_t0_download&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-127315647-blog-129293478.235%5Ev28%5Epc_relevant_t0_download&utm_relevant_index=16)
