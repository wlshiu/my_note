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
            vim git ctags cscope id-utils
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







