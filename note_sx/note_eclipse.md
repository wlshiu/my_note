# Eclipse MCU on Windows
---

[GNU MCU Eclipse](https://gnu-mcu-eclipse.github.io/)

+ Component
    - [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk9-downloads-3848520.html)
    - [Eclipse & CDT](https://github.com/gnu-mcu-eclipse/org.eclipse.epp.packages/releases/)
    - [Build Tools](https://github.com/gnu-mcu-eclipse/windows-build-tools/releases)
    - [GNU ARM Eclipse QEMU](https://github.com/gnu-mcu-eclipse/qemu/releases)
        > `v2.80` something wrong, and `v2.7.0-20161029` is ok.
    - [Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm)
    - [OpenOCD](http://gnutoolchains.com/arm-eabi/openocd/)
    - [MS font Consolas](http://www.microsoft.com/en-us/download/details.aspx?id=17879)

+ Install
    - install JDK
    - un-tar Eclipse package to your directory
        > if execute eclipse fail (error code 13), you need to check the JDK version (jdk 1.8/1.10)
    - install QEMU
    - un-tar build_tool to eclipse root directory
    - un-tar toolchain to eclipse root directory
    - un-tar openocd to eclipse root directory

+ Configure Eclipse IDE
    - set toolchain path
        > Window -> Perference -> MCU -> Global ARM Toolchains Paths

        ```
        e.g. D:\eclipse\gcc-arm-none-eabi-4_8-2014q3\bin
        ```

    - set build tool path
        > Window -> Perference -> MCU -> Global Build Tools Path

        ```
        e.g. D:\eclipse\Build_Tools\2.11-20180428-1604\bin
        ```

    - set Qemu path
        > Window -> Perference -> MCU -> Global QEMU Path

        ```
        e.g. D:\QEMU\bin
        ```

    - set OpenOCD path
        > Window -> Perference -> MCU -> Global OpenOCD Path

        ```
        e.g. D:\eclipse\OpenOCD\bin
        ```

    - download Device Packs
        > Quick bar -> Make the C/C++ Packs persepective visible
            -> reflash (link to network and download list)
            -> select Device to install (press right key and install, status at botton right)

    - text setting
        > Window -> Perference -> General -> Workspace -> text file encoding (UTF-8)

        > Window -> Perference -> General -> Workspace -> new text file line delimiter (UNIX)

        > Window -> Preferences -> General -> Editor -> Text Editor -> Insert Spaces for tabs (enable)

        > Window -> Preferences -> General -> Editor -> Text Editor -> Displayed tab width (4)

+ Syntax
    - Eclipse Color Theme
        ```
        Help -> Install New Software -> Add

            Name    : Eclipse Color Theme
            Location: http://eclipse-color-theme.github.com/update

            next to install plug-in

        Windows -> Preferences -> General -> Appearance -> Color Theme
        ```
    - code syntax
        > Windows -> Preferences -> C/C++ -> Editor -> Syntax Coloring
        >> Don't press `Apply and Close`, just press `Apply` or it will reset to default...

    - font
        ```
        General > Appearance > Colors and Fonts

            Basic > Text Font
        ```

+ Project portability
    - project icon (in Project Explor) -> press right key -> properties -> private setting for this project


# QEMU debugging

[The QEMU debugging Eclipse plug-in](https://gnu-mcu-eclipse.github.io/debug/qemu/)
[Tutorial: Create a Blinky ARM test project](https://gnu-mcu-eclipse.github.io/tutorials/blinky-arm/)


+ set QEMU folder location
    > Window -> Perference -> MCU -> Global QEMU Path

+ Associate a device to the project
    > project properties -> C/C++ Build -> Settings -> tab Devices (select a device name you want)

    >> if you link to a board, you should select the device under the `Boards` item

+ Create the debugger launch configuration
    - select the project
    - build it and ensure the executable file is available
    - expand either the Debug or the Release folder and select the executable (*.elf) you want to debug
        1. select (*.elf) and press right key
            > Debug as -> Debug Configurations (enter Debug Configurations window)
        1. or in the Eclipse menu, Run -> Debug Configurations (to open window)
    - In Debug Configurations window
        1. double click the `GDB QEMU Debugging` to New a configuration
            > a multi-tab page will be displayed
        1. At Main tab, project name (e.g. Hollo) and the application file name (e.g. Debug/hello.elf) should be already filled

        1. At Debugger tab, Board name and Device name should be filled
            > if you don't know which board to used, the `Board namd` type `?`

        1. At Common tab, select `Shared file` (optional)
        1. click the `Apply` button and then `Close` button

        1. you should get a `*.launch` file in project directory

+ Start debugging
    - open debug configuration
        1. select (*.elf) and press right key
            > Debug as -> Debug Configurations
        1. or in the Eclipse menu, Run -> Debug Configurations

    - if necessary, expand the `GDB QEMU Debugging`
    - select the newly defined configuration
    - click the bottom `Debug` button
        1. if you get the log as below, because of the `Board name` is `?`

        ```
        GNU ARM Eclipse 32-bits QEMU v2.8.0 (qemu-system-gnuarmeclipse.exe).

        Supported boards:
          Maple                LeafLab Arduino-style STM32 microcontroller board (r5)
          NUCLEO-F103RB        ST Nucleo Development Board for STM32 F1 series
          NUCLEO-F411RE        ST Nucleo Development Board for STM32 F4 series
          NetduinoGo           Netduino GoBus Development Board with STM32F4
          NetduinoPlus2        Netduino Development Board with STM32F4
          OLIMEXINO-STM32      Olimex Maple (Arduino-like) Development Board
         *STM32-E407           Olimex Development Board for STM32F407ZGT6
          STM32-H103           Olimex Header Board for STM32F103RBT6
         *STM32-P103           Olimex Prototype Board for STM32F103RBT6
         *STM32-P107           Olimex Prototype Board for STM32F107VCT6
         *STM32F4-Discovery    ST Discovery kit for STM32F407/417 lines
          STM32F4-Discovery2   ST Discovery kit for STM32F407/417 lines
          STM32F429I-Discovery ST Discovery kit for STM32F429/439 lines
          generic              Generic Cortex-M board; use -mcu to define the device
        ```

        1. It should select a board name which QEMU supported

        ```
          Board name                                        Device name
          Freescale K60-512 TWR                             Kinetis K60
          Freescale FRDM-KL25Z for KL14/15/24/25 MCUs       Kinetis KL25
          Luminary EKK LM3S9B2                              TI LM3S9Bx
          Keil MCB1114                                      NXP LPC111x
          Olimex LPC-1766STK                                NXP LPC176x
          Code Red RDB4078                                  NXP LPC40xx
          Nuvoton NUC120 Tiny board                         Nuvoton NUC120LE3AN
          NuMicro-SDK                                       Nuvoton NUC140VE3
          STM32F072B Discovery board                        STM32F0xx
         *STM32F103 Reva board                              STM32F1xx
         *Olimex STM32-P107 board                           STM32F1xx
          ST STM32F4 Discovery board                        STM32F4xx
          ST STM3240G-EVAL                                  STM32F4xx
         *Olimex STM32-E407                                 STM32F4xx
        ```

# MISC

+ open exist project
    > File -> Import -> General -> Existing Projects into Workspace

+ ST family
    - STM32F0 (CM0)
    - STM32F1 (CM3)
    - STM32F2 (CM3)
    - STM32F3 (CM4)
    - STM32F4 (CM4)

