Kernel-Module [[Back](note_LinuxDD.md##kernel-module)]
---

Kernel Module 是一段可以在 run-time 被載入到 Linux Kernel 中的程式碼, 它可以`運作在 kernel-space`
> 如果沒有使用 Kernel Module, 每修改 Kernel code, 或新增 Kernel 功能特性, 都需要重新編譯 Kernel, 大大浪費了時間和效率

Linux Kernel 的 framework 中, 對 hardware 與 driver 定義為 device, device_driver, 和 bus 物件
> 當某個 descriptor 包含 `struct device` 表示繼承了 device 屬性, 同樣地, 含有 `struct device_driver`, 亦表示繼承 device_driver 屬性,
含有 `struct bus`, 亦表示繼承 bus 屬性

+ device
    > A `hardware` of a SoC

+ device_driver
    > A `driver` of a hardware of a SoC

+ bus
    > 在 kernel 中定義的 `bus` 是抽象的物件 (與 Computer Architecture 中的 BUS 不同), 主要用來
    > + 描述與 device 溝通的模式, e.g. SPI-bus, USB-bus, PCI-bus, I2C-bus, ...etc.
    > + 選擇 device 所能使用的 drivers 版本
    >> 在 OS 中, driver 可能會有很多版本可選擇使用, 像是 OS 供應商(e.g. microsoft), Hardware vendor driver kits (e.g. CUDA-v1.0, CUDA-v2.0),

    - bus 上面會掛有很多的 drivers, 當有新的 driver 或 device 加入到 bus 上時, bus 必需幫 driver 跟 device 進行配對
        > 此配對稱作 `match`, 經由 device-tree 提供 hardware info

    - 配對成功後, 就會使用 `probe method` 來做 driver 的初始化


## [Device-Tree](../note_vg/linux/note_decive_tree.md)

+ [device-tree demo](./note_device_tree_demo.md)

## edu device (todo)



+ Reference
    - [EDU device — QEMU documentation](https://www.qemu.org/docs/master/specs/edu.html)
    - [QEMU EDU 设备驱动 | jklincn](https://jklincn.com/posts/qemu-edu-driver/)
        > [GitHub - jklincn/qemu\_edu\_driver: QEMU EDU Device Driver](https://github.com/jklincn/qemu_edu_driver)




# Reference

+ [iT 邦幫忙::我在核心裡面了！第一個核心模組](https://ithelp.ithome.com.tw/m/articles/10243519)
+ [iT 邦幫忙::使用 Device Tree 來找 Driver](https://ithelp.ithome.com.tw/m/articles/10244211)
