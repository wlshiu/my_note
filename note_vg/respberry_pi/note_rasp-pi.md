rasp-pi
---

+ configure

    ```shell
    # enter text ui
    $ sudo raspi-config
    ```

+ wifi setting

    ```shell
    # check wifi interface
    $ ifconfig | grep wlan*
    wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500

    # scan wifi AP
    $ sudo iwlist wlan0 scan | grep ESSID
                    ESSID:"18-4B"
                    ESSID:"20-5A"

    # add AP info for linking
    $ sudo vi /etc/wpa_supplicant/wpa_supplicant.conf

    network={
        ssid="18-4B"
        psk="your_password"
    }

    $ sudo reboot
    ```

    - fix wifi UP

        ```shell
        # add setting, stuffix commant should delete
        $ sudo vim /etc/network/interfaces
        ...
            source-directory /etc/network/interfaces.d

            auto lo
            iface lo inet loopback
            iface eth0 inet dhcp

            allow-hotplug wlan0
            auto wlan0
            iface wlan0 inet static
            address 192.168.0.12    # IP your want
            gateway 192.168.0.1
            netmask 255.255.255.0
            network 192.168.0.1
            broadcast 192.168.0.255
            wpa-ssid "ssid"     # wifi AP
            wpa-psk "password"  # password
        ```


+ samba

    ```shell
    $ sudo apt-get install samba

    # add pi [username] to sambashare group
    $ sudo usermod -a -G sambashare pi

    # set password
    $ sudo pdbedit -a -u pi

    # add setting
    $ sudo vim /etc/samba/smb.conf
    ...
    [pi]
      comment = pi's home
      path = /home/pi
      read only = no
      guest ok = no
      browseable = yes
      create mask = 0644
      directory mask = 0755
    ```

+ enable uart port

    樹莓派包含兩個串口，一個稱之為硬件串口(/dev/ttyAMA0)，一個稱之為 mini 串口(/dev/ttyS0).

    硬件串口由硬件實現，有單獨的波特率時鐘源，性能高、可靠.

    mini串口時鐘源是由CPU內核時鐘提供，波特率受到內核時鐘的影響，不穩定

    - uart vs bluetooth
        1. `serial0` 是 GPIO 引腳對應的串口
        1. `serial1` 是藍牙對應的串口

        ```shell
        $ ls -l /dev/serial*
        lrwxrwxrwx 1 root root 5 Apr 13 15:17 /dev/serial0 -> ttyS0
        lrwxrwxrwx 1 root root 7 Apr 13 15:17 /dev/serial1 -> ttyAMA0
        ```

    - if no `serial0`

        ```shell
        $ sudo raspi-config
        Interfacing -> serial -> No -> Yes
        ```

    - switch `ttyAMA0` for minicom

        ```shell
        $ sudo echo "dtoverlay=pi3-miniuart-bt" >> /boot/config.txt
        ```

        ```shell
        # switch to default
        $ sudo sed -i '/dtoverlay=pi3-miniuart-bt/d' /boot/config.txt
        ```

+ enable spi port

    ```shell
    $ sudo raspi-config

    Interfacing Options -> P4 SPI -> Yes

    # check
    $ ls -l /dev/spi*
    /dev/spidev0.0
    /dev/spidev0.1
    ```

+ Python

    - GPIO

        ```shell
        $ sudo dpkg -i rpi.gpio-common_0.6.5-1_armhf.deb python-rpi.gpio_0.6.5-1_armhf.deb
        ```

        ```python
        #!/usr/bin/env python
        # encoding: utf-8

        import RPi.GPIO
        import time

        # 指定GPIO port 的選定模式為GPIO引腳編號模式(而非主板編號模式)
        RPi.GPIO.setmode(RPi.GPIO.BCM)

        # 指定GPIO14(就是LED長針連接的GPIO針腳)的模式為輸出模式
        # 如果上面GPIO port 的選定模式指定為主板模式的話,這里就應該指定8號而不是14號.
        RPi.GPIO.setup(14, RPi.GPIO.OUT)

        # 循環10次
        for i in range(0, 10):
            RPi.GPIO.output(14, True) # GPIO14 pull high
            time.sleep(0.5)
            RPi.GPIO.output(14, False) # GPIO14 pull low
            time.sleep(0.5)

        # clean GPIO port
        RPi.GPIO.cleanup()
        ```

    - Uart

        ```shell
        # download pip source from 'https://pypi.python.org/pypi/pip#downloads'
        # un-tar gz file and enter to source code
        $ python setup.py install

        # pyserial module
        $ sudo pip install pyserial-3.4-py2.py3-none-any.whl
        ```

# misc

+ libraries

    ```shell
    $ sudo apt-get update
    $ sudo apt-get install -y vim exuberant-ctags global tig git binutils gcc gdb automake autoconf pkgconfig libtool tree
    ```

+ autotool error: `Authentication issue instant is too old or in the future`

    ```shell
    # re-writ timestamp of files
    $ find . -type f -name '*.*' -exec touch {} \;
    ```

# library

```shell
$ sudo dpkg -i *.deb
```
+ [raspbian-packages](http://raspbian.raspberrypi.org/raspbian/pool/main/)
+ [libsigseg](http://raspbian.raspberrypi.org/raspbian/pool/main/libs/libsigsegv/libsigsegv2_2.10-5_armhf.deb)
+ [autoconf](http://raspbian.raspberrypi.org/raspbian/pool/main/a/autoconf/autoconf_2.69-10_all.deb)
+ [autotools-dev](http://raspbian.raspberrypi.org/raspbian/pool/main/a/autotools-dev/autotools-dev_20161112.1_all.deb)
+ [automake](http://raspbian.raspberrypi.org/raspbian/pool/main/a/automake-1.15/automake_1.15-6_all.deb)
+ [libltdl-dev](http://raspbian.raspberrypi.org/raspbian/pool/main/libt/libtool/libltdl-dev_2.4.6-2_armhf.deb)
+ [libtool](http://raspbian.raspberrypi.org/raspbian/pool/main/libt/libtool/libtool_2.4.6-2_all.deb)
+ [m4](http://raspbian.raspberrypi.org/raspbian/pool/main/m/m4/m4_1.4.18-1_armhf.deb)


# reference

+ [樹莓派開發筆記(六)：GPIO口的UART使用](https://blog.csdn.net/qq21497936/article/details/79758975)
+ [樹莓派 3 UART 及 GPIO 針腳定義](https://github.com/Yradex/RaspberryPi3_OS/wiki/%E6%A0%91%E8%8E%93%E6%B4%BE-3-UART-%E5%8F%8A-GPIO-%E9%92%88%E8%84%9A%E5%AE%9A%E4%B9%89)

