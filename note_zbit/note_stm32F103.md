STM32F103
---

# Windows

## CMSIS-DAP CDC

Windows 10 automatically install

+ Windows 7

    - Keil-MDK trigger automatically downloading Software Packs `Keil.STM32F1xx_DFP.2.3.0`

    - set output path
        > + `Options for target ` -> tab `Output` -> `Select Folder for Objects`
        > + `Options for target ` -> tab `Listing` -> `Select Folder for Listings ...`

    - set ICE protocol
        > `Options for target ` -> tab `Debug` -> use `CMSIS-DAP debugger`

    - set FLM
        > `Options for target ` -> tab `Utilities` -> `Settings` -> tab `Flash Download` -> Add

    - USB driver
        > `C:\Keil_v5\ARM\STLink\USBDriver`

        1. CMSIS_DAP_v2.inf
            > inf file (It may not be necessary)

            ```
            [Version]
            Signature = "$Windows NT$"
            Class     = USBDevice
            ClassGUID = {88BAE032-5A81-49f0-BC3D-A4FF138216D6}
            Provider  = %ManufacturerName%
            DriverVer = 04/13/2016, 1.0.0.0
            CatalogFile.nt      = CMSIS_DAP_v2_x86.cat
            CatalogFile.ntx86   = CMSIS_DAP_v2_x86.cat
            CatalogFile.ntamd64 = CMSIS_DAP_v2_amd64.cat

            ; ========== Manufacturer/Models sections ===========

            [Manufacturer]
            %ManufacturerName% = Devices, NTx86, NTamd64

            [Devices.NTx86]
            %DeviceName% = USB_Install, USB\VID_c251&PID_f000

            [Devices.NTamd64]
            %DeviceName% = USB_Install, USB\VID_c251&PID_f000

            ; ========== Class definition ===========

            [ClassInstall32]
            AddReg = ClassInstall_AddReg

            [ClassInstall_AddReg]
            HKR,,,,%ClassName%
            HKR,,NoInstallClass,,1
            HKR,,IconPath,0x10000,"%%SystemRoot%%\System32\setupapi.dll,-20"
            HKR,,LowerLogoVersion,,5.2

            ; =================== Installation ===================

            [USB_Install]
            Include = winusb.inf
            Needs   = WINUSB.NT

            [USB_Install.Services]
            Include = winusb.inf
            Needs   = WINUSB.NT.Services

            [USB_Install.HW]
            AddReg  = Dev_AddReg

            [Dev_AddReg]
            HKR,,DeviceInterfaceGUIDs,0x10000,"{CDB3B5AD-293B-4663-AA36-1AAE46463776}"

            ; =================== Strings ===================

            [Strings]
            ClassName        = "Universal Serial Bus devices"
            ManufacturerName = "KEIL - Tools By ARM"
            DeviceName       = "CMSIS-DAP v2"
            ```




