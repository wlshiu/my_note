AES (Advanced Encryption Standard)
---


+ 特性
    > + A fixed block size of 128 bits
    > + A key size of 128, 192, or 256 bits

    - 加密過程中使用的 Keys 是由 [Rijndael's key schedule](https://en.wikipedia.org/wiki/AES_key_schedule) 產生


    - 一種區塊加密 (Block Cipher) 標準
        > 允許使用同一個區塊密碼 key 對超過一塊的資料進行加密, 並保證其安全性.
        區塊密碼自身**只能加密長度等於密碼區塊長度**的單塊資料, 若要加密變長資料, 則資料必須先被劃分為一些單獨的密碼塊


    - 一種對稱加密演算法 (Symmetric-key algorithm)
        > 這類演算法在加密和解密時使用相同的密鑰, 或是使用兩個可以簡單地相互推算的密鑰, 速度比公鑰加密快很多

+ Working Flow

    - Main-Flow
        > Use `4x4` bytes (128-Bits) matrix (a element is a byte)

        1. AddRoundKey
            > 矩陣中的每一個 byte 都與該次回合金鑰(Round Key) 做 `Bitwise XOR` 運算
            >> 每個 Sub-Key (Round-Key) 由 **Rijndael's key schedule** 產生.

            ```
            Round-Key[4x4] = KeySchedule(Key[4x4])

            TempText[4x4] = Plaintext[4x4] ^ Round-Key[4x4]     // XOR
            ```

        1. SubBytes
            > 透過一個非線性的替換函式 (S-box), 用查表的方式把每個 byte 替換成對應的 byte

            ```
            SubBytes[4x4] = S_Box(TempText[4x4])
            ```

        1. ShiftRows
            > 將矩陣中的每個 row 進行**左循環**式 element 位移 (left-cyclically shift).

            ```
            {
                [SubBytes(0, 0), SubBytes(0, 1), SubBytes(0, 2), SubBytes(0, 3)],
                [SubBytes(1, 0), SubBytes(1, 1), SubBytes(1, 2), SubBytes(1, 3)],
                [SubBytes(2, 0), SubBytes(2, 1), SubBytes(2, 2), SubBytes(2, 3)],
                [SubBytes(3, 0), SubBytes(3, 1), SubBytes(3, 2), SubBytes(3, 3)],
            }

            after ShiftRows:
            {
                [SubBytes(0, 0), SubBytes(0, 1), SubBytes(0, 2), SubBytes(0, 3)],
                [SubBytes(1, 1), SubBytes(1, 2), SubBytes(1, 3), SubBytes(1, 0)],
                [SubBytes(2, 2), SubBytes(2, 3), SubBytes(2, 0), SubBytes(2, 1)],
                [SubBytes(3, 3), SubBytes(3, 0), SubBytes(3, 1), SubBytes(3, 2)],
            }
            ```


        1. MixColumns
            > 為了充分混合矩陣中各個 Column 的操作. 這個步驟使用線性轉換來混合每行內的 4-bytes.
            最後一個加密迴圈中省略 MixColumns 步驟, 而以另一個 AddRoundKey 取代.

            ```
            Matrix multiplication

            C = 0 ~ 4

             |                |    |                  |   |                |
             | SubBytes'(0, C)|    | [02, 03, 01, 01] |   | SubBytes(0, C) |
             | SubBytes'(1, C)| =  | [01, 02, 03, 01] | * | SubBytes(1, C) |
             | SubBytes'(2, C)|    | [01, 01, 02, 03] |   | SubBytes(2, C) |
             | SubBytes'(3, C)|    | [03, 01, 01, 02] |   | SubBytes(3, C) |

            ```


    - Rounds (loop times)
        > + `10 rounds` for 128-bits keys.
        > + `12 rounds` for 192-bits keys.
        > + `14 rounds` for 256-bits keys.

# Definitions

+ Block
    > one fixed-length group of bits

+ Plaintext (明文)
    > 加密前的資料

+ Ciphertext or Cyphertext (密文)
    > 加密後的資料

+ Initialization-Vector (IV) or Starting-Variable (SV)
    > 將加密隨機化的一個 Block of Bits, 由此即使同樣的明文被多次加密也會產生不同的密文
    >> IV 通常無須保密, 然而在大多數情況中, **不應在使用相同 Key 的情況下, 重複使用同一個 IV**

+ Padding
    > Block Cipher 中, Key 和 Plaintext 長度必須對等 (128/192/256 bits),
    當 Plaintext 不足 alignment 時, 在尾部添加 Padding

    - 用 `0x80` 補齊, 並增加一個全為 `0` 的 Block
    - 或在最後一個 Block 補上 N 個值皆為 N 的 bytes

+ Sequential/Parallel
    > + Sequential 加密, 因與前一個 Plaintext Block 相關聯, 一旦有錯誤, 後續都會錯誤
    > + Parallel 加密, 每個 Block 都有其獨立性, 前面有錯誤時, 不會擴散到後面的 Blocks

+ Stream cipher (串流加密 or 資料流加密)
    > Encryption and Decryption 雙方使用相同 pseudo-random stream 作為 Key. <br>
    Plaintex stream 每次與 Key strem 對應的順序加密, 得到 Ciphertext stream

# Algorithm

## ECB (Electronic codebook)

The simplest of the encryption modes <br>

Plaintext 按照塊密碼的塊大小被分為數個塊, 並對每個塊進行獨立加密.<br>

+ Pros
    > 構造簡單, 容易實做

+ Cons
    > 缺點在於**同樣的 Plaintext Block 會被加密成相同的 Ciphertext Block**, 無法很好的隱藏資料


## CBC (Cipher-block chaining)

The most commonly used encryption modes <br>

每個 Plaintext Block 先與前一個 Ciphertext Block 進行 `XOR` 後, 再進行加密
> 每個 Ciphertext Block 都依賴於它前面的所有 Plaintext Block. 為了保證每條訊息的唯一性, 在第一個塊中需要使用 IV (Initialization-Vector)

+ Pros
    >　相同Plaintext, 會因為前一個的 Ciphertext 不同而產生出不同的 Ciphertext.

+ Cons
    > + 缺點在於加密過程是 sequential, 無法被併列化 (parallelized)
    >> Ciphertext 錯誤，會導致 Error propagation
    > + 第一次加密很容易被抽換 bitwise, 因為每次驅動的 Initial Vector 都相同

## CTR (Counter mode) or ICM mode (Integer Counter Mode) or SIC (Segmented Integer Counter)

引入一個 counter 來產生 Stream cipher (由 Key 及 counter 來產生 pseudo-random stream), 以保證任意長時間均不會產生重複輸出.
> 加密和解密時需要用到的 `counter` 值, 可以由 `Nonce` 和分組序號直接計算出來
>> `Nonce` (作用等同於 IV, 可視為 IV)

```
IV[127:0] = Nonce[95:0] + Counter[32-bits]
```

可以以**任意順序**對分組進行加密和解密, 支援 parallelized 處理

+ Pros

    - 加解密可以平行化處理, 如果加解密速度耗時, 可用多核心加速
    - 支持 Random access
    - 可不需要 Padding

+ Cons

    - 必須一直保持同步
    - 訊息被修改時, 不易被發現, 只單純影響單一 Plaintext
        > 沒有 Error propagation.

    - Initial Vector 不能重複使用, 否則很容易被攻擊者抓到

# Key Derivation Function (KDF)

KDF is a [cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function).

使用 Pseudo-Randomness 從  a main key, a password, or a passphrase 中衍生出一個或多個 Keys. <br>
> KDF可用於將 Key 擴充為更長的金鑰或取得所需格式的金鑰.

可以防止獲得衍生金鑰的攻擊者知道關於輸入秘密值或任何其他衍生金鑰的有用資訊.
KDF 還可用於確保衍生金鑰具有其他屬性, 例如避免某些特定加密系統中的 **弱金鑰**



