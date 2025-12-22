Linux Device Driver with (Qemu)
---

# Build-up qemu environment

> on lubuntu 22.04.4 LTS

+ toolchain

    - bare-metal
        > + [gcc-arm-10.3-2021.07-x86_64-arm-none-eabi](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi.tar.xz?rev=325890dc39394ec49a112e5a661f6497&revision=325890dc-3939-4ec4-9a11-2e5a661f6497&hash=A4E88F4944E90A49F13A07F7C8F2A1D2)
        > + [gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz?rev=9d9808a2d2194b1283d6a74b40d46ada&revision=9d9808a2-d219-4b12-83d6-a74b40d46ada&hash=D0972BEEF0AB458042B15D029FAEBC59)

    - GNU/Linux
        > + [arm-linux-gnueabi](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabi/)
        > + [gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz?rev=1cb9c51b94f54940bdcccd791451cec3&revision=1cb9c51b-94f5-4940-bdcc-cd791451cec3&hash=448E26250A9F882931F13D985ADA554B)
        > + `$ sudo apt install gcc-arm-linux-gnueabihf`


## busybox

+ Busybox use static lib

    ```
    Settings  --->
        --- Build Options
        [*] Build static binary (no shared libs)

    ```

+ Build busybox

    ```
    $ vi ./z_busybox_build.sh

        #!/bin/bash

        set -e

        out=setting.env

        # echo "export ARCH=arm64" > ${out}
        # echo "export CROSS_COMPILE=aarch64-none-linux-gnu-" >> ${out}
        # echo "export SRCARCH=arm64" >> ${out}

        echo "export ARCH=arm" > ${out}
        echo "export CROSS_COMPILE=arm-linux-gnueabi-" >> ${out}
        echo "export SRCARCH=arm" >> ${out}

        source ${out}
        make menuconfig
        make

    $ chmod +x ./z_busybox_build.sh
    ```

+ Create directory architecture of busybox of rootfs

    ```
    # default prefix: ./_install
    $ make install
    ```

### Create root file-system (rootfs)

+ Creat the fully directory architecture of rootfs

    ```
    $ cd <busybox_dir>/_install
    $ mkdir -p dev etc home lib mnt proc root sys tmp var
    ```

    - `/bin` : 系統管理員和使用者皆可使用的指令
    - `/sbin`: 系統管理員使用的系統指令
    - `/dev` : 儲存特殊檔案或裝置檔案; 裝置兩種類型: Character-device, Block-device
    - `/etc` : 系統設定檔
    - `/home`: 普通使用者目錄
    - `/root`: root使用者目錄
    - `/lib` : 為系統啟動或根檔案上的應用程式(bin, sbin, etc.)提供共用程式庫, 以及為核心提供核心模組
    - `/mnt` : 暫時掛載點
    - `/tmp` : 暫存檔儲存目錄
    - `/usr` : usr hierarchy, 全域共享的唯讀資料路徑
    - `/var` : 儲存常發生變化的資料目錄: cache, log, etc.
    - `/proc`: 基於記憶體的虛擬檔案系統, 用於為核心及進程儲存其相關信息
    - `/sys` : sysfs虛擬檔案系統提供了一種比proc更為理想的存取核心資料的途徑: 其主要作用在於, 為管理linux設備, 提供一種統一模型的接口


## linux kernel

+ Configure kernel

    ```
    $ make menuconfig
        System Type -->
            [ ] Enable the L2x0 outer cache controller
            ps. Disable this option (or QEMU works fail)
        Kernel Features -->
            [*] Use the ARM EABI to compile the kernel
            ps. Enable this option

        ...

        kernel hacking—>
           Compile-time checks and compiler options ->
             [*] compile the kernel with debug info
             ps. Enable the debug info of kernel
    ```

+ Build kernel

    ```
    $ vi ./z_build_kernel.sh
        #!/bin/bash -

        set -e

        out=setting.env

        # echo "export ARCH=arm64" > ${out}
        # echo "export CROSS_COMPILE=aarch64-none-elf-" >> ${out}
        # echo "export SRCARCH=arm64" >> ${out}

        echo "export ARCH=arm" > ${out}
        echo "export CROSS_COMPILE=arm-none-eabi-" >> ${out}
        echo "export SRCARCH=arm" >> ${out}

        source ${out}
        make vexpress_defconfig
        make menuconfig
        make

    $ sudo chmod +x ./z_build_kernel.sh
    ```

+ Run kernel with Qemu
    > level Qemu, `Ctrl + a` then `x`

    ```
    $ vi ./z_kernel_qemu.sh

        #!/bin/bash

        sudo qemu-system-arm \
            -M vexpress-a9 \
            -m 128M \
            -kernel arch/arm/boot/zImage \
            -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
            -nographic \
            -append "console=ttyAMA0"

    $ chmod +x ./z_kernel_qemu.sh
    ```



# Device Driver

