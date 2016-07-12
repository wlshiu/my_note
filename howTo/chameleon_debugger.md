Chameleon debugger note
---

# Multi-core

- Setup IDE
    1. execute Chameleon debugger
    2. In system configuration window, select core_0 to Activate Target
    3. menu view -> system configuration, select core_1 to Activate Target
        > display `red frame command window`
    4. When `red frame command window` is foreground, you operate core_1
    5. When `normal command window` is foreground, you operate core_0

-


# Dubugging

- RTOS side
    0. In a multi-core chip, Configure chameleon dubugger to multi-core stat
    1. power on PCBA and boot system
    2. In Chameleon debugger, `Stop` all CPUs
        > You can use long sleep to break at boot time.
    3. load symbol file
        a. memu file -> Load
        b. In Load window (options area), `only select Symbol item`
        c. Press Browse button, choose your symbol file.
            > eg. amba_app.elf (symbol of app layer)
        d. load
    4. set H/w breakpoint and set start PC address
    5. Press Go button to act all CPUs


# Burn-in F/w

- NAND boot mode
    1. power on PCBA and enter bootloader mode
    2. Press `Stop` to pause CPU
    3. menu file -> Load
    4. In Load window (options area), select `Load code`, `Initialize CPU, Set PC`, `Verify Code`, `Open Modules`
    5. Press Browse button, choose your F/w file.
        > eg. bst_bld_pba_sys_dsp_rom_lnx_rfs.elf (super set)
    6. Press `Load` to download F/w to DRAM in PCBA
    7. Press `Go` to to make CPU write F/w to NAND

- USB boot mode (trigger from Chameleon debugger)
    1. change H/w trap to usb boot mode
        > a9s EVK cheetah => SW1, pin_8

    2. load initial script
        > `~/rtos/tools/soc/Chameleon/Ambarella-A9S/arm/*.mac`

        a. menu tool -> Macros -> Edit, Add hot key for your script
        b. press hot key to initialize PCBA

    3. menu file -> Load
    4. In Load window (options area), select `Load code`, `Initialize CPU, Set PC`, `Verify Code`, `Open Modules`
    5. Press Browse button, choose your F/w file.
        > eg. bst_bld_pba_sys_dsp_rom_lnx_rfs.elf (super set)
    6. Press `Load` to download F/w to DRAM in PCBA
    7. Press `Go` to make CPU write F/w to NAND




