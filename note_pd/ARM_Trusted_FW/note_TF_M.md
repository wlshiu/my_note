Trusted_Firmware-M
---

# Definitions
> [Glossary of terms and abbreviations](https://trustedfirmware-m.readthedocs.io/en/latest/glossary.html#term-SPE)

+ PSA (Platform Security Architecture)

+ MPU (Memory Protection Unit)
    > Hardware component providing privilege control.

+ NSPE (Non Secure Processing Environment)
    > In TF-M this means non secure domain typically running an OS using services provided by TF-M.

+ SPE (Secure Processing Environment)
    > In TF-M this means the secure domain protected by TF-M.


# Conception

Architecture of Trusted Firmware-M
![Arch_TF-M](./Arch_TF-M.jpg)

## Secure Boot

Secure boot 最主要的目的, 就是防止系統使用到惡意的程式
> 在開機流程中, boot-code 會先透過密碼學(cryptography)演算法, 驗證是否為可信任的的程式,
如果驗證成功即會開始執行, 否則中止流程

![Secure_boot_of_TF-M](./Secure_boot_of_TF-M.jpg)

+ BL-1 (Bootloader 1)
    > 此階段主要是必要的硬體初始化或設定, 因此 BL1 必須是可信任且不可被竄改.
    執行完初始化後, 就會跳到 BL2 的 entry point 繼續執行 BL2

+ BL-2 (Bootloader 2)
    > BL2 負責其他所需的初始化操作, 例如啟動 MCUboot 前所需的設定或檢查, 接著就會把執行交給 MCUboot

+ MCUboot
    > MCUboot 是針對 32-bits MCU 所設計的 Secure-Bootloader, 其中包含**完整的程式驗證流程**,
    因此也是 Trusted Firmware-M Secure-Boot 流程的核心.
    >> 而 MCUboot 本身就是獨立的 open source project, 因此也能移植到其他 project

+ TF-M Core
    > + TF-M Core 會依據 memory layout, 放在指定的 Flash Address，而 MCUboot 會先去該 Address 取得 TF-M Core 的 Binary data, 並進行相關驗證確認.
    >     > 如果 Binary data 已被加密, 也會在這階段進行解密
    >
    > + 在確認完 TF-M 是正確且可信任後, 才會載入 TF-M Core

    > 要注意的是, Trusted Firmware-M 手冊中有提到, 驗證和解密所需 key, 建議放在 OTP 中,以確保不可修改

    > 此外, 由於需要在載入 TF-M Core 前, 就需要對 TF-M Binary data 進行驗證,
    因此需要 **只獨立存在 SPE 中的 crypto API, 來處理驗證與加解密**
    >> 在 BL-2 階段需設定好必要的 hardware/software

+ RTOS
    > 最後階段載入 App (with/without RTOS)
    >> 此時同樣需要驗證解密, 確認正確無誤後, 才能載入執行


## Handshake between SPE and NSPE

![Scenario_of_TF-M](./Scenario_of_TF-M.jpg)

# Practice

## Setup development environment

+ dependencies
    > + **CMake version 3.21 or later**
    > + **Python version 3.12 or later**

    ```
    $ sudo apt-get install -y git curl wget build-essential libssl-dev cmake make
    $ sudo apt install ninja-build
    $ sudo apt install python3.12 python3.12-pip python3.12-venv python3.12-dev
    $ sudo apt install gdb-multiarch

    $ cd <user-local-tf-m_dir>
    $ python3 -m venv .venv
    $ source .venv/bin/activate
    $ cd <user-local>/trusted-firmware-m/tools
    $ pip install -r requirements.txt

    # if necessary
    $ pip uninstall requirements.txt
    ```

+ download source code
    > Use `ver: TF-Mv1.8.1`
    >> involve SPE(Secure Processing Environment) and NSPE (Non Secure Processing Environment)

    ```
    $ git clone https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
    $ git checkout TF-Mv1.8.1  # use GNU Arm Embedded Toolchain 11.2-2022.02
    ```

+ build
    > create `z_build_tfm.sh`

    ```
    #!/bin/bash

    cmake -S . -B out \
        -DTFM_PLATFORM=arm/mps2/an521 \
        -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        -DTEST_NS=ON \
        -DTEST_S=ON \
        -DTFM_PSA_API=ON \
        -DBL2=OFF

    cd out
    make
    ```

    ```
    $ cd <user-local>/trusted-firmware-m/out/bin
    $ ls
        tfm_ns.axf  tfm_ns.elf  tfm_ns.map  tfm_s.bin  tfm_s.hex
        tfm_ns.bin  tfm_ns.hex  tfm_s.axf   tfm_s.elf  tfm_s.map
    ```

## Qemu

+ Create `z_qemu_server.sh`

    ```
    #!/bin/bash

    TARGET_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_s.elf"
    TARGET_NON_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_ns.bin"

    qemu-system-arm \
        -M mps2-an521 \
        -kernel ${TARGET_SECU} \
        -device loader,file=${TARGET_NON_SECU},addr=0x00100000 \
        -nographic -s -S
    ```


+ Create `z_qemu_gdb.sh` (not work..)

    ```bash
    #!/bin/bash

    TARGET_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_s.elf
    TARGET_NON_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_ns.elf

    cgdb -d gdb-multiarch ${TARGET_SECU} \
        -ex "target remote:1234" \
        -ex "add-symbol-file ${TARGET_NON_SECU}" \
        -ex "b tfm_ns_platform_init"
    ```


# Reference

+ [Trusted Firmware-M Documentation — Trusted Firmware-M Unknown documentation](https://trustedfirmware-m.readthedocs.io/en/latest/index.html)
    - [Building default configuration for an521](https://trustedfirmware-m.readthedocs.io/en/latest/building/tfm_build_instruction.html#building-default-configuration-for-an521)

+ [Understanding ARM Trusted Firmware using QEMU](https://lnxblog.github.io/2020/08/20/qemu-arm-tf.html)
+ [ARM Trusted Firmware-M (TF-M): build and run on QEMU - YouTube](https://www.youtube.com/watch?v=Tn9O44ur_xs)
+ [一文熟悉Trusted Firmware-M - 知乎](https://zhuanlan.zhihu.com/p/651683753)

+ MCUboot
    - [MCUboot | mcuboot](https://docs.mcuboot.com/)
    - [GitHub - STMicroelectronics/stm32-mw-mcuboot: MCUboot is an OS- and HW-independent secure bootloader for 32-bit MCUs aiming at defining a common infrastructure for the bootloader and the system flash layout on microcontroller systems, and at providing a secure bootloader that enables simple software upgrades. · GitHub](https://github.com/STMicroelectronics/stm32-mw-mcuboot/tree/main)
