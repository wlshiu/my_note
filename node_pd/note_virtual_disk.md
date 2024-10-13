Virtual Disk
---

# Ubuntu

+ `dd` command
    > Data-Duplicator 可以製作映像檔 (e.g. iso, img, ...etc)

    ```
    # create image file with 128MB ('0x0' full all image file)
    $ dd if=/dev/zero of=a9rootfs.ext3 bs=1M count=128
    ```

    - `if=FILE`
        > 指定輸入檔案名稱(Input File) 為 FILE
    - `of=FILE`
        > 指定輸出檔案名稱(Output File) 為 FILE

    - `bs=BYTES`
        > 指定 `Block Size`, 一次讀取與寫入 BYTES 位元組的資料
        >> 此選項會覆蓋 `ibs` 與 `obs` 的設定

    - `count=N`
        > 只處理 N 個輸入 Block, 每個 Block 的大小為 ibs or bs


+ `mkfs` command
    > `mkfs` is used to create a filesystem on a device or in an image file
    >> 在執行 `mkfs` 前, 必須確定 disk or image-file 已經被 unmount

    ```
    mkfs [options] [-t type fs-options] device [size]

    * device: 想要格式化的裝置
    * size: 裝置的大小
    * options:
        '-t': 指定要建立的檔案系統類型, e.g. ext2, ext3, ext4, vfat
        '-V': 顯示詳細資訊
        '-l': 讀取壞塊列表
        '-v': 顯示版本資訊
    ```

    - 也可以直接使用 `mkfs.<file-system-type>`

        ```
        mkfs.ext2    mkfs.ext4    mkfs.minix   mkfs.ntfs
        mkfs         mkfs.cramfs  mkfs.ext3    mkfs.fat     mkfs.msdos   mkfs.vfat
        ```

    - examples

        1. 對 image file 格式化為 ext3 file-system

            ```
            $ mkfs.ext3 a9rootfs.ext3
                or
            $ mkfs -t ext3 a9rootfs.ext3
            ```

        1. 格式化為 FAT16
            > FAT12/FAT16 時, 需考慮其所支援的最大容量, 否則可能會出錯

            ```
            $ mkfs.vfat -F 16 img.fat16
            ```

+ `mount/umount ` command
    > 掛載 devicd or image file 到指定目錄

    ```
    mount <-t filesystem-type> <device> <dir>
    mount <-t filesystem-type> <image-file> <dir> <-o loop>
    ```

    - examples

        ```
        # 掛載 image file 到 ./my_test 目錄下
        $ mkdir -p ./my_test
        $ chmod 777 ./my_test

        # '-o loop' 掛載為 loop device
        # ps. The loop device can create the virtual block device from a file (character device)
        $ mount -t ext3 a9rootfs.ext3 ./my_test -o loop
            or
        $ mount -t vfat img.fat16 ./my_test -o loop

        $ umount ./my_test
        ```

+ Reference

    - [dd 指令教學與實用範例，備份與回復資料的小工具 – G. T. Wang](https://blog.gtwang.org/linux/dd-command-examples/)

