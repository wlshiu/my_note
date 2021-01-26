NDS32 Debugging
---

# Excepteions

## General exceptin

+ type
    > reason



# Andes ICE (ICEman)

+ install

    ```
    $ cd path/BSPvXXX/ice
    $ sudo ./ICEman.sh
    ```

    - Re-connect cable

+ trigger AICE

    ```
    $ ICEman -N reset-hold-script.tpl
        Andes ICEman v4.5.3 (OpenOCD) BUILD_ID: 2019120517
        Burner listens on 2354
        Telnet port: 4444
        TCL port: 6666
        Open On-Chip Debugger 0.10.0+dev-gdb5c113 (2019-12-05-17:33)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        Andes AICE-MINI v1.0.1
        There is 1 core in target
        JTAG frequency 12 MHz
        The core #0 listens on 1111.
        ICEman is ready to use.
    ```

