[zephyr-rtos](https://github.com/zephyrproject-rtos/zephyr)
---

+ [Getting Started Guide](https://docs.zephyrproject.org/latest/getting_started/index.html)

    - setup enviornment

        ```
        $ sudo apt install -y --no-install-recommends git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev
        ```

        1. cmake MUST use `3.13.1` or higher

            ```
            $ wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | sudo apt-key add -
            $ sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
            $ sudo apt update
            $ sudo apt install cmake
            ```

        1. python dependencies

            ```
            $ pip3 install --user -U west
            $ echo 'export PATH=$HOME/.local/bin:"$PATH"' >> ~/.bashrc
            $ source ~/.bashrc
            ```

        1. download Zephyr source code

            ```
            $ west init $HOME/zephyrproject
            $ cd $HOME/zephyrproject
            $ west update
            ```
        1. others

            ```
            $ west zephyr-export
            $ pip3 install --user -r $HOME/zephyrproject/zephyr/scripts/requirements.txt
            ```

    - toolchain

        ```
        $ cd ~
        $ wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.11.3/zephyr-sdk-0.11.3-setup.run
        $ chmod +x zephyr-sdk-0.11.3-setup.run
        $ ./zephyr-sdk-0.11.3-setup.run -- -d $HOME/zephyr-sdk-0.11.3
        ```

    - Build

        ```
        $ source $HOME/zephyrproject/zephyr/zephyr-env.sh
        $ cd $HOME/zephyrproject/zephyr
        $ west build -p auto -b qemu_cortex_m3 samples/hello_world
        ```

        1. `zephyr-env.sh` will export environment varables
            > `west build` will read `.zephyrrc`

            ```
            $ vi $HOME/.zephyrrc
                export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
                export ZEPHYR_BASE=$HOME/zephyrproject/zephyr
                export ZEPHYR_SDK_INSTALL_DIR=$HOME/zephyr-sdk-0.11.3
            ```

        1. `-b qemu_cortex_m3`
            > set board type

    - Run

        1. Running in an Emulator
            > you should set `BOARD` to one of the QEMU boards
            > + `qemu_x86` to emulate running on an x86-based board
            > + `qemu_cortex_m3` to emulate running on an ARM Cortex M3-based board

            ```
            $ west build -t run
            ```

            > Press `Ctrl + A, X` to stop the application from running in QEMU.

        1. Running on a Board

            ```
            $ west flash
                or
            $ ninja run
            ```

    - Clean

        ```
        $ west build -t clean
            or
        $ rm -fr $HOME/zephyrproject/zephyr/build
        ```

    - QEMU Debug

        ```
        # gdb server
        $ qemu -s -S zephyr.elf
            or
        $ ninja debugserver
        ```

        ```
        # gdb client
        $ gdb --tui zephyr.elf
        (gdb) target remote localhost:1234
        ```

        1. use `DDD` (Data Displayer Debugger)
            > it also executes the gdb

            ```
            $ sudo apt-get install ddd
            $ ddd --gdb --debugger "gdb zephyr.elf"
            ```

+ without `west`

    - switch directory to application

        ```
        $ cd sample/hello_world
        ```
    - cmake builder

        ```
        $ mkdir build && cd build
        $ cmake -GNinja -DBOARD=qemu_cortex_m3 ..
        $ ninja menuconfig
        $ ninja             # start building
        $ ninja run         # run emulation
        ```

# [NRF52 simulated board (BabbleSim)](https://docs.zephyrproject.org/latest/boards/posix/nrf52_bsim/doc/index.html#nrf52-bsim)

[BabbleSim](https://babblesim.github.io/)

+ BabbleSim setup

    - compile

        ```
        $ sudo apt-get install libfftw3-dev
        $ mkdir -p $HOME/BabbleSim && cd $HOME/BabbleSim
        $ curl https://storage.googleapis.com/git-repo-downloads/repo > ./repo  && chmod a+x ./repo
        $ ./repo init -u https://github.com/BabbleSim/manifest.git -m everything.xml -b master
        $ ./repo sync
        $ make everything -j 8
        ```
    - set enviornment

        ```
        $ echo 'export BSIM_OUT_PATH=$HOME/BabbleSim/' >> $HOME/.zephyrrc
        $ echo 'export BSIM_COMPONENTS_PATH=$HOME/BabbleSim/components/' >> $HOME/.zephyrrc
        ```

+ simulation

    - compile APP

        1. `west`

            ```
            $ west build -b nrf52_bsim samples/bluetooth/beacon/
            ```

        1. without `west`

            ```
            $ cd samples/bluetooth/beacon/
            $ mkdir out && cd out
            $ cmake -GNinja -DBOARD=nrf52_bsim ..
            $ ninja
            $ gdb ./zephyr/zephyr.exe
            (gdb) file ./zephyr.elf
            (gdb) b zephyr_app_main()
            (gdb) r
            ```

    - run

        ```
        #  Press Ctrl+C to exit
        $ $HOME/zephyrproject/zephyr/build/zephyr/zephyr.exe -nosim
            d_00: @00:00:00.000000  *** Booting Zephyr OS build zephyr-v2.3.0-1263-g4a492bb55ea9  ***
            d_00: @00:00:00.000000  Starting Beacon Demo
            d_00: @00:00:00.000000  [00:00:00.000,000] <inf> bt_hci_core: HW Platform: Nordic Semiconductor (0x0002)
            d_00: @00:00:00.000000  [00:00:00.000,000] <inf> bt_hci_core: HW Variant: nRF52x (0x0002)
            d_00: @00:00:00.000000  [00:00:00.000,000] <inf> bt_hci_core: Firmware: Standard Bluetooth controller (0x00) Version 2.3 Build 99
            d_00: @00:00:00.000000  [00:00:00.000,000] <wrn> bt_hci_core: No static addresses stored in controller
            d_00: @00:00:00.002648  [00:00:00.002,624] <inf> bt_hci_core: Identity: ed:3b:20:15:18:12 (random)
            d_00: @00:00:00.002648  [00:00:00.002,624] <inf> bt_hci_core: HCI: version 5.2 (0x0b) revision 0x0000, manufacturer 0x05f1
            d_00: @00:00:00.002648  [00:00:00.002,624] <inf> bt_hci_core: LMP: version 5.2 (0x0b) subver 0xffff
            d_00: @00:00:00.002648  Bluetooth initialized
            d_00: @00:00:00.003368  Beacon started
        ```

    - debug

        ```
        $ gdb $HOME/zephyrproject/zephyr/build/zephyr/zephyr.exe
        (gdb) file ./zephyr.elf
        (gdb) b zephyr_app_main()
        (gdb) r
        ```

    - backtrace

        ```
        #0  hci_driver_open () at /home/vng/working/my_space/test/zephyrproject/zephyr/subsys/bluetooth/controller/hci/hci_driver.c:489
        #1  0x56571782 in bt_enable (cb=0x5655f27e <bt_ready>) at /home/vng/working/my_space/test/zephyrproject/zephyr/subsys/bluetooth/host/hci_core.c:6633
        #2  0x5655f366 in zephyr_app_main () at ../src/main.c:70
        ```

    - simulation with radio activity
        > BableSim `2G4 (2.4GHz)` physical layer simulation (phy)
        >> `${BSIM_OUT_PATH}/bin/bs_2G4_phy_v1` is the simulater of `2.4GHz PHY`

        1. build application

            ```
            $ cd samples/bluetooth/central_hr/
            $ mkdir out && cd out
            $ cmake -G"Unix Makefiles" -DBOARD=nrf52_bsim ..

            $ cd samples/bluetooth/peripheral/
            $ mkdir out && cd out
            $ cmake -G"Unix Makefiles" -DBOARD=nrf52_bsim ..

            $ cp samples/bluetooth/central_hr/out/zephyr/zephyr.exe \
                ${BSIM_OUT_PATH}/bin/nrf52_bsim_samples_bt_central_hr

            $ cp samples/bluetooth/peripheral/out/zephyr/zephyr.exe \
                ${BSIM_OUT_PATH}/bin/nrf52_bsim_samples_bt_peripheral
            ```

        1. BabbleSim's `2G4(2.4GHz)` simulation
            > run them together
            >> Run `-help` for more information.

            ```
            $ ${BSIM_OUT_PATH}/bin/nrf52_bsim_samples_bt_peripheral -s=trial_sim -d=0 &
            $ ${BSIM_OUT_PATH}/bin/nrf52_bsim_samples_bt_central_hr -s=trial_sim -d=1 &
            $ ${BSIM_OUT_PATH}/bin/bs_2G4_phy_v1 -s=trial_sim -D=2 -sim_length=10e6 &
            ```

            > + `-s` option provides a string which uniquely identifies this simulation
            > + `-D` option tells the Phy how many devices will be run in this simulation
            > + `-d` option tells each device which is its device number in the simulation
            > + `-sim_length` option specifies the length of the simulation in microseconds,
            e.g. `10e6` is `10us`, `100e3` is 100ms

        1. stop simulation
            > the script will stop all your ongoing simulations,
            or provide to it a simulation ID as its only paramter,
            in which case it will only stop the processes linked to that simulation

            ```
            $ ${BSIM_COMPONENTS_PATH}/common/stop_bsim.sh
            ```

        1. dump phy log
            > The `bs_2G4_phy_v1` can dump all radio activity to files.
            You control this with the `-dump` command line options.
            This radio activity can be easily imported for analysis into the Ellisys Bluetooth Analyzer SW.

        1. convert output for analysis

            ```
            $ ${BSIM_OUT_PATH}/components/ext_2G4_phy_v1/dump_post_process/convert_results_to_ellisysv2.sh results/<sim_id>/d_2G4*.Tx.csv > ~/Trace.bttrp
            ```

        1. [Ellisys Bluetooth Analyzer SW](https://www.ellisys.com/products/bex400/index.php#screenshots)
            > The trace can then be imported into the Ellisys SW

            ```
            File > Import ; Select Bluetooth packets ; Click Next ; Click Browse ; and select/open the file.
            ```


# reference

+ [Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE](https://electronut.in/getting-started-with-zephyr-rtos-on-nordic-nrf52832-hackable/)
+ [Samples and Demos](https://docs.zephyrproject.org/latest/samples/index.html#samples-and-demos)
    - [Developing Bluetooth Applications](https://docs.zephyrproject.org/latest/guides/bluetooth/bluetooth-dev.html#bluetooth-hw-setup)
+ [Supported Boards](https://docs.zephyrproject.org/latest/boards/index.html)
+ [Bluetooth Stack Architecture](https://docs.zephyrproject.org/latest/guides/bluetooth/bluetooth-arch.html)
