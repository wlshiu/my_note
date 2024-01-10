SystemC
---

SystemC 是一門建立在 C++ 之上的一個 `Standard Library`, 在行為驗證層級及暫存器傳輸層級之間, 建立更抽象的設計層級,
用以補足 S/w 與 H/w 設計之間的 gap, 並加速整體系統設計

SystemC 擁有以 RTL Level 描述 H/w 模型的能力, 因此和傳統的 RTL Simulation 比較, 用來模擬一項工作的電腦處理器資訊量, 基本上大致相同.
> 事實上 SystemC 並沒有提供能夠強化效能的技巧, 因此處理器指令的數量必須要降低. <br>
為了達到這個目的, 唯一的解決方案, 就是捨棄包含在 RTL Level 的部份資訊, 抽象的程度越高, 模擬的速度就越快

+ 早期的 Chip 設計流程為
    > + C level 功能驗證 => 檢查演算法是否可以實作
    > + RTL 設計 => 使用 RTL 來實現電路, 及在 FPGA 上做功能驗證
    > + APR => H/w layout
    > + Tape-out
    > + S/w 開發 => 撰寫驅動程式或測試整體系統

+ 在有了 SystemC 之後 Chip 設計流程為
    > + C level 功能驗證 => 檢查演算法是否可以實作
    > + 建立 SystemC 模擬平台 => 通常在 QEMU 上架構虛擬平台, 並在平台上驗證 behavior, timing, power, ...etc
    > + S/w 開發 => 撰寫驅動程式或測試整體系統
    > + RTL 設計 => 使用 RTL 來實現電路, 及在 FPGA 上做功能驗證
    > + APR => layout
    > + Tape-out

最大的差別, 在於 S/w 與 H/w 可以同時開始設計, 不只在設計時程上有差異,
更可以幫助設計人員在系統設計初期, 就能對整體系統的性能, 有更好的掌握與理解


# Practice

platform: ubuntu 20.4

+ Download source code

    ```shell
    $ wget http://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.gz
    ```

+ Build systemC library

    - cmake to build
        > + `-DCMAKE_CXX_STANDARD=11` 使用 C++11
        > + `-DDISABLE_COPYRIGHT_MESSAGE=True`  不 log systemc copyright info

        ```
        $ tar -zxf systemc-2.3.3.gz
        $ cd systemc-2.3.3
        $ mkdir build && cd build
        $ cmake .. -DCMAKE_CXX_STANDARD=11 -DCMAKE_INSTALL_PREFIX=$HOME/.systemc -DDISABLE_COPYRIGHT_MESSAGE=True
        $ ccmake .  # modify cmake configuration with tui
        $ make install
        ```

        1. ccmake

            ```
            $ sudo apt-get install cmake-curses-gui
            ```

    - autotool to build

        ```
        $ tar -zxf systemc-2.3.3.gz
        $ cd systemc-2.3.3
        $ mkdir build && cd build
        $ ../configure --perfix=$HOME/.systemc CXXFLAGS='--std=c++11'
        $ make
        ```

+ Set environment varables

    ```
    $ export SYSTEMC_HOME=$HOME/.systemc
    $ export LD_LIBRARY_PATH=$HOME/.systemc/lib:$LD_LIBRARY_PATH
    ```

+ try-run

    - hello.cpp

        ```
        $ vi hello.cpp

            #if 0

            #ifndef _HELLO_H
            #define _HELLO_H
            #include "systemc.h"

            SC_MODULE(hello)
            {
                SC_CTOR(hello)
                {
                    cout<<"Hello, SystemC!"<<endl;
                }
            };
            #endif

            //main.cpp
            int sc_main(int i, char* a[])
            {
                hello h("hello");
                return 0;
            }

            #else

            #include <systemc.h>

            SC_MODULE (hello_world) {
                SC_CTOR (hello_world) {
                    SC_THREAD(say_hello);
                }

                void say_hello() {
                    cout << "Hello World SystemC" << endl;
                }

            };

            int sc_main(int argc, char* argv[])
            {
                hello_world hello("HELLO");

                sc_start();

                return (0);
            }
            #endif
        ```
    - compile

        ```
        $ vi ./z_build_app.sh
            #!/bin/bash

            g++ ./hello.cpp -I$HOME/.systemc/include -L$HOME/.systemc/lib --std=c++11 -lsystemc -o hello
        ```

    - run app

        ```
        $ ./hello

                SystemC 2.3.3-Accellera --- Jan 10 2024 14:18:04
                Copyright (c) 1996-2018 by all Contributors,
                ALL RIGHTS RESERVED
        Hello World SystemC
        ```


# Reference
+ [學長認真: 各種搞懂SystemC](https://sianghuang.blogspot.com/2017/11/systemc.html)
+ [SystemC 學習之 Linux 安裝 SystemC(一)_systemc教學-CSDN部落格](https://blog.csdn.net/yp18792574062/article/details/133747670?spm=1001.2101.3001.6650.2&utm_medium=distribute.pc_relevant.none-task-blog-2~default~YuanLiJiHua~Position-2-133747670-blog-78672320.235%5Ev40%5Epc_relevant_anti_t3&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2~default~YuanLiJiHua~Position-2-133747670-blog-78672320.235%5Ev40%5Epc_relevant_anti_t3&utm_relevant_index=5)
+ [accellera-official/systemc: SystemC Reference Implementation](https://github.com/accellera-official/systemc/tree/master)
+ [dcblack/ModernSystemC: Example code for Modern SystemC using Modern C++](https://github.com/dcblack/ModernSystemC)
+ [AleksandarKostovic/SystemC-tutorial: Brief SystemC getting started tutorial](https://github.com/AleksandarKostovic/SystemC-tutorial/tree/master)

