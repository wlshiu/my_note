TFTP - Trivial File Transfer Protocol
---

+ Ubuntu

    - install

        ```shell
        $ sudo apt-get install tftpd-hpa tftp-hpa
        ```

        1. tftpd-hpa
            > Server

        1. tftp-hpa
            > Client

    - configure

        ```
        $ sudo vim /etc/default/tftpd-hpa
        TFTP_USERNAME="tftp"
        TFTP_DIRECTORY="/tftpboot"
        TFTP_ADDRESS="0.0.0.0:69"
        TFTP_OPTIONS="-l -c -s"
        ```

        1. tftp directory

            ```shell
            $ sudo mkdir /tftpboot
            $ sudo chmod -R 777 /tftpboot
            $ sudo chown nobody.nogroup -R /tftpboot
            ```

    - restart server tftpd-hpa

        ```shell
        $ sudo /etc/init.d/tftpd-hpa start
        ```

    - check listening tftp (port 69)

        ```shell
        $ netstat  -a| grep  tftp
        udp        0      0 *:tftp                  *:*
        ```

    - client

        ```shell
        $ tftp 127.0.0.1
        tftp>
        ```

        1. commands
            > + `get [file name]`
            > + `put [file name]`
            > + `quit`
            > + `help or ?`

            ```shell
            $ tftp> get test.txt
            ```

        1. once command

            ```
            # check host IP
            $ ifconfig eth0 | grep addr

            $ tftp 192.168.56.3 -v -c get test.txt
            $ tftp 192.168.56.3 -v -c put 1.txt
            ```

+ Win 10

    - enable tftp feature

        ```
        WIN+R -> type 'appwiz.cpl'

        'Turn Windows features on or off' tab

        enable 'TFTP Client'
        ```

    - cmd window

        ```
        $ tfpt -i 192.168.56.3 GET test.txt
        ```

