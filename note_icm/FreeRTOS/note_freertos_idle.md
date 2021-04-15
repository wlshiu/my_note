FreeRTOs Idle Task [[Back](note_freertos_guide.md)]
---

+ Idle Task

    ```c
    static portTASK_FUNCTION( prvIdleTask, pvParameters )
    {
        ( void ) pvParameters;//防止報錯

        portTASK_CALLS_SECURE_FUNCTIONS();

        for( ;; )
        {
            /* 進入空閒任務後會不停的查看是否有任務需要刪除, 在這個函數內進行刪除 */
            prvCheckTasksWaitingTermination();

            #if ( configUSE_PREEMPTION == 0 )
            {
                /* 如果沒有使用搶佔, 會不停的強制一次任務切換查看是否有其他任務需要執行
                   使用了搶佔的話就不需要這一步了, 因為有高優先級任務就緒後會自動搶佔 */
                taskYIELD();
            }
            #endif

            /* 如果使能了搶佔並使能時間片調度的話執行這個分支 */
            #if ( ( configUSE_PREEMPTION == 1 ) && ( configIDLE_SHOULD_YIELD == 1 ) )
            {
                /* 查看除了空閒任務以外同等優先級下有沒有任務等待執行,
                   有的話將時間片剩餘的時間讓給同優先級的就緒任務 */
                if( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ tskIDLE_PRIORITY ] ) ) > ( UBaseType_t ) 1 )
                {
                    taskYIELD();
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
            #endif

            /* 定義了這個宏的話, 當進入空閒任務時就會執行下面這個鉤子函數 */
            #if ( configUSE_IDLE_HOOK == 1 )
            {
                /* 這個鉤子函數由用戶自己定義使用, 可做一些低功耗處理,
                   但是一般建議使用 tickless 來做低功耗操作 */
                extern void vApplicationIdleHook( void );
                vApplicationIdleHook();
            }
            #endif

            /* 當使能這個宏時就使能低功耗 tickless 模式 */
            #if ( configUSE_TICKLESS_IDLE != 0 )
            {
                TickType_t xExpectedIdleTime;

                /* 獲取下一個任務的解鎖時間(即進入低功耗模式的時長) */
                xExpectedIdleTime = prvGetExpectedIdleTime();

                /* 下一個任務的解鎖時間, 必須大於用戶定義的最小空閒休眠時間閾值, 否則不休眠 */
                if( xExpectedIdleTime >= configEXPECTED_IDLE_TIME_BEFORE_SLEEP )
                {
                    /* 掛起任務調度器 */
                    vTaskSuspendAll();
                    {
                        configASSERT( xNextTaskUnblockTime >= xTickCount );
                        /* 重新採集一次時間值, 這次的時間值可以使用 */
                        xExpectedIdleTime = prvGetExpectedIdleTime();

                        configPRE_SUPPRESS_TICKS_AND_SLEEP_PROCESSING( xExpectedIdleTime );

                        /* 下一個任務的解鎖時間必須大於用戶定義的最小空閒休眠時間閾值, 否則不休眠 */
                        if( xExpectedIdleTime >= configEXPECTED_IDLE_TIME_BEFORE_SLEEP )
                        {
                            traceLOW_POWER_IDLE_BEGIN();
                            /* 進入 Tickless 模式 */
                            portSUPPRESS_TICKS_AND_SLEEP( xExpectedIdleTime );
                            traceLOW_POWER_IDLE_END();
                        }
                        else
                        {
                            mtCOVERAGE_TEST_MARKER();
                        }
                    }
                    /* 恢復任務調度器 */
                    ( void ) xTaskResumeAll();
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
            #endif
        }
    }
    ```

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