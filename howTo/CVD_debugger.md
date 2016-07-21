CVD debugger note
---

# Dubugging

- Setup environment
    1. check F/W
        a. NAND boot
            > image in NAND

        b. memroy boot
            > CVC load image to memroy

    2. link CPU in EVK (need to press `GO`)
        > ~\rtos\tools\soc\CodeViser\Ambarella-H2\Ambarella_H2_CVD64.csf

        > init DRAM with script (need to press `GO`) <br>
        > NAND boot maybe doesn't need.
        >> ~\rtos\tools\soc\CodeViser\Ambarella-H2\Bin\Ambarella-H2-LPDDR3_H9CCNNN8GTMLAR_456MHz.csf

    3. load symbol file
        > menu program -> load -> select option `No-code` -> select your `*.elf`

        a. linux: vmlinux
        b. rtos: elf file

    4. add Source_Path
        > menu config -> source path -> add source code root directory


    + develop with scritp
        > `;` is comment

        ```csf
        ;// Amba:LogLevel 3
        ;// Amba:MemMap 0xEC000000 0x01000000 IO
        ;// Amba:Aarch  64

        Disconnect
        ; WinCloseAll
        wait.100ms

        SelectBREAK %program %hw

        LOCAL  &rtos_root_path &dram_init_script &is_do_burn_in

        ;--- target dram init script
        ;----- Ambarella-H2-LPDDR3_H9CCNNN8GTMLAR_456MHz.csf
        ;----- Ambarella-H2-LPDDR3_H9CCNNN8GTMLAR_600MHz.csf
        &dram_init_script="Ambarella-H2-LPDDR3_H9CCNNN8GTMLAR_456MHz.csf"

        ;--- set your rtos path
        PWD Z:\h2\sdk_main_full\rtos\rtos
        &rtos_root_path=CDIR()

        ;--- link cpu
        execute &rtos_root_path\tools\soc\CodeViser\Ambarella-H2\Ambarella_H2_CVD64.csf

        ;--- init Memory controler
        execute &rtos_root_path\tools\soc\CodeViser\Ambarella-H2\Bin\&dram_init_script

        &is_do_burn_in=0

        IF &is_do_burn_in==1
        (
            ;--- burn-in linux elf to NAND
            PRINT "Load linux elf file"
            wait.1s
            LoadImage "&rtos_root_path\output\out\fwprog64\your_burn_in_elf.elf"
            GO
            ;---wait until target stop
            WAIT !ISRUN()
            PRINT %ERROR "Target STOP"
            wait.2s
        )

        ;--- re-init Memory controler
        execute &rtos_root_path\tools\soc\CodeViser\Ambarella-H2\Bin\&dram_init_script

        ;--- load rtos bin file
        PRINT "Load bin file"
        wait.1s
        LoadBinary "&rtos_root_path\output\out\amba_ssp_svc.bin" 0x00020000

        ;--- load atf
        LoadImage "&rtos_root_path\vendors\arm-trusted-firmware\output\bl31.elf" %multi

        ;--- load symbol
        PRINT "Load symbol file"
        wait.1s
        LoadImage "&rtos_root_path\output\out\your_target_symbol.elf" %multi %symbol
        wait.1s
        LoadImage "&rtos_root_path\output\out\your_target_symbol.elf" %multi %symbol

        ;--- Write the pc and flag to AMBA_BOOTPARAM_BASE
        ;--- PC = 0x00020000 and 32-bit OS
        MWriteS32 0xE001B018 %Verify 0x00020001

        ;--- set source path
        SourcePathReset
        AddSourcePath &rtos_root_path
        AddSourcePath &rtos_root_path/../../ambalink_sdk_4_x/linux
        PRINT "Select source path"
        SourcePathList

        wait.1s
        ;--- display symbol list
        SymbolList

        ;--- Open debug windows
        DebugList main

        ; go
        ```


# Burn-in F/w

- burn-in to NAND
    + CVD
        1. open CVD and board power on

        2. link cpu (need to press `GO`)
            > ~\rtos\tools\soc\CodeViser\Ambarella-H2\Ambarella_H2_CVD64.csf

        3. init DRAM with script (need to press `GO`)
            > ~\rtos\tools\soc\CodeViser\Ambarella-H2\Bin\Ambarella-H2-LPDDR3_H9CCNNN8GTMLAR_456MHz.csf

        4. Load `*elf` and write to NAND (need to press `GO`)
            > just load your `*.elf` file in ~/rots/output/out/fwprog64

    + USB tool
        1. Change mode with POC (pin[8] and pin[10] => high)

        2. Power on EVK and target burning F/W from USB tool

