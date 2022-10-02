ECC (Error Correction Code)
---

因為 Flash 中會有出錯的可能, 如果沒有使用 ECC, 讀出的資料和寫入的資料會有不匹配的可能, 也許一個檔案中只有一兩個bit不匹配, 這也是不能容忍的.
相對來說, 依出錯機率
> + SLC 出錯機率比較低, 所以使用一個糾錯能力不強的 `Hanming code` 即可
> + MLC 出錯機率相對高, 需要糾錯能力更強的 `RS (Reed-Solomon codes)` 或者 `BCH (Bose–Chaudhuri–Hocquenghem codes)`



+ RS(Reed-Solomon) 應用也非常廣泛, 按 multi-bits 的組合編碼, 而 BCH 按 bit 編碼,
    > 比如 Flash 中某個 byte 應該是 0x00, 但從 Flash 讀出卻是 0xF0
    > + `RS` 只認為出現了 **1** 個錯誤
    >> `RS` 有著不錯的突發隨機錯誤和隨機錯誤的能力
    > + `BCH` 卻認為出現了 **4** 個錯誤
    >> `BCH` 擅長處理隨機錯誤, 由於 Flash 自身的特點, 出現隨機錯誤的機率更大一些, 所以在 MLC 中應用最多的還是 BCH 方式



為能更正錯誤的 data, 需要額外的空間保存校驗資料
> 額外空間越多, 代表可以使用更正能力越強的 ECC.
>> 一般在 NAND Flash 中, Page 的 1KB 資料大多數是 `(1024＋32) Bytes`.



## BCH 演算法

通常以　`512-Bytes` 或者 `1024-Bytes` 的原始資料為單位處理, 並生成一定長度的校驗資料
> 因為 BCH 按 bit-field 處理資料, 所以是 `4096-bits` 或者 `8192-bits`

假設最大更正能力為 `t (可校驗 t bits 以內錯誤)`
> + 如果選用 **4096-bits (512-Bytes)** 的原始資料長度, 則模式為 `BCH(8191, 8191 - 13 * t, t, 13)`
> + 如果選用 **8192-bits (1024-Byte)** 的原始資料長度, 則模式為 `BCH(16383, 16383 - 14 * t, t, 14)`

校驗資料長度就是 `13*t` 或者 `14*t` bits.

+ 平均 `(1024 + 32) Bytes` 的 MLC, 大多建議使用 `8-bits/512-Bytes ECC` (每 512-Bytes 資料,　校驗 8-bits 以內錯誤)
    >  此時需要 `13*8*2 bits = 26-Bytes` 的校驗資料空間

    > 當寫資料到 NAND Flash 時, 每 **512Bytes** 資料經過 BCH 就會生成 `13-Bytes` 的校驗資料.
    當然剩下的 `16 - 13 = 3-Bytes` 也可以作為某種用途的資料 (可任意使用剩下的 3 Bytes 而不會影響 BCH 的使用）, 一起寫入到 NAND Flash 中.

    > Controller 從 NAND Flash中 讀取資料時, 需要將 **原始資料** 和 **校驗資料** 一起讀出並經過 BCH module, BCH module 計算伴隨矩陣, 可以先判斷出是否出現了錯誤.
    > + 如果出現了錯誤, 需要計算錯誤位置多項式, 然後解多項式, 得到錯誤的 bit order(目前主要使用 Chien-search 方法), 因為是 bit-field 錯誤, 找到錯誤的 bit-order 後, inverse 此 bit 就是正確的資料
    > + 只要是錯誤 bits 小於等於 8, BCH 都能夠找到錯誤的 bit-fields, 但是如果錯誤 bitt 超過了 8, 對於 BCH 來說已經超過更正範圍, 只能報告出現了無法更正的情況


+ 平均 `(1024 + 45) Bytes` 的 MLC, 大多建議使用 `24-bits/1024-Bytes ECC`
    > 此時需要 `14*24 bits = 42-Bytes` 的校驗資料空間


### MISC

+ BCH3121 => BCH(31, 21, 5) code
    > 31-bits 空間中, 21-bits 為原始資料, 可更正 5-bits 以內錯誤


## Reference

+ [The Error Correcting Codes (ECC) Page](http://www.eccpage.com/)
