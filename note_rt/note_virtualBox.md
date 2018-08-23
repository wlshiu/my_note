VirtualBox
---

# lubuntu

+ install `Lubuntu minimal installation`
    > [web] (http://cdimage.ubuntu.com/netboot/) download `mini.iso`

+ Add new virtual Disk
    1. virtualBox setup

    1. In lubuntu
        a. list disk and find your new disk
            ```
            $ sudo fdisk -l
            ```
        a. format disk
            ```
            $ sudo mkfs -t ext4 /dev/sdb
            ```
        a. mount device
            ```
            $ sudo mkdir /data
            $ sudo mount /dev/sdb /data
            ```
        a. set auto mount

            ```
            $ sudo blkid  # get UUID of new disk
            $ sudo vim /etc/fstab

                ...
                # add infomation
                UUID=your_disk_UUID    /data    ext4    defaults     0    1
                ...


            # change owner
            $ sudo chown -R username:group /data

            # set link
            $ cd ~/
            $ ln -sv /data ./work
            ```

+ update atp-get
    1. edit sources.list

        ```
        $ sudo gedit /etc/apt/sources.list

        # replace "http://tw.archive.canonical.com/ubuntu/" with "server_url" in sources.list

        ```
        a. [NCHC, Taiwan, 20 Gbps] (http://free.nchc.org.tw/ubuntu/)
        a. [TaiChung County Education Network Center, 1 Gbps] (http://ftp.tcc.edu.tw/Linux/ubuntu/)

    1. update list
        ```
        $ sudo apt-get update
        ```

    1. upgrade
        ```
        $ sudo apt-get upgrade
        ```
    1. apt-get remove xxx
        > un-install xxx

+ Environment
    ```
    $ sudo apt-get install build-essential make dos2unix automake libtool pkg-config \
            vim git ctags cscope id-utils texinfo
    ```
    - svn
        > In RTK, it only support `subversion 1.6.17`

        1. [svn download web] (http://mirrors.kernel.org/ubuntu/pool/main/s/subversion/)
            > package
            >> `libsvn1_1.6.17dfsg-3ubuntu3.5_amd64.deb`, `subversion_1.6.17dfsg-3ubuntu3.5_amd64.deb`
        1. [db lib download web] (http://mirrors.kernel.org/ubuntu/pool/main/d/db4.8)
            > package
            >> `libdb4.8_4.8.30-11ubuntu1_amd64.deb`

        1. manually install
            > you should heed the dependency

            ```
            $ sudo apt-get install libneon27-gnutls
            $ sudo dpkg -i libdb4.8_4.8.30-11ubuntu1_amd64.deb \
                libsvn1_1.6.17dfsg-3ubuntu3.5_amd64.deb \
                subversion_1.6.17dfsg-3ubuntu3.5_amd64.deb

            ```

    - `32bits-toolchain` in `64bits-OS`
        1. Enable the i386 architecture (as root user)
            ```
            $ dpkg --add-architecture i386
            $ apt-get update
            ```
        1. Install 32-bit libraries
            ```
            $ apt-get install libc6:i386 libstdc++6:i386 lib32ncurses5 lib32z1
            ```

+ resolution
    1. Install `VboxGuestAdditions`

        ```
        $ cd /media/VBOXADDITIONS_x.x.xxx/
        $ sudo ./VBoxLinuxAdditions.run
        ```
    1. In lubuntu, Perferences -> Monitor Settings

+ Share Folder
    > Need to Install `VboxGuestAdditions`

    1. Setup shard folder setting in VirtualBox
    1. Check active
        ```
        $ ls /media/sf_xxxx

        # create link for using
        $ ln /media/sf_xxx ~/sf_share
        ```
    1. If get `Permission denied`

        a. Add to group
            ```
            $ sudo adduser yourusername vboxsf
            ```
    1. auto mount share folder
        a. Add setting `vboxsf.conf`
            ```
            $ touch /etc/modules-load.d/vboxsf.conf
            ```
        a. type `vboxsf` to vboxsf.conf

    1. MUST reboot system

+ Change graphic/text UI login
    - Text login
        > F1 ~ F6 is txet mode in Linux
        1. With Real Linux/
            > ALT+CTRL+F1

        1. With Virtual Linux
            > ALT+CTRL+SPACE and Keep ALT+CTRL prees F1
    - Graphic login
        > F7 is Graphic mode in Linux
        1. With Real Linux/
            > ALT+CTRL+F7
        1. With Virtual Linux
            > ALT+CTRL+SPACE and Keep ALT+CTRL prees F7

+ Samba
    - install

+ Network File System (NFS)
    - VirtualBox
        1. set network `Adapter 2`
            a. Atteched to: Bridged Adapter
            a. name: MAC Bridge Miniport
                > In windows PC side
                > + Control Panel -> Network and Sharing Center ->  Change adapter settings
                > + select both your physical adapter and *VirtualBox Host-Only Network*
                > + right key of mouse, press *Bridge Connections*
                > + Windows will new a network bridge *MAC Bridge Miniport*
            a. Adapter Type: Intel .... (82540EM)
            a. Promiscuous Mode: Allow All (maybe 'Deny' also work)
            a. Reflash MAC address

    - lunbuntu 16.04

        1. install
            ```
            $ apt-get install nfs-kernel-server nfs-common portmap
            ```

        1. setup
            a. set network interface
                g. manual setting
                    ```
                    $ sudo ifconfig enp0s8 192.168.0.100 network 255.255.255.0
                    ```

                g. edit /etc/network/interface for auto enable
                    ```
                    # Add network interface setting
                    auto enp0s8
                    iface enp0s8 inet static    # static ip
                    address 192.168.0.100       # it should be in the same domain with PCBA
                    netmask 255.255.255.0
                    network 192.168.1.1
                    broadcast 192.168.0.255
                    gateway 192.168.0.254       # it should be in the same domain with PCBA


                    # rtk route setting
                    up route add default gw 172.22.49.254 metric 1
                    dns-nameservers 172.21.1.10 172.21.1.11
                    dns-search realtek.com.tw
                    ```

            a. edit /etc/exports
                ```
                # Allow connection from any (*)
                /home/username/my_nfs *(rw,sync,no_root_squash,no_subtree_check)

                  # update export info
                $ exportfs -ra
                ```
            a. Set the share folder
                ```
                $ mkdir ~/my_nfs

                  # it is available by anyone.
                $ sudo chmod 777 ~/my_nfs
                ```
        1. enable NFS
            ```
            $ sudo service nfs-kernel-server restart
            ```

        1. test
            a. local test

                ```
                $ sudo mkdir /tmp/test_nfs
                $ sudo chmod 777 /tmp/test_nfs
                $ sudo mount -t nfs -o nolock localhost:/home/username/my_nfs/ /tmp/test_nfs
                $ ls /tmp/test_nfs
                ```
    - PCBA
        1. manual setting
            ```
              # set eth0 ip, which is in PC ip domain
            $ ifconfig eth0 192.168.0.105 netmask 255.255.255.0
            $ mkdir /tmp/nfs
            $ mount -t nfs -o proto=tcp -o nolock 172.22.49.177:/home/username/my_nfs /tmp/nfs
            ```
        1. script
            ```
            #!/bin/sh

            Red='\e[0;31m'
            Yellow='\e[1;33m'
            Green='\e[0;32m'
            Cyan='\e[0;36m'
            NC='\e[0m' # No Color

            host_ip=192.168.0.100
            local_ip=192.168.0.105

            ifconfig eth0 ${local_ip} netmask 255.255.255.0
            sleep 5

            if !ping -c 3 ${host_ip} > /dev/null 2>&1; then
                echo -e "${Red} !!!!!!! connecte ${host_ip} fail !!!${NC}"
                exit 1;
            else
                echo -e "connect ${host_ip} ok.........."
            fi

            # set -e

            if [ -d /tmp/nfs ]; then
                umount -l /tmp/nfs
                rm -fr /tmp/nfs
            fi

            mkdir /tmp/nfs
            mount -t nfs -o nolock -o proto=tcp ${host_ip}:/home/wl/work/ /tmp/nfs/
            if [ $? == 0 ]; then
                echo -e "${Yellow}mount nfs ok.....${NC}"
            else
                echo -e "${Red} mount nfs fail !!!! ${NC}"
            fi

            ```
