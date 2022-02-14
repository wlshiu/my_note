Iinterview
---


# Concept of Program

## 評價 code 優劣或錯誤


+ Interrupt
    > 解釋原因

    ```c
    int input_handler(volatile int a)
    {
        return a + a;
    }

    __irq int uart_isr(float a)
    {
        int     err_code = 0;
        float   value = 0.0f;

        mutex_lock();

        value = a * a;
        value = input_handler(value);
        printf("result = %d\n", value);

        mutex_unlock();

        return err_code;
    }
    ```

    - ISR 不會有 `input parameters` 也不會有 `回傳值`
    - ISR 不可使用 mutex
        1. system call 會造成 dead lock

    - ISR 避免使用 float operate
        1. 有些 CPU 使用 S/w float 會很慢

    - ISR 不可使用 printf
        1.

    - `input_handler`
        > input 參數為 volatile 時, 應先預存, 否則 real-time `a + a` 操作時, `a` 會有不同的值

        1. 更正程式

            ```
            int input_handler(volatile int a)
            {
                int     b = a;
                return b + b;
            }
            ```

+ Coding style

    - 假設 <br>
        uart control register 為 0x40000000 (其中 bit[1] 為 enable)<br>
        uart data register 為 0x40000004 (bit[7:0]) <br>
        請簡略試寫 `send_byte()` <br>
        ps. 略過 buadrate 等其他複雜設定

        ```c
        #define SET_BIT(pVal, bit_order)        ((*(volatile uint32_t*)(pVal)) |= (0x1ul << (bit_order)))
        #define CLR_BIT(pVal, bit_order)        ((*(volatile uint32_t*)(pVal)) &= ~(0x1ul << (bit_order)))
        #define SET_REG(addr, value)            (*(volatile uint32_t*)(addr) = (value))
        #define SET_REG_Msk(addr, msk, value)   (*(volatile uint32_t*)(addr) = (*(volatile uint32_t*)(addr) & ~(msk)) | ((value) & (msk)))

        #define REG_UART_CR                     0x40000000ul
        #define REG_UART_ENABLE_Pos             1

        #define REG_UART_DATA                   0x40000004ul

        int send_byte(void)
        {
            SET_REG_Msk(REG_UART_DATA, 0xFF, 'a');
            SET_BIT(REG_UART_CR, REG_UART_ENABLE_Pos);
            return 0;
        }
        ```

        1. 是否會 bit control
            > + set bit
            > + clear bit
            > + set with mask

        1. 是否會對 register address 使用 volatile

        1. 是否會考慮可讀性
            > + 使用 define 來取代數字
            > + 使用 macro 來表示操作
            > + 使用 mask 來保護

        1. 是否會注意流程
            > set data 後才 enable

        1. 解釋這樣寫的原因

## 版控觀念

+ Git

# 解決問題的態度

## 遇到問題時會如何做

+ 假設分配到過往沒做過的任務

    - 網路找資源
        1. 找 spec 或 paper
        1. 找論壇
            > + stack overflow

        1. 找有做過的 vendor 所提供的文件或 SDK
            > + github/gitlab

    - 找 Degital Designer 討論

+ 假設客戶回報問題

    - 確認版本 (e.g. IC type, SDK, Board)
    - 確認是否能複製問題
    - 檢查 control flow
        1. 是否有流程順序錯誤
        1. 是否有執行到 code
            > + compile options 設定
            > + 判斷式是否正確 (if else)
        1. 是否有被 block 住
    - 檢查 Regitsters 設定是否正確
    - 檢查 signal 是否正確

## 舉出自身過往例子


