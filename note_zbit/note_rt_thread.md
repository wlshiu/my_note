[RT-Thread](https://www.rt-thread.org/page/download.html)
---

# Environment

## Windows

+ [RT-Thread env](https://download-sh-cmcc.rt-thread.org:9151/www/aozima/env_released_1.2.0.7z)
    > 依照 `Add_Env_To_Right-click_Menu.png` 加入右鍵啟動 rt-thread 環境

+ Get rt-thread source

    ```
    $ git clone https://github.com/RT-Thread/rt-thread.git
    ```

+ Compile

    - Enter target BSP and press `right key` to launch rt-thread environment

        ```
        > cd rt-thread\bsp\stm32f10x-HAL
        ```

    - Build

        ```
        > scons
        ```

        1. the compiled source code of packages
            > `rt-thread\bsp\stm32f10x-HAL\packages`

        1. object files
            > `rt-thread\bsp\stm32f10x-HAL\build`

    - Keil-MDK project file
        > `rt-thread\bsp\stm32f10x-HAL\template.uvprojx`

+ Package Management

    - Enable packages
        > only configure the target packages

        ```
        > menuconfig
            -> RT-Thread online packages
        ```

    - Update packages
        > really handle packages to download/upgrade/delete

        ```
        > pkgs --update
        ```

        1. `pkgs` command

            ```
            $ pkgs
            usage: env.py package [-h] [--update] [--list] [--wizard] [--upgrade] [--printenv]
            optional arguments:
                -h, --help show this help message and exit
                --update update packages, install or remove the packages as you set in menuconfig
                --list list target packages
                --wizard create a package with wizard
                --upgrade update local packages list from git repo
                --printenv print environmental variables to check
            ```

+ Configure environment setting

    ```
    menuconfig -s
    ```

+ Python

    - Launch rt-thread environment

        ```
        > python get-pip.py         # install pip
        > pip install module-name   # install module with pip
        ```

# Reference

+ [RT-Thread document center](https://www.rt-thread.io/document/site/)
