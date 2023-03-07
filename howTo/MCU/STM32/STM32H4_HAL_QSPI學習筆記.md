[STM32H4_HAL_QSPI 學習筆記](https://www.cnblogs.com/rongjiangwei/p/15686253.html)
---

說明：
QSPI的記憶體對應模式, 自動查詢模式和間接模式.

間接模式就是相對於記憶體對應時, 可以是匯流排直接訪問來說的.


## 驅動如何使用

+ 底層初始化HAL_QSPI_MspInit.
    - `__HAL_RCC_QSPI_CLK_ENABLE`
    - `__HAL_RCC_QSPI_FORCE_RESET()` 配合 `__HAL_RCC_QSPI_RELEASE_RESET()` 可 reset QSPI
    - `__HAL_RCC_GPIOx_CLK_ENABLE`
    - HAL_GPIO_Init 組態復用模式
    - 如果使用中斷模式, 呼叫函數 HAL_NVIC_SetPriority() 和 HAL_NVIC_EnableIRQ() 設定
    - 使用DMA傳輸時, 用的是MDMA,
        > + `__HAL_RCC_MDMA_CLK_ENABLE`
        > + `HAL_MDMA_Init`
        > + `__HAL_LINKDMA`

        > 如果需要中斷處理, 需要組態NVIC
        > + HAL_NVIC_SetPriority
        > + HAL_NVIC_EnableIRQ
        > + SDMMC 的中斷使能和禁止函數`__HAL_SD_ENABLE_IT`, `__HAL_SD_DISABLE_IT`
        > + 中斷標誌位處理 `__HAL_SD_GET_IT和__HAL_SD_CLEAR_IT`
        > + SDMCC 不需要通用的DMA, 因為內部自帶一個DMA.

    - 函數 HAL_QSPI_Init 組態 flash大小, 時鐘分頻, fifo閥值, 時鐘模式, 採樣偏移, CS高電平時間.

+ 間接模式
    - 函數 HAL_QSPI_Command 或者 HAL_QSPI_Command_IT 組態命令時序
        1. 這幾個階段都是可以組態是否使用的.
        1. 指令階段.
        1. 地址階段.
        1. 可選位元組階段.
        1. 空週期階段.
        1. 資料階段.
            > + DDR模式組態, 時鐘的上升沿和下降沿均可做資料收發.
            > + Sending Instruction Only Once (SIOO)模式組態, 這種模式傳送一次指令後,
            就可以方便的做讀寫操作, 不過需要外部Flash支援這種模式才行.

    - 如果命令不需要資料, 則將其直接傳送到記憶體：
        1. 在輪詢模式下, 輸出功能在傳輸完成時完成.
        1. 在中斷模式下, 傳輸完成後將呼叫HAL_QSPI_CmdCpltCallback.

    - 間接模式寫操作可以呼叫  HAL_QSPI_Transmit(), HAL_QSPI_Transmit_DMA() 或者 HAL_QSPI_Transmit_IT()
        1. 在輪詢模式下, 寫操作在傳輸完成時完成.
        1. 在中斷模式, 達到FIFO閥值的時呼叫回呼函數 HAL_QSPI_FifoThresholdCallback, 傳輸完成的時候, 呼叫回呼函數 HAL_QSPI_TxCpltCallback.
        1. 在DMA模式, 半傳輸完成的時候呼叫回呼函數 HAL_QSPI_TxHalfCpltCallback, 而全部傳輸完成的時候,呼叫回呼函數 HAL_QSPI_TxCpltCallback

    - 間接模式讀操作可以呼叫HAL_QSPI_Receive(), HAL_QSPI_Receive_DMA() 或者 HAL_QSPI_Receive_IT()
        1. 在輪詢模式下, 讀操作在傳輸完成時完成.
        1. 在中斷模式, 達到FIFO閥值的時呼叫回呼函數 HAL_QSPI_FifoThresholdCallback, 傳輸完成的時候,呼叫回呼函數 HAL_QSPI_RxCpltCallback.
        1. 在DMA模式, 半傳輸完成的時候呼叫回呼函數 HAL_QSPI_RxHalfCpltCallback, 而全部傳輸完成的時候,呼叫回呼函數 HAL_QSPI_RxCpltCallback.

+ 自動查詢模式
    - 函數HAL_QSPI_AutoPolling() 或者 HAL_QSPI_AutoPolling_IT() 組態時序
        1. 這幾個階段都是可以組態是否使用的.
        1. 指令階段.
        1. 地址階段.
        1. 可選位元組階段.
        1. 空週期階段.
        1. 資料階段.
        1. Sending Instruction Only Once (SIOO)模式組態, 這種模式傳送一次指令後, 就可以方便的做讀寫操作, 不過需要外部Flash支援這種模式才行.
        1. 狀態位元組的大小, 匹配值, 使用的掩碼, 匹配模式(OR / AND), 輪詢間隔和啟動自動停止.

    - 組態完成後
        1. 在輪詢模式下, 寫操作在達到狀態匹配時完成, 同時啟動自動停止以避免無限循環.
        1. 在中斷模式下, 每次狀態匹配時都會呼叫 HAL_QSPI_StatusMatchCallback().

+ 記憶體對應模式
    - 函數 HAL_QSPI_MemoryMapped 組態命令時序和記憶體對應
        1. 這幾個階段都是可以組態是否使用的.
        1. 指令階段.
        1. 地址階段.
        1. 可選位元組階段.
        1. 空週期階段.
        1. 資料階段.
        1. DR模式組態, 時鐘的上升沿和下降沿均可做資料收發.
        1. Sending Instruction Only Once (SIOO)模式組態, 這種模式傳送一次指令後, 就可以方便的做讀寫操作, 不過需要外部Flash支援這種模式才行.
        1. 超時啟動和超時時間.
    - 組態完成後, 只要地址範圍內的AHB匯流排訪問完成, 就會使用 QuadSPI. 超時到期時將呼叫 HAL_QSPI_TimeOutCallback().

+ 錯誤管理和終止功能
    1. HAL_QSPI_GetError() 函數給出上一次操作期間引發的錯誤.
    1. HAL_QSPI_Abort() 和 HAL_QSPI_AbortIT() 函數中止任何正在進行的操作並刷新fifo
        > + 在輪詢模式下, 當傳輸完成位被置位, 忙位清零時, 寫操作完成.
        > + 在中斷模式下, 當傳輸完成位被置位時, 回呼函數 HAL_QSPI_AbortCpltCallback() 將被呼叫.

+ 控制和狀態獲取功能
    - HAL_QSPI_GetState() 用於獲取當前的驅動狀態.
    - HAL_QSPI_SetTimeout() 組態溢出時間.
    - HAL_QSPI_SetFifoThreshold() 組態FIFO的閥值.
    - HAL_QSPI_GetFifoThreshold() 給出當前的FIFO閥值.

+ QSPI的一個勘誤處理：
     在讀傳輸結束時寫入FIFO的額外資料


## API

```c
/* 初始化和復位初始化 */
HAL_StatusTypeDef HAL_QSPI_Init     (QSPI_HandleTypeDef *hqspi);
HAL_StatusTypeDef HAL_QSPI_DeInit   (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_MspInit  (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_MspDeInit(QSPI_HandleTypeDef *hqspi);

/* QSPI IRQ */
void              HAL_QSPI_IRQHandler(QSPI_HandleTypeDef *hqspi);

/* QSPI 間接模式 */
HAL_StatusTypeDef HAL_QSPI_Command      (QSPI_HandleTypeDef *hqspi, QSPI_CommandTypeDef *cmd, uint32_t Timeout);
HAL_StatusTypeDef HAL_QSPI_Transmit     (QSPI_HandleTypeDef *hqspi, uint8_t *pData, uint32_t Timeout);
HAL_StatusTypeDef HAL_QSPI_Receive      (QSPI_HandleTypeDef *hqspi, uint8_t *pData, uint32_t Timeout);
HAL_StatusTypeDef HAL_QSPI_Command_IT   (QSPI_HandleTypeDef *hqspi, QSPI_CommandTypeDef *cmd);
HAL_StatusTypeDef HAL_QSPI_Transmit_IT  (QSPI_HandleTypeDef *hqspi, uint8_t *pData);
HAL_StatusTypeDef HAL_QSPI_Receive_IT   (QSPI_HandleTypeDef *hqspi, uint8_t *pData);
HAL_StatusTypeDef HAL_QSPI_Transmit_DMA (QSPI_HandleTypeDef *hqspi, uint8_t *pData);
HAL_StatusTypeDef HAL_QSPI_Receive_DMA  (QSPI_HandleTypeDef *hqspi, uint8_t *pData);

/* QSPI 狀態標誌查詢模式 */
HAL_StatusTypeDef HAL_QSPI_AutoPolling   (QSPI_HandleTypeDef *hqspi, QSPI_CommandTypeDef *cmd, QSPI_AutoPollingTypeDef *cfg, uint32_t Timeout);
HAL_StatusTypeDef HAL_QSPI_AutoPolling_IT(QSPI_HandleTypeDef *hqspi, QSPI_CommandTypeDef *cmd, QSPI_AutoPollingTypeDef *cfg);

/* QSPI 記憶體對應模式 */
HAL_StatusTypeDef HAL_QSPI_MemoryMapped(QSPI_HandleTypeDef *hqspi, QSPI_CommandTypeDef *cmd, QSPI_MemoryMappedTypeDef *cfg);

/* 非阻塞回呼函數 */
void              HAL_QSPI_ErrorCallback        (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_AbortCpltCallback    (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_FifoThresholdCallback(QSPI_HandleTypeDef *hqspi);

/* QSPI 間接模式 */
void              HAL_QSPI_CmdCpltCallback      (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_RxCpltCallback       (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_TxCpltCallback       (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_RxHalfCpltCallback   (QSPI_HandleTypeDef *hqspi);
void              HAL_QSPI_TxHalfCpltCallback   (QSPI_HandleTypeDef *hqspi);

/* QSPI 狀態標誌查詢模式 */
void              HAL_QSPI_StatusMatchCallback  (QSPI_HandleTypeDef *hqspi);

/* QSPI 記憶體對應模式 */
void              HAL_QSPI_TimeOutCallback      (QSPI_HandleTypeDef *hqspi);

/* 外設控制和狀態函數 */
HAL_QSPI_StateTypeDef HAL_QSPI_GetState        (QSPI_HandleTypeDef *hqspi);
uint32_t              HAL_QSPI_GetError        (QSPI_HandleTypeDef *hqspi);
HAL_StatusTypeDef     HAL_QSPI_Abort           (QSPI_HandleTypeDef *hqspi);
HAL_StatusTypeDef     HAL_QSPI_Abort_IT        (QSPI_HandleTypeDef *hqspi);
void                  HAL_QSPI_SetTimeout      (QSPI_HandleTypeDef *hqspi, uint32_t Timeout);
HAL_StatusTypeDef     HAL_QSPI_SetFifoThreshold(QSPI_HandleTypeDef *hqspi, uint32_t Threshold);
```
