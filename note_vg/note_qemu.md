Qemu
---

# Ubuntu 18.04

+ dependency

    ```shell
    $ sudo apt install librados2=12.2.4-0ubuntu1
    $ sudo apt-get install librbd1
    $ sudo apt-get install qemu-block-extra
    $ sudo apt-get install qemu-system-common
    $ sudo apt-get install qemu-system-arm
    ```

+ check

    ```shell
    $ qemu-system-arm -machine -cpu help
    ```

+ example

    - [freertos-plus](https://github.com/embedded2014/freertos-plus)

        ```shell
        $ cd freertos-plus
        $ make
        $ cd build
        $ qemu-system-arm -M stm32-p103 -monitor stdio -kernel main.bin -semihosting
        ```
