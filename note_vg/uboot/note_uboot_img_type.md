uboot image type [[Back](note_uboot_quick_start.md)]
---

隨著 kernel 在 ARM 架構中引入 device tree(全稱是flattened device tree, 後續將會以FDT代稱)的時候,
其實懷著一個 Unify Kernel 的夢想(同一個 Image, 可以支持多個不同的平台).
隨著新的 ARM64 架構將 FDT 列為必選項, 並將和體系結構有關的代碼剝離之後, 這個夢想已經接近實現:

> 在編譯 linux kernel 的時候, 不必特意的指定具體的架構和 SOC,
只需要告訴 kernel 本次編譯需要支持哪些板級的 platform 即可,
最終將會生成一個 Kernel image, 以及多個和具體的板子(哪個架構, 哪個SOC, 哪個版型)有關的 FDT image(dtb文件).

> uboot 在啟動的時候, 根據硬件環境, 加載不同的dtb文件,
即可使 linux kernel 運行在不同的硬件平台上, 從而達到 unify kernel 的目標.


# Legacy uImage

uboot 要 boot 一個 binary raw data, 因此需要獲得該文件的一些信息
> + 文件的類型, 如 kernel image, dtb file, ramdisk image, ...等等
> + 該文件需要放在 memory 的哪個位置(加載地址)
> + 該文件需要從 memory 哪個位置開始執行(執行地址)
> + 該文件是否有壓縮
> + 該文件是否有一些完整性校驗的信息(如CRC)

因此 u-boot 自定義了一種 uImage 格式.
其格式比較簡單, 就是為二進制文件加上一個header(具體可參考"include/image.h"中的定義), 標示該文件的特性.

然後在 boot 該類型的 Image 時, 從header中讀取所需的信息, 按照指示, 進行相應的動作即可.

這種原始的 Image 格式, 稱作 `Legacy uImage`

# FIT uImage

為達到 Unify kernel 的理想, 需要 uboot 的協助, 因而有幾個需求:
> + Image 中需要包含多個 dtb 文件
> + 可以方便的選擇使用哪個 dtb 文件 boot kernel

綜合上面的需求, 推出了一種新的格式 `FIT uImage` (Flattened Image Tree).
利用了 Device Tree Source files (DTS) 的語法,
生成的 image 文件 (itb) 也和 dtb 文件類似.

```
                        mkimage + dtc                  xfr to address
image source file   -------------------> target file ----------------> bootm execute
    +
image data files
```

其中 image source file(.its) 和 device tree source file(.dts) 類似, 負責描述要生成的 target file 的信息.
mkimage 和 dtc 工具, 可以將`.its`文件以及對應的 `image data fil`e, 打包成 target file.
再將 target file 下載到麼 memory 中, 使用 bootm 執行

## syntax of Image Sourece File

multi.its 中的包含了 3 個 kernel image,
2 個 ramdisk image,
2 個 fdt image.
每個文件都是 images 下的一個子 node

```
/* At u-boot/doc/uImage.FIT/multi.its */
/dts-v1/;

/ {
	description = "Various kernels, ramdisks and FDT blobs";
	#address-cells = <1>;

	images {
		kernel@1 {
			description = "vanilla-2.6.23";
			data = /incbin/("./vmlinux.bin.gz");
			type = "kernel";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "md5";
			};
			hash@2 {
				algo = "sha1";
			};
		};

		kernel@2 {
			description = "2.6.23-denx";
			data = /incbin/("./2.6.23-denx.bin.gz");
			type = "kernel";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "sha1";
			};
		};

		kernel@3 {
			description = "2.4.25-denx";
			data = /incbin/("./2.4.25-denx.bin.gz");
			type = "kernel";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "md5";
			};
		};

		ramdisk@1 {
			description = "eldk-4.2-ramdisk";
			data = /incbin/("./eldk-4.2-ramdisk");
			type = "ramdisk";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "sha1";
			};
		};

		ramdisk@2 {
			description = "eldk-3.1-ramdisk";
			data = /incbin/("./eldk-3.1-ramdisk");
			type = "ramdisk";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "crc32";
			};
		};

		fdt@1 {
			description = "tqm5200-fdt";
			data = /incbin/("./tqm5200.dtb");
			type = "flat_dt";
			arch = "ppc";
			compression = "none";
			hash@1 {
				algo = "crc32";
			};
		};

		fdt@2 {
			description = "tqm5200s-fdt";
			data = /incbin/("./tqm5200s.dtb");
			type = "flat_dt";
			arch = "ppc";
			compression = "none";
			load = <00700000>;
			hash@1 {
				algo = "sha1";
			};
		};

	};

	configurations {
		default = "config@1";

		config@1 {
			description = "tqm5200 vanilla-2.6.23 configuration";
			kernel = "kernel@1";
			ramdisk = "ramdisk@1";
			fdt = "fdt@1";
		};

		config@2 {
			description = "tqm5200s denx-2.6.23 configuration";
			kernel = "kernel@2";
			ramdisk = "ramdisk@1";
			fdt = "fdt@2";
		};

		config@3 {
			description = "tqm5200s denx-2.4.25 configuration";
			kernel = "kernel@3";
			ramdisk = "ramdisk@2";
		};
	};
};
```

+ key words
    - `description`
        > 可以隨便寫

    - `data`
        > binary 的路徑

        ```
        data = /incbin/("path/to/data/file.bin")
        ```

    - `type`
        > binary 的類型, `kernel`, `ramdisk`, `flat_dt`等, 具體可參考中[uImage.FIT]的介紹.

    - `arch`
        > 平台類型, `arm`, `i386`等, 具體可參考中[uImage.FIT]的介紹.

    - `os`
        > OS 類型, linux, vxworks等, 具體可參考中[uImage.FIT]的介紹.

    - `compression`
        > binary 的壓縮格式, u-boot 會按照執行的格式解壓.

    - `load`
        > binary 的加載位置, u-boot 會把它 copy 對應的 address 上.

    - `entry`
        > binary 入口地址, 一般 kernel Image 需要提供, u-boot 會跳轉到該地址上執行.

    - `hash`
        > 使用的數據校驗算法.


+ configurations node
    > 包含了  3種配置, 每種配置使用了不同的 kernel, ramdisk 和 fdt,
    默認配置項由`default`指定, 當然也可以在運行時指定

    ```
	configurations {
		default = "config@1";

		config@1 {
			description = "tqm5200 vanilla-2.6.23 configuration";
			kernel = "kernel@1";
			ramdisk = "ramdisk@1";
			fdt = "fdt@1";
		};

		config@2 {
			description = "tqm5200s denx-2.6.23 configuration";
			kernel = "kernel@2";
			ramdisk = "ramdisk@1";
			fdt = "fdt@2";
		};

		config@3 {
			description = "tqm5200s denx-2.4.25 configuration";
			kernel = "kernel@3";
			ramdisk = "ramdisk@2";
		};
	};
    ```

+ generate FIT-uImage

    ```
    # image source file 為 kernel_fdt.its
    $ u-boot/tools/mkimage -f kernel_fdt.its kernel_fdt.itb

    # 查看 itb 信息
    $ u-boot/tools/mkimage -l kernel.itb
    ```

+ run
    > 將生成的`.idb`文件, 下載到 memory 的某個地址(e.g. 0x100000), 然後使用 bootm 啟動

    ```
    => bootm 0x100000
        or
    => bootm 0x100000#config@2
    ```

# reference

+ [u-boot FIT image介紹](http://www.wowotech.net/u-boot/fit_image_overview.html)
+ [uImage.FIT](https://github.com/wowotechX/u-boot/blob/x_integration/doc/uImage.FIT/source_file_format.txt)
