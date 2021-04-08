FreeRTOs Idle Task [[Back](note_freertos_guide.md)]
---


# tickless (low power)

+ vTaskStepTick
    > 每當只有 idle task 被執行時, 系統 Heartbeat (SysTick) 中斷將會停止, MCU 進入低功耗模式.
    當 MCU 退出低功耗後, 系統 Heartbeat (SysTick)必須被調整, vTaskStepTick() 用來將進入低功耗的時間補回給 RTOS.


    ```c
    void vTaskStepTick( TickType_txTicksToJump );
    ```

    - Example usage

        ```c
        /* 首先定義宏portSUPPRESS_TICKS_AND_SLEEP(). 宏參數指定要進入低功耗(睡眠)的時間, 單位是系統節拍週期. */
        #define portSUPPRESS_TICKS_AND_SLEEP( xIdleTime )   vApplicationSleep( xIdleTime )

        /* 定義被 portSUPPRESS_TICKS_AND_SLEEP() 調用的函數 */
        void vApplicationSleep(TickType_t xExpectedIdleTime )
        {
            unsigned long ulLowPowerTimeBeforeSleep, ulLowPowerTimeAfterSleep;

            /* 從時鐘源獲取當前時間, 當微控制器進入低功耗的時候, 這個時鐘源必須在運行 */
            ulLowPowerTimeBeforeSleep = ulGetExternalTime();

            /* 停止系統節拍時鐘中斷. */
            prvStopTickInterruptTimer();

            /* 配置一個中斷, 當指定的睡眠時間達到後, 將處理器從低功耗中喚醒.這個中斷源必須在微控制器進入低功耗時也可以工作.*/
            vSetWakeTimeInterrupt( xExpectedIdleTime );

            /*進入低功耗 */
            prvSleep();

            /*  確定微控制器進入低功耗模式持續的真正時間. 因為其它中斷也可能使得微處理器退出低功耗模式.
             *  注意：在調用宏 portSUPPRESS_TICKS_AND_SLEEP() 之前, 調度器應該被掛起, 
             *  portSUPPRESS_TICKS_AND_SLEEP() 返回後, 再將調度器恢復.
             *  因此, 這個函數未完成前, 不會執行其它任務. 
             */
            ulLowPowerTimeAfterSleep = ulGetExternalTime();

            /* 調整內核系統節拍計數器. */
            vTaskStepTick( ulLowPowerTimeAfterSleep – ulLowPowerTimeBeforeSleep );

            /*重新啟動系統節拍時鐘中斷.*/
            prvStartTickInterruptTimer();
        }        
        ```


# reference

+ [FreeRTOS高級篇11---空閒任務分析](https://freertos.blog.csdn.net/article/details/52061032)