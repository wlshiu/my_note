DHCP
---

# windows

    tftpd64

+ configure setting
    > `Settings` -> DHCP tab

    - DHCP Pool definition

        1. `IP pool start address`: DHCP start ip address item
            > this ip address MUST be in the LAN of inferface which is selected.

            ```
            e.g. 192.168.20.5
            ```

        1. `Size of pool`: the max number of clints

        1. `Boot File`: a file name which you want to pass to client
            > it can be empty or set the file name which transfer with tftp

    - DHCO Options
        > the option commands

        1. `Def. router (Opt 3)`: the default router address

            ```
            e.g. 192.168.20.1
            ```

        1. `Mask (Opt 1)`: the netmask

            ```
            e.g. 255.255.255.0
            ```

# ubuntu 18.04

    isc-dhcp-server

+ install

    ```
    $ sudo apt install isc-dhcp-server
    ```

+ configure setting

    - set interface

        ```
        $ sudo vi /etc/default/isc-dhcp-server
        ...
        INTERFACES=""  => INTERFACES="eth0" or "enp0s8"
        ```

    - set dhcp config
        ```
        $ sudo vim /etc/dhcp/dhcpd.conf
        ...
        # add to tail
        subnet 192.168.56.0 netmask 255.255.255.0 {
            range 192.168.56.5 192.168.56.10;
            option domain-name-servers 8.8.8.8;
            option domain-name "my-cloud.orz";
            option subnet-mask 255.255.255.0;
            option routers 196.168.56.3;  # dhcp server ip address
            option broadcast-address 192.168.56.254;
            default-lease-time 600;
            max-lease-time 7200;
            filename "boot_rom.elf";  # the boot file name
        }
        ```

+ run dhcp server

    ```
    $ sudo systemctl enable isc-dhcp-server
    $ sudo systemctl restart isc-dhcp-server
    ```

+ check dhcp server status

    ```
    $ sudo systemctl status isc-dhcp-server
    ```

+ list assigned addresses

    ```
    $ dhcp-lease-list
    ```

+ misc

    - error msg `Can't open /var/lib/dhcp/dhcpd.leases for append.`
        > change permission

    ```
    $ sudo chmod -R 777 /var/lib/dhcp/dhcpd.leases
    ```

    - Virtualbox disable default DHCP server
        > `File` -> `Host Network Manager (Ctrl + H)` -> `DHCP Server tab` -> cancel `Enable DHCP Server`


# DHCP client test

+ [dhcptest](https://github.com/CyberShadow/dhcptest)

    ```
    # windows console
    $ dhcptest-0.7-win64.exe --quiet --query --wait --tries 5 --timeout 10
    op=BOOTREPLY chaddr=F0:E2:61:86:3D:4B hops=0 xid=12F4D074 secs=0 flags=8000
    ciaddr=0.0.0.0 yiaddr=196.168.20.5 siaddr=169.254.163.199 giaddr=0.0.0.0 sname= file=
    9 options:
     53 (DHCP Message Type): offer
     54 (Server Identifier): 169.254.163.199
      1 (Subnet Mask): 255.255.255.0
      3 (Router Option): 196.168.20.1
     51 (IP Address Lease Time): 172800 (2 days)
     58 (Renewal (T1) Time Value): 86400 (1 day)
     59 (Rebinding (T2) Time Value): 138240 (1 day, 14 hours, and 24 minutes)
      7 (Log Server Option): A9 FE A3 C7
     66 (TFTP server name): 169.254.163.199
    ```

+ [nmap](https://nmap.org/download.html)

    ```
    # sudo nmap --script broadcast-dhcp-discover [-e NetInterface]
    $ sudo nmap --script broadcast-dhcp-discover -e enp0s8
    Starting Nmap 7.70 ( https://nmap.org ) at 2018-04-29 10:09 PDT
    Pre-scan script results:
    | broadcast-dhcp-discover:
    |   Response 1 of 1:
    |     IP Offered: 192.168.29.131
    |     DHCP Message Type: DHCPOFFER
    |     Server Identifier: 192.168.29.1
    |     IP Address Lease Time: 2m00s
    |     Renewal Time Value: 1m00s
    |     Rebinding Time Value: 1m45s
    |     Subnet Mask: 255.255.255.0
    |     Broadcast Address: 192.168.29.255
    |     Domain Name Server: 192.168.29.1
    |     WPAD:
    |     NetBIOS Name Server: 192.168.29.1
    |     Domain Name: example.com
    |_    Router: 192.168.29.1
    WARNING: No targets were specified, so 0 hosts scanned.
    Nmap done: 0 IP addresses (0 hosts up) scanned in 3.21 seconds
    ```

+ [dhcpdump](https://linux.die.net/man/1/dhcpdump)

    ```
    $ sudo apt-get install dhcpdump

    # dhcpdump -i [NetInterface]
    $ dhcpdump -i eth0
      TIME: 2010-05-06 15:42:33.000
        IP: 0.0.0.0 (0:19:d1:2a:ba:a8) > 255.255.255.255 (ff:ff:ff:ff:ff:ff)
        OP: 1 (BOOTPREQUEST)
     HTYPE: 1 (Ethernet)
      HLEN: 6
      HOPS: 0
       XID: e16fef09
      SECS: 0
     FLAGS: 0
    CIADDR: 0.0.0.0
    YIADDR: 0.0.0.0
    SIADDR: 0.0.0.0
    GIADDR: 0.0.0.0
    CHADDR: 00:19:d1:2a:ba:a8:00:00:00:00:00:00:00:00:00:00
     SNAME: .
     FNAME: .
    OPTION:  53 (  1) DHCP message type         3 (DHCPREQUEST)
    OPTION:  50 (  4) Request IP address        192.168.2.2
    OPTION:  12 ( 13) Host name                 vivek-desktop
    OPTION:  55 ( 13) Parameter Request List      1 (Subnet mask)
                             28 (Broadcast address)
                              2 (Time offset)
                              3 (Routers)
                             15 (Domainname)
                              6 (DNS server)
                            119 (Domain Search)
                             12 (Host name)
                             44 (NetBIOS name server)
                             47 (NetBIOS scope)
                             26 (Interface MTU)
                            121 (Classless Static Route)
                             42 (NTP servers)
    ```

