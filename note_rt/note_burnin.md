Burn Image
---

## Daily Build

+ path
    - [QC Daily Build] (\\172.22.1.23\mm_data\TVQC_ADB)
        > RTD2871_DEMO_BOARD_S2AL2A -> `Merlin2\DB177_Merlin2_FW_TV001_RTD2871_DEMO_Sina_Driverbase`
        >   > which version can use ?? God bless you, just try and error...... WTF
    - [SQA Daily Build] (\\172.22.56.20\images)


## USB Debug board

+ FT232R USB to UART
    - [Driver] (http://cadinfo.realtek.com/svn/MM/sd-tv-tools/branches/RTICEv4/General/CDM_v2.12.06_WHQL_Certified.rar)

## Panel

+ BenQ connection
    - LVDS bus
    - PWM control DuPont line (4 pins)
        > It *MUST* be `5-Voltage` or BenQ panel crash

## Burn in
+ Burn bootloader

    - [Boot code for QC Daily Build.] (http://172.21.0.100/svn/col/DVR/merlin2/software/SQA_DailyBuild/bootcode/RTD289XP_demo_int_ddr_DCU1_2G2G_securestore)
        > dvrboot.rescue.exe.bin

    - [rtICE] (http://cadinfo.realtek.com/svn/MM/sd-tv-tools/branches/RTICEv4/General/rtice-standard-5.6.10-en.7z)
        > Owner will announce the last version
        >> very very ... very slow

        1. Burn (left) -> Burn -> boot_DDR3 -> select image
        1. system option -> set-status type: Rom_code -> IC type: merlin2

+ USB
    - Bootloader ONLY search `install.img` file name in USB disk

    - Start burn image
        > Press `Tab` key and reboot PCBA


    - Enter bootload console
        > Pres `ESC` key and reboot PCBA


+ tftp
    > Video/Audio F/w load to Dram and run

    - PC side
        1. install `tftp64d`
        1. set the `start_path`
            > Client (PCBA) will connect and search the file from `start_path`


    - PCBA side
        1. enter bootloader
            ```
            #  Press ESC and reboot: enter Bootcode console Mode
            Realtek>
            ```
        1. set env variables
            ```
            Realtek> env set ethaddr 00:xx:xx:xx:xx:xx  # MAC address
            Realtek> env set ipaddr 172.22.49.29        # PCBA ip
            Realtek> env set gatewayip 172.22.49.254
            Realtek> env set serverip 172.22.49.xx      # PC ip
            Realtek> env set tftpblocksize 512
            Realtek> env save
            Realtek> env print
            ```

        1. Burn in
            ```
            Realtek> tftp 0x1500000 dvrboot.exe.bin

              # start kernel
            Realtek> go 0x1500000   # maybe need twice
            ```

        1. Video F/W start address
            ```
            Realtek> tftp 0x1a900000 video_firmware.bin
            Realtek> tftp 0x1ae00000 video2_firmware.bin
            ```


+ NFS
    > Mount for APP

        1. set env variables
            ```
            Realtek> env set ethaddr 00:xx:xx:xx:xx:xx  # MAC address
            Realtek> env set ipaddr 172.22.49.29        # PCBA ip
            Realtek> env set gatewayip 172.22.49.254
            Realtek> env set serverip 172.22.49.xx      # PC ip
            Realtek> env set tftpblocksize 512
            Realtek> env save
            Realtek> env print

              # run to kernel ready
            Realtek> go  0x1500000
            ```

        1. mount nfs

            ```
              # set eth0 ip, which is in PC ip domain
            $ ifconfig eth0 172.22.49.178
            $ mkdir /tmp/nfs
            $ mount -t nfs -o proto=tcp -o nolock 172.22.49.177:/home/username/my_nfs/ /tmp/nfs/
            ```
            or

            ```
            $ /bin/busybox route del -net 127.0.0.0 netmask 255.0.0.0 dev lo;

              # set eth0 ip/mask and enable
            $ ifconfig eth0 172.22.49.xx netmask 255.255.255.0
            $ route add default gw 172.22.49.254 dev eth0
            $ mount -o rw,remount /tmp/usbmounts/sda1
            $ mount -t nfs -o rsize=1024,wsize=1024,tcp,nolock \
                172.22.49.xx:/heme/xxx/system/project/PanEuroDVB /mnt/hdb
            ```

# Pack image

+ Prepare APP executable file and resource

    ```
    # System_APP_project_path = ~/system/project/PanEuroDVB
    # in ~/system/project/
    $ make release

    # all resouce will copy to ${System_APP_project_path}/bin/
    ```

+ re-pack image
    > the packing shell script is in merlin2 kernel code

    ```
      # check out code
    $ mkdir ${merlin2_kernel_path} && cd ${merlin2_kernel_path}
    $ repo init -u ssh://code.realtek.com.tw:20001/rtk/native/manifest -b merlin2
    $ repo sync
    $ repo start my_master -all

      # build merlin2 kernel
    $ cd ${merlin2_kernel_path}/kernel/system
    $ make PRJ=develop.rtd289x.tv001.emmc.sina


      # if use the 'package3.tar.gz' in daily build, it should delete bootfile.image or bootfile.raw
    $ rm -f ${merlin2_kernel_path}/image_file_creator/components/packages/package3/customer/tv001/bootfile.image
    $ rm -f ${merlin2_kernel_path}/image_file_creator/components/packages/package3/customer/tv001/bootfile.raw


      # package3 mean EMMC version......WTF
      # replace the files about APP
    # $ rm -fr ${merlin2_kernel_path}/image_file_creator/components/packages/package3/ap/bin
    $ cp -fr ${System_APP_project_path}/bin ${merlin2_kernel_path}/image_file_creator/components/packages/package3/ap/bin

      # re-pack image
    $ cd ${merlin2_kernel_path}/image_file_creator

      # set install_ap/install_bootloader to involve APP or Bootloader
    $ make image PACKAGES=package3 CUSTOMER_ID=tv001 install_ap=1 install_bootloader=0

    ```














