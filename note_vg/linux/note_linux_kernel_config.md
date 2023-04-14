linux kernel config
---




## `Initramfs`

將 `rootfs` 一併包進 image, 當 boot 時會將 rootfs 複製到 DRAM
> `Initramfs`只支援 read-only mode

一旦執行 rootfs 裡的 init, kernel 就會認為 boot 已經完成, 接下來 init 將接手掌控整個系統
> kernel 專門為 init 預留 `Process ID #1`
>> 如果 `PID 1` 退出的話, 系統會 panic

```
General setup ->
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
    (./usr/image)    Initramfs source file(s)                   <-- rootfs.bin 在 Host 的 path
    [*]   Support initial ramdisk/ramfs compressed using gzip   <-- support input format of initramfs
    [*]   Support initial ramdisk/ramfs compressed using bzip2
    [*]   Support initial ramdisk/ramfs compressed using LZMA
    [*]   Support initial ramdisk/ramfs compressed using XZ
    [*]   Support initial ramdisk/ramfs compressed using LZO
    [*]   Support initial ramdisk/ramfs compressed using LZ4
```

```
Executable file formats ->
    [*] Kernel support for ELF binaries
```

+ External-rootfs vs Initramfs
    > External rootfs 是在 built-in initramfs 之後執行, 如果兩個檔案包含有相同名稱的內容, External rootfs 會覆蓋掉 built-in 時填進去的資料
    >> 這表示不用修改 kernel, 就可以 update 或是 customize rootfs, 而不用更換 kernel

+ license issue
    > 可以在 rootfs 裡面運行 non-GPL program 或是 driver module
    >> 製作 initramfs, 只是算是使用, 不算修改 kernel, 可以 non-open source code



## Floating point

ARM VFP (Vector Floating Point) 為半精度, 單精度和雙精度中的浮點操作, 提供硬體支援
> 它完全符合 `IEEE 754` 標準, 並提供完全 S/w 支援

+ 使用 H/w support

    ```
    Floating point emulation  --->
    [*] VFP-format floating point maths
    ```





