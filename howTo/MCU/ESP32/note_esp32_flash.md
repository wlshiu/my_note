ESP32 Flash
----

Flash 內容使用 AES-256 加密, Key 存放在 eFuse (**UID 同樣也存放在 eFuse**)
> 默認情況下, **F/w 無法對 eFuse 讀寫**

Flash 加密功能, 是用於加密外部 SPI Flash 中的內容
> 啟用 flash 加密功能後，F/w 會**以明文形式燒錄**, 然後在**首次啟動時將資料進行加密**

因此物理讀取 flash 將無法恢復大部分 flash 內容

啟用 flash 加密後, 系統將默認加密下列類型的 flash 資料
> + F/w 引導載入程序
> + 分區表
> + 所有 **app** 類型的分區
> + 在分區表中標有**加密**標誌的分區
> + 如果啟用了安全啟動, 則可以加密安全啟動啟動載入器摘要
>> **安全啟動**是一個獨立的功能, 可以與 flash 加密一起使用, 從而建立更安全的環境

+ 名詞定義

    - ROM-Code (BootCode)
        > bootloader in ROM

    - SPL (Secondary Program Loader)
        > F/w bootloader

# Flash Encryption Process

+ SPL 開啟支援 Flash-Encryption, 並使用`明文燒錄 img file`

+ 第一次上電復位時, flash 中的所有資料都是明文, 同時 ROM-Code 載入 SPL

+ SPL 將讀取 `eFuse[FLASH_CRYPT_CNT]` 值, 因為該值為 0(偶數個 bits 被設定), SPL 將 configure 並啟用 Flash-Encryption-Block, 同時將 `eFuse[FLASH_CRYPT_CONFIG]` 的值設為 0xF
    > 關於 Flash Encryption Block 的更多資訊, 請參考 ESP32 技術參考手冊 -> eFuse 控製器(eFuse) -> flash 加密塊

+ SPL 使用 RNG 生成 AES-256 bits Key, 然後將其寫入 `flash_encryption` eFuse 中.
    > 由於 `flash_encryption` eFuse 已設定 Read/Write protection bits, S/w 將無法訪問 Key
    >> flash 加密操作完全在 H/w 中完成

+ Flash-Encryption-Block 將加密 flash 的內容
    > SPL, app, 以及標有 `encrypted` tag 的分區
    >> 就地加密可能會耗些時間, 對於大分區最多需要一分鐘

+ SPL 將在 `eFuse[FLASH_CRYPT_CNT]` 中設定第一個可用 bit, 來對已加密的 flash 內容進行標記 (奇數個 bits 被設定)

+ 在開發階段, 常需編寫不同的明文 flash img 並測試 flash 的加密過程. 這要求 F/w Download mode 能夠根據需求, 不斷載入新的明文 img,
    但在製造和生產過程中, 出於安全考慮, F/w Download mode 不應有權限訪問 flash 內容, 因此需要有兩種不同的 flash 加密組態：
    > + Development mode 用於開發
    > + Release mode 用於生產

    - 對於 [Development mode](#Development-mode), SPL 僅設定 `eFuse[DISABLE_DL_DECRYPT]` 和 `eFuse[DISABLE_DL_CACHE]` 為 1, 以便 UART burner 重新燒錄 Encrypted-BINs
        > 此時 `eFuse[FLASH_CRYPT_CNT]` 是 unlocked

    - 對於 [Release mode](#Release-mode), SPL 設定 `eFuse[DISABLE_DL_ENCRYPT]`, `eFuse[DISABLE_DL_DECRYPT]` 和 `eFuse[DISABLE_DL_CACHE]` 為 1, 以防止 UART burner 解密 flash 內容
        > 此時 `eFuse[FLASH_CRYPT_CNT]` 是 locked (要修改此行為, 請參閱 `Enabling UART Bootloader Encryption/Decryption`)

+ 重新 reboot device 以開始執行加密 img data
    > SPL 呼叫 Flash-Decryption-Block 來解密 flash 內容, 然後將解密的內容, 載入到 IRAM 中

# Flash Encryption Configuration

+ [Development mode](#Development-mode)
    > 用於開發過程, 在此模式下，仍然可以將新的 img(明文) 燒錄到 device 中, 並且 bootloader 將使用儲存在 H/w 中的 Key 對該 img 進行透明加密
    >> 此操作間接允許從 flash 中讀出 img 明文

+ [Release mode](#Release-mode)
    >  用於製造和生產, 在此模式下, 如果**不知道加密 Key, 則不能將 img (明文) 燒錄到 device 中**

## Development mode

## Release mode

# Advanced Features

## 加密分區 (Encrypted Partition)

## Enabling UART Bootloader Encryption/Decryption



# Reference

+ [flash 加密](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/security/flash-encryption.html)
+ [啟用 UART 引導載入程序加密/解密](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/security/flash-encryption.html#uart-bootloader-encryption)
+ [安全 Q&A](https://espressif-docs.readthedocs-hosted.com/projects/espressif-esp-faq/zh_CN/latest/software-framework/security.html)
