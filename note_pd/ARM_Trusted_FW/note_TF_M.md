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


## 業界常見的啟動流程

### 單核心

```
Power_On -> BL1 (ROM if exsit)
         -> BL2 (MCUboot 驗證 tfm_s/tfm_ns)
         -> tfm_s (初始化安全環境)
         -> tfm_ns (運行應用程序)
```

+ BL1 (ROM) 階段
    > Vendor 對 SoC 設計

+ BL2 (MCUboot) 階段
    > 檢查 Secure (tfm_s) 與 Non-Secure (tfm_ns) ImgBin 的簽章,
    如果驗證通過, BL2 會準備好跳轉環境, 並將控制權移交給 tfm_s->entry

+ tfm_s (SPE) 階段
    - System-Core 預設進入 `Secure state`
    - 配置 TrustZone 的安全邊界(e.g. SAU, MPC, PPC, ...etc.)
    - 啟動 Secure Partition Manager (SPM)
        > 負責管理安全分區(e.g. Crypto, Storage, Attestation, ...etc)

    - 一切安全服務就緒後, TF-M 會執行狀態切換指令(e.g. `BXNS`), 跳轉至 tfm_ns->entry

+ tfm_ns (NSPE Application) 階段
    > 一般 User Application

    - 當需要安全功能(e.g. 存取金鑰或加密)時, 透過 `PSA API` 發起請求, 經由 IPC 機制切換到 SPE 處理

### 多核心

區分 `Secure Core + Non-Secure Core`
> Secure Core 需要負責 wake-up Non-secure Core

```
Power_On -> BL1 (ROM if exsit)
         -> BL2 (MCUboot of Secure Core)
         -> tfm_s (Secure Core, 初始化安全環境)
            -> initialize Mailbox/IPC of SPE side
            -> Release Reset of Non-secure Core (啟動 Non-secure Core)
         > tfm_ns (Non-secure Core)
            -> initialize Mailbox/IPC of NSPE side
```
+ BL1 (ROM) 階段
    > Vendor 對 SoC 設計

+ Secure Core: BL2 (MCUboot)
    > 通常一上電只有 Secure Core 會先從 `Reset_Handler` 執行

    - BL2 運行於 Secure Core, 負責驗證位於 Flash 中的 tfm_s (Secure) 與 tfm_ns (Non-secure) 的 ImgBin
        > 基於成本考量, 會利用 MPU (Memory Protection Unit) 來限制 Non-secure Core 的 Memory (Flash/SRAM) 存取區域
        >> 有些設計會分開 tfm_s/tfm_ns 的實體 Flash

    - 如果驗證通過, BL2 會準備好跳轉環境, 並將控制權移交給 tfm_s->entry

+ Secure Core: TF-M SPE (tfm_s)
    - 配置 TrustZone 的安全邊界(e.g. SAU, MPC, PPC, ...etc.)
    - 啟動 Secure Partition Manager (SPM)
        > 負責管理安全分區(e.g. Crypto, Storage, Attestation, ...etc)
    - 初始化 Mailbox/IPC 溝通機制 (on Secure Core Side)
    - 一切就緒後, Secure Core 的tfm_s 會發出硬體指令(e.g. 設定系統控制暫存器, 發送中斷, ...),
    解除 Non-secure Core 的 Reset 狀態 (喚醒 Non-secure Core)

+ Non-secure Core: Application (tfm_ns)

    - Non-secure Core 被喚醒後, 直接從 tfm_ns 的起始位址執行
    - 初始化 Mailbox/IPC 溝通機制 (on Non-Secure Core Side)
    - 當需要安全功能時, 會透過 Mailbox/IPC, 將請求傳送給 Secure Core 的 tfm_s 處理


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
    > `xxx_signed.bin` 表示含有 img header info (for verification)

    - create `z_build_tfm.sh`

        1. without BL2

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
                tfm_ns.axf  tfm_ns.bin  tfm_ns.elf  tfm_ns.hex  tfm_ns.map
                tfm_s.axf  tfm_s.bin  tfm_s.elf  tfm_s.hex  tfm_s.map

            ```

        1. with BL2

            ```
            #!/bin/bash

            cmake -S . -B out \
                -DTFM_PLATFORM=arm/mps2/an521 \
                -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake \
                -DCMAKE_BUILD_TYPE=Debug \
                -DTEST_NS=ON \
                -DTEST_S=ON \
                -DTFM_PSA_API=ON \
                -DBL2_HEADER_SIZE=0x020 \
                -DBL2=ON

            cd out
            make
            ```

            ```
            $ cd <user-local>/trusted-firmware-m/out/bin
            $ ls
                bl2.axf  bl2.elf  bl2.map     tfm_ns.bin  tfm_ns.hex  tfm_ns_signed.bin  tfm_s.bin  tfm_s.hex  tfm_s_ns_signed.bin
                bl2.bin  bl2.hex  tfm_ns.axf  tfm_ns.elf  tfm_ns.map  tfm_s.axf          tfm_s.elf  tfm_s.map  tfm_s_signed.bin

            # 'xxx_signed' 表示含有 img healder info
            # tfm_s_ns_signed.bin = bl2.bin + tfm_s_signed.bin + tfm_ns_signed.bin
            ```


## Qemu

+ `MPS2-AN521` board

    - `MPS2-AN521` Flash 的 Secure Mapping Start Address 通常是 0x1000_0000
        > ref: `trusted-firmware-m/platform/ext/target/arm/mps2/an521/partition/flash_layout.h`


+ Create `z_qemu_server.sh`

    - without BL2

        ```
        #!/bin/bash

        TARGET_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_s.elf"
        TARGET_NON_SECU_BIN="<user-local>/trusted-firmware-m/out/bin/tfm_ns.bin"
        TARGET_BL2_BIN="<user-local>/trusted-firmware-m/out/bin/bl2.bin"
        TARGET_FULL_BIN="<user-local>/trusted-firmware-m/out/bin/tfm_s_ns_signed.bin"

        # only tfm_s and tfm_ns
        qemu-system-arm \
            -M mps2-an521 \
            -kernel ${TARGET_SECU} \
            -device loader,file=${TARGET_NON_SECU_BIN},addr=0x00100000 \
            -nographic -s -S

        ```

    - with BL2 (?)

        ```
        #!/bin/bash

        TARGET_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_s.elf"
        TARGET_BL2="<user-local>/trusted-firmware-m/out/bin/bl2.elf"

        TARGET_SECU_BIN="<user-local>/trusted-firmware-m/out/bin/tfm_s_signed.bin"       # bin_base: 0x10080020
        TARGET_NON_SECU_BIN="<user-local>/trusted-firmware-m/out/bin/tfm_ns_signed.bin"  # bin_base: 0x00100020
        TARGET_BL2_BIN="<user-local>/trusted-firmware-m/out/bin/bl2.bin"                 # bin_base: 0x10000000
        TARGET_FULL_BIN="<user-local>/trusted-firmware-m/out/bin/tfm_s_ns_signed.bin"

        # only BL2 ok
        qemu-system-arm \
            -M mps2-an521 \
            -kernel ${TARGET_BL2} \
            -nographic -s -S

        # BL2 + tfm_s ok
        qemu-system-arm \
            -M mps2-an521 \
            -kernel ${TARGET_BL2} \
            -device loader,file=${TARGET_FULL_BIN},addr=0x10080000 \
            -nographic -s -S

        # full load (? why does tfm_ns NOT work ? )
        qemu-system-arm \
            -M mps2-an521 \
            -device loader,file=${TARGET_BL2_BIN},addr=0x10000000 \
            -device loader,file=${TARGET_SECU_BIN},addr=0x10080000 \
            -device loader,file=${TARGET_NON_SECU_BIN},addr=0x00100000 \
            -nographic -s -S
        ```


+ Create `z_qemu_gdb.sh`

    - without BL2

        ```bash
        #!/bin/bash

        TARGET_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_s.elf
        TARGET_NON_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_ns.elf
        TARGET_BL2=<user-local>/trusted-firmware-m/out/bin/bl2.elf

        cgdb -d gdb-multiarch ${TARGET_SECU} \
            -ex "target remote:1234" \
            -ex "add-symbol-file ${TARGET_NON_SECU}" \
            -ex "layou asm" \
            -ex "winheight cmd +15" \
            -ex "b tfm_ns_platform_init"

        # arm-none-eabi-gdb -tui ${TARGET_SECU} \
        #     -ex "target remote:1234" \
        #     -ex "add-symbol-file ${TARGET_NON_SECU}" \
        #     -ex "b tfm_ns_platform_init"

        ```


    - with BL2 (?)

        ```bash
        #!/bin/bash

        TARGET_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_s.elf
        TARGET_NON_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_ns.elf
        TARGET_BL2=<user-local>/trusted-firmware-m/out/bin/bl2.elf

        #
        # + only bl2 case: ok
        # + full symbols : ?
        #
        cgdb -d gdb-multiarch ${TARGET_BL2} \
            -ex "target remote:1234" \
            -ex "add-symbol-file ${TARGET_NON_SECU}" \
            -ex "add-symbol-file ${TARGET_SECU}" \
            -ex "b main"
            -ex "b tfm_ns_platform_init"

        # arm-none-eabi-gdb -tui ${TARGET_SECU} \
        #     -ex "target remote:1234" \
        #     -ex "add-symbol-file ${TARGET_NON_SECU}" \
        #     -ex "b main"
        #     -ex "b tfm_ns_platform_init"
        ```


## Source code

+ common codes (system-core layer)

    - boot from `Reset_Handler`

        ```c
        // at trusted-firmware-m/platform/ext/target/arm/mps2/an521/cmsis_core/startup_an521.c: Reset_Handler
        void Reset_Handler(void)
        {
        #if defined (__ARM_FEATURE_CMSE) && (__ARM_FEATURE_CMSE == 3U)
            __disable_irq();
        #endif
            __set_PSP((uint32_t)(&__INITIAL_SP));

            __set_MSPLIM((uint32_t)(&__STACK_LIMIT));
            __set_PSPLIM((uint32_t)(&__STACK_LIMIT));

        #if defined (__ARM_FEATURE_CMSE) && (__ARM_FEATURE_CMSE == 3U)
            __TZ_set_STACKSEAL_S((uint32_t *)(&__STACK_SEAL));
        #endif

            SystemInit();                             /* CMSIS System Initialization */
            __PROGRAM_START();                        /* Enter PreMain (C library entry point) */
        }
        ```

### BL2 (MCUboot)

```
trusted-firmware-m/bl2/ext/mcuboot/bl2_main.c: main()
```

### TF-M SPE

```
trusted-firmware-m/secure_fw/spm/cmsis_psa/main.c: main()
```

### TF-M NSPE


# Reference

+ [Trusted Firmware-M Documentation — Trusted Firmware-M Unknown documentation](https://trustedfirmware-m.readthedocs.io/en/latest/index.html)
    - [Building default configuration for an521](https://trustedfirmware-m.readthedocs.io/en/latest/building/tfm_build_instruction.html#building-default-configuration-for-an521)

+ [Understanding ARM Trusted Firmware using QEMU](https://lnxblog.github.io/2020/08/20/qemu-arm-tf.html)
+ [ARM Trusted Firmware-M (TF-M): build and run on QEMU - YouTube](https://www.youtube.com/watch?v=Tn9O44ur_xs)
+ [一文熟悉Trusted Firmware-M - 知乎](https://zhuanlan.zhihu.com/p/651683753)

+ MCUboot
    - [MCUboot | mcuboot](https://docs.mcuboot.com/)
    - [GitHub - STMicroelectronics/stm32-mw-mcuboot: MCUboot is an OS- and HW-independent secure bootloader for 32-bit MCUs aiming at defining a common infrastructure for the bootloader and the system flash layout on microcontroller systems, and at providing a secure bootloader that enables simple software upgrades. · GitHub](https://github.com/STMicroelectronics/stm32-mw-mcuboot/tree/main)
