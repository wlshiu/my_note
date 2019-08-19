Linux spidev
---

# SPI (Serial Peripheral Interface)

+ Four lines

    - SCLK:
        > Serial Clock (output from master)
    - MOSI:
        > Master Output Slave Input, or Master Out Slave In (data output from master)
    - MISO:
        > Master Input Slave Output, or Master In Slave Out (data output from slave)
    - SS or CS:
        > Slave Select or Chip Select (often active low, output from master)

+ SPI Polarity
    >　CKPOL (Clock Polarity) = CPOL = POL = Polarity = （時鐘）極性

+ SPI Phase
    > CKPHA (Clock Phase) = CPHA = PHA = Phase = （時鐘）相位

+ 用途
    > Kernel 用 `CPOL` 和 `CPHA` 的組合來表示當前SPI需要的工作模式

    - 用 `CPOL` 表示 Clock 信號的初始電位的狀態
        > + `0` 表示 Clock 信號初始狀態為低電位
        > + `1` 表示 Clock 信號的初始電位是高電位.

    - 用 `CPHA` 來表示在那個 Clock Edge 取樣,
        > + `0` 表示在 `1-st` Clock Edge 取樣數據
        > + `1` 則表示要在 `2-ed` Clock Edge 來取樣數據

    - 一個 Clock 週期內, 有兩個 edge
        > + `Leading edge` (1-st edge), 對於開始電壓是 `1`, 那麼就是 `1` -> `0` 的時候, 對於開始電壓是`0`, 那麼就是`0` -> `1` 的時候
        > + `Trailing edge` (2-ed edge), 對於開始電壓是 `1`, 那麼就是 `0` -> `1` 的時候 (即在第一次 `1` -> `0` 之後, 才可能有後面的 `0` -> `1`), 對於開始電壓是 `0`, 那麼就是 `1` -> `0` 的時候


# Tool

+ spidev_test

    - path
        1. linux-3.16/Documentation/spi/spidev_test.c
        1. linux-5.2.8/tools/spi/spidev_test.c

    - example

    ```
    $ gcc spidev_test.c -o test_spidev
    $ ./spidev_test -D /dev/spidev0.0 -s 50000000
    spi mode: 0
    bits per word: 8
    max speed: 50000000 Hz (50000 KHz)

    FF FF FF FF FF FF
    40 00 00 00 00 95
    FF FF FF FF FF FF
    FF FF FF FF FF FF
    FF FF FF FF FF FF
    DE AD BE EF BA AD
    F0 0D

    $ ./spidev_test -D /dev/spidev0.0 -s 512000 -p "123456789" -H -O
    ```

    ```
    $ ./spidev_test --help
          -D --device   device to use (default /dev/spidev1.1)
          -s --speed    max speed (Hz)
          -d --delay    delay (usec)
          -b --bpw      bits per word
          -i --input    input data from a file (e.g. \test.bin\)
          -o --output   output data to a file (e.g. \results.bin\)
          -l --loop     loopback
          -H --cpha     clock phase
          -O --cpol     clock polarity
          -L --lsb      least significant bit first
          -C --cs-high  chip select active high
          -3 --3wire    SI/SO signals shared
          -v --verbose  Verbose (show tx buffer)
          -p            Send data (e.g. \1234\\xde\\xad\)
          -N --no-cs    no chip select
          -R --ready    slave pulls low to pause
          -2 --dual     dual transfer
          -4 --quad     quad transfer
          -S --size     transfer size
          -I --iter     iterations
    ```


+ spidev_fdx

    - path
        1. linux-3.16/Documentation/spi/spidev_fdx.c
        1. linux-5.2.8/tools/spi/spidev_fdx.c

    - example

    ```
    $ gcc spidev_fdx.c -o spidev_fdx
    $ ./spidev_fdx -r 20 /dev/spidev0.0
    ```

    ```
    $ ./spidev_fdx -h
    $ ./spidev_fdx [-m length] [-r rx_length] [device-name]
        -m              duplex, default send 1 byte and receive [length] bytes (max: 32)
        -r              simplex, receive size (min: 2, max: 32)
        device-name     device to use (e.g /dev/spidev1.1)
    ```
