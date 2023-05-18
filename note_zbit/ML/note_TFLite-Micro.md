TFLite-Micro [[Back](note_TensorFlow.md#TFLite-Micro)]
---

Google official: [TensorFlow Lite for Microcontrollers](https://tensorflow.google.cn/lite/microcontrollers/overview?hl=zh-cn) <br>
github: [tflite-micro](https://github.com/tensorflow/tflite-micro)

# Setup Environment

+ dependency

    ```bash
    $ sudo apt install libjpeg-dev zlib1g-dev
    ```

+ Python lib

    ```bash
    $ sudo pip install pillow
    $ sudo pip install Wave

    # necessary bits for create_size_log scripts
    $ sudo pip install pandas
    $ sudo pip install matplotlib
    $ sudo pip install six
    ```


+ [參考程式碼](https://drive.google.com/open?id=1cawEQAkqquK_SO4crReDYqf_v7yAwOY8&hl=zh-cn)
    > 這些 exampels 是 platform-less, 可在 PC 上模擬演算法

    ```
    $ cd gcc/micro_speech
    $ make
    ```

# Architecture of source code of TFLite-Micro


+ Variables of Makefile

    - `MAKEFILE_DIR`
        > tflite-micro/tensorflow/lite/micro/tools/make

    - `third_party_downloads.inc`
        > 紀錄 dependency libs 下載 URL

    - `Downloads directory`
        > tflite-micro/tensorflow/lite/micro/tools/make/downloads


+ [Benchmark](https://github.com/tensorflow/tflite-micro/tree/main/tensorflow/lite/micro/benchmarks)
    > only support
    > + Keyword Benchmark (keyword detection)
    > + Person Detection Benchmark (手勢)

    ```
    $ make -f tensorflow/lite/micro/tools/make/Makefile run_keyword_benchmark
    ```


# Simulation

TensorFlow Lite MCU 團隊面臨著以下挑戰
> 如何避免 reset board, re-burn img to board, 就可以在各種 board 上重複且可靠地測試各種演示, 模型及場景 ?


## [Software Emulation with QEMU](https://github.com/tensorflow/tflite-micro/blob/main/tensorflow/lite/micro/docs/qemu.md)

+ Compile
    > select project with folder name of `tflite-micro/tensorflow/lite/micro/examples`

    ```
    # build stm32f103 bluepill
    $ make -f tensorflow/lite/micro/tools/make/Makefile TARGET=bluepill hello_world
    ```

- Execute Qemu

    ```
    # stm32f103 BluePill
    $ qemu-system-gnuarmeclipse --verbose --verbose \
        --board BluePill \
        -d unimp,guest_errors \
        --nographic \
        ---kernel gen/bluepill_x86_64_default/bin/hello_world\
        --semihosting-config enable=on,target=native
    ```

+ test Qemu case

    ```
    #
    # test_cortex_m_qemu.sh arguments:
    #   $1: TENSORFLOW_ROOT
    #       Path to root of the tflite-micro (TFLM) tree.
    #   $2: EXTERNAL_DIR (optional)
    #       Path to the external directory that contains external code
    #       ps. 目前似乎沒作用
    #
    $ tflite-micro/tensorflow/lite/micro/tools/ci_build/test_cortex_m_qemu.sh <tflite-micro_root_path>
    ```

## [Software Emulation with Renode](https://github.com/tensorflow/tflite-micro/blob/main/tensorflow/lite/micro/docs/renode.md)

[Renode](https://renode.io/) 由 Antmicro 公司打造的 `a virtual development tool for embedded systems`,
希望能夠將 Hardware-less 工作流, 持續整合於 embedded system 和 IoT system
> [Renode - github](https://github.com/renode/renode)

借助 Renode, 可以確實地模擬整個系統和動態環境, 包括向模擬感測器提供建模示例資料, 隨後 user 自訂軟體和演算法, 將讀取並處理這些資料.
對於開發者來說, 如果要使用 TensorFlow Lite, 在 Embedded Device 和 IoT Device 上試驗, 及建構由 ML 提供支援的應用,
Renode 將是一個理想平台, 因為該 framework, 能夠快速運行未經修改的軟體, 且無需訪問 Hardware.

+ Renode 的工作原理
    > Renode 會模擬 H/w (包括 RISC-V CPU 以及 I/O 和感測器), 這樣 img 認為它在實際的 board 運行。
    >> 這是通過 Renode 的 machine code 轉換和全面的 SoC 支援而實現的

    - 首先 Renode 將 App 的 machine code 轉換為本地 Host machine code

    - 接下來每當 App 嘗試 read/write 任何 peripheral 時, 該呼叫都會被攔截, 並重新導向到對應的模型
        > Renode 模型通常(但不限於)用 `C#` 或 `Python` 編寫, 實現 register interface, 並與實際 H/w 在行為上保持一致

        1. 由於這些模型是抽象的, 可以通過 Renode 的 CLI interfce 或使用指令碼檔案(*.resc), 以程式設計方式與它們進行互動

+ Portable install

    ```
    $ tar -zxf renode-1.13.3.linux-portable.tar.gz
    $ vi ~/.bashrc
        export PATH=$HOME/renode-1.13.3.linux-portable:$PATH
    ```

+ Compile
    > select project with folder name of `tflite-micro/tensorflow/lite/micro/examples`

    ```
    # build stm32f103 bluepill
    $ make -f tensorflow/lite/micro/tools/make/Makefile TARGET=bluepill hello_world

    # build risc-v sifive
    $ make -f tensorflow/lite/micro/tools/make/Makefile TARGET=riscv32_mcu hello_world
    ```

+ Execute renode

    - Start simulator of renode

        ```
        $ renode
        PuTTY X11 proxy: unable to connect to forwarded X server: Network error: Connection refused
        14:21:37.0425 [WARNING] Couldn't start UI - falling back to console mode
        14:21:37.4129 [INFO] Loaded monitor commands from: /home/wl.hsu/Renode/renode_1.13.3_portable/scripts/monitor.py
        Renode, version 1.13.3.19119 (a72a1fa1-202302201037)

        (monitor)
        (monitor) include @tensorflow/lite/micro/testing/bluepill_nontest.resc
        14:23:17.8708 [INFO] Including script: /home/data_1/working/ML/tflite-micro/tensorflow/lite/micro/testing/bluepill_nontest.resc
        14:23:17.8806 [INFO] System bus created.
        14:23:18.6780 [INFO] sysbus: Loaded SVD: /tmp/renode-17809/08499fd3-c627-4b2c-ada8-615bc83ba8ea.tmp. Name: STM32F103. Description: STM32F103.
        (machine-0)
        (machine-0) sysbus LoadELF @gen/bluepill_x86_64_default/bin/kernel_add_test
        14:27:01.6175 [INFO] sysbus: Loading segment of 36620 bytes length at 0x8000000.
        14:27:01.6296 [INFO] sysbus: Loading segment of 10460 bytes length at 0x8008F0C.
        14:27:01.6298 [INFO] sysbus: Loading segment of 516 bytes length at 0x8008FC0.
        (machine-0)
        (machine-0) machine StartGdbServer 3333  <------ enable GDB server (port: 3333) for debug
        14:28:23.8435 [INFO] machine-0: GDB server with all CPUs started on port :3333
        (machine-0) start
        ```

        ```
        # 不斷行命令
        (monitor) Clear; include @tensorflow/lite/micro/testing/bluepill_nontest.resc; sysbus LoadELF @gen/bluepill_x86_64_default/bin/kernel_add_test; start
        ```

        1. GDB client connect

            ```
            $  arm-none-eabi-gdb
            (gdb) target remote localhost:3333
            ```

    - `*.resc` is the setup script of renode
        > `tflite-micro/tensorflow/lite/micro/testing/*.resc`

# Reference

+ [怎麼將tflite部署在Android上_無需硬體, 使用 Renode 在微控製器上運行和測試 TF Lite...](https://blog.csdn.net/weixin_39632982/article/details/112523334)