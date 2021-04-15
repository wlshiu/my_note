Task Notify [[Back](note_freertos_task.md)]
---

如果 RTOS task 已經因為等待 notify 而進入 blocking 狀態, 則接收到 notify 後 task 解除 blocking 並**清除通知**
> 使用 **configUSE_TASK_NOTIFICATIONS** 來開啟

+ task notify 效率可以快45%, 使用更少的RAM.
+ 限制
    - 只能有一個任務接收通知事件
    - 接收通知的 task 可以因為等待通知而進入 blocking 狀態, 但是**發送通知的 task** 即便不能立即完成通知發送, 也**不能進入 blocking 狀態**

#　xTaskNotifyGive() and ulTaskNotifyTake()

專門為使用更輕量級更快的方法, 來代替二進制或計數信號量而量身打造的

+ xTaskNotifyGive() and vTaskNotifyGiveFromISR()
    > 等效於 **xSemaphoreGive()**

    - xTaskNotifyGive

        ```c
        #define xTaskNotifyGive( xTaskToNotify ) \
            xTaskGenericNotify( ( xTaskToNotify ), ( tskDEFAULT_INDEX_TO_NOTIFY ), ( 0 ), eIncrement, NULL )

        #define xTaskNotifyGiveIndexed( xTaskToNotify, uxIndexToNotify ) \
            xTaskGenericNotify( ( xTaskToNotify ), ( uxIndexToNotify ), ( 0 ), eIncrement, NULL )
        ```

        1. **xTaskToNotify**
            > task handle

        1. **uxIndexToNotify**
            > 當 `configTASK_NOTIFICATION_ARRAY_ENTRIES > 1`, 可以使用多組 task notifies, uxIndexToNotify 用來指定使用哪一組

    - vTaskNotifyGiveFromISR

        ```c
        #define vTaskNotifyGiveFromISR( xTaskToNotify, pxHigherPriorityTaskWoken ) \
            vTaskGenericNotifyGiveFromISR( ( xTaskToNotify ), ( tskDEFAULT_INDEX_TO_NOTIFY ), ( pxHigherPriorityTaskWoken ) );

        #define vTaskNotifyGiveIndexedFromISR( xTaskToNotify, uxIndexToNotify, pxHigherPriorityTaskWoken ) \
            vTaskGenericNotifyGiveFromISR( ( xTaskToNotify ), ( uxIndexToNotify ), ( pxHigherPriorityTaskWoken ) );
        ```

        1. **xTaskToNotify** and **uxIndexToNotify**
            > 等同 xTaskNotifyGive

        1. **pxHigherPriorityTaskWoken** 	(*pxHigherPriorityTaskWoken 必須初始化為 0)
            > 如果發送 notify 導致 task 取消 blocking, 並且取消 blocking 的 task 的優先級高於當前運行的 task,
            則 vTaskNotifyGiveFromISR() 會設置 `(*pxHigherPriorityTaskWoken) = pdTRUE`; 同時應在退出中斷之前請求 context switch
            >> pxHigherPriorityTaskWoken 是可選參數, 可以設置為 NULL

            ```c
            /* This is an example of a transmit function in a generic peripheral driver.  An
             * RTOS task calls the transmit function, then waits in the Blocked state (so not
             * using an CPU time) until it is notified that the transmission is complete.  The
             * transmission is performed by a DMA, and the DMA end interrupt is used to notify
             * the task.
             */

            static TaskHandle_t xTaskToNotify = NULL;

            /* The peripheral driver's transmit function. */
            void StartTransmission( uint8_t *pcData, size_t xDataLength )
            {
                /* At this point xTaskToNotify should be NULL as no transmission is in
                 * progress.  A mutex can be used to guard access to the peripheral if necessary.
                 */
                configASSERT( xTaskToNotify == NULL );

                /* Store the handle of the calling task. */
                xTaskToNotify = xTaskGetCurrentTaskHandle();

                /* Start the transmission - an interrupt is generated when the transmission is complete. */
                vStartTransmit( pcData, xDatalength );
            }
            /*-----------------------------------------------------------*/

            /* The transmit end interrupt. */
            void vTransmitEnd_ISR( void )
            {
                BaseType_t xHigherPriorityTaskWoken = pdFALSE;

                /* At this point xTaskToNotify should not be NULL as a transmission was in progress. */
                configASSERT( xTaskToNotify != NULL );

                /* Notify the task that the transmission is complete. */
                vTaskNotifyGiveFromISR( xTaskToNotify, &xHigherPriorityTaskWoken );

                /* There are no transmissions in progress, so no tasks to notify. */
                xTaskToNotify = NULL;

                /* If xHigherPriorityTaskWoken is now set to pdTRUE then a context switch
                 * should be performed to ensure the interrupt returns directly to the highest
                 * priority task.  The macro used for this purpose is dependent on the port in
                 * use and may be called portEND_SWITCHING_ISR().
                 */
                portYIELD_FROM_ISR( xHigherPriorityTaskWoken ); // 切換
            }
            /*-----------------------------------------------------------*/

            /* The task that initiates the transmission, then enters the Blocked state (so
            not consuming any CPU time) to wait for it to complete. */
            void vAFunctionCalledFromATask( uint8_t ucDataToTransmit, size_t xDataLength )
            {
                uint32_t ulNotificationValue;
                const TickType_t xMaxBlockTime = pdMS_TO_TICKS( 200 );

                /* Start the transmission by calling the function shown above. */
                StartTransmission( ucDataToTransmit, xDataLength );

                /* Wait for the transmission to complete. */
                ulNotificationValue = ulTaskNotifyTake( pdFALSE, xMaxBlockTime );

                if( ulNotificationValue == 1 )
                {
                    /* The transmission ended as expected. */
                }
                else
                {
                    /* The call to ulTaskNotifyTake() timed out. */
                }
            }
            ```


+ ulTaskNotifyTake()
    > 等效於 **xSemaphoreTake()**

    ```c
    #define ulTaskNotifyTake( xClearCountOnExit, xTicksToWait ) \
        ulTaskGenericNotifyTake( ( tskDEFAULT_INDEX_TO_NOTIFY ), ( xClearCountOnExit ), ( xTicksToWait ) )

    #define ulTaskNotifyTakeIndexed( uxIndexToWaitOn, xClearCountOnExit, xTicksToWait ) \
        ulTaskGenericNotifyTake( ( uxIndexToWaitOn ), ( xClearCountOnExit ), ( xTicksToWait ) )
    ```

    - **uxIndexToWaitOn**
        > 當 `configTASK_NOTIFICATION_ARRAY_ENTRIES > 1`, 可以使用多組 task notifies, uxIndexToNotify 用來指定使用哪一組

    - **xClearCountOnExit**
        > 如果接收到 RTOS task notify, 並且 `xClearCountOnExit = pdFALSE`, 則在 ulTask??NotifyTake() 退出之前, RTOS task 的 notify value 將減小.
        這等效於成功調用 xSemaphoreTake() 會減少計數信號量的值

        > 如果收到 RTOS task notify, 並將 `xClearCountOnExit = pdTRUE`, 則在 ulTaskNotifyTake() 退出之前, RTOS task 的 notify value 將重置為 0.
        這等效於成功調用 xSemaphoreTake() 後, 二進制信號量的值保留為零(或為空, 或不可用)


    - **xTicksToWait**
        > 如果在調用 ulTaskNotifyTake() 時, notify 尚未掛起, 則在 blocking 狀態下, 等待接收通知的最長時間
        >> 處於 blocking 狀態時, RTOS task 不會消耗任何 CPU 時間

        > 時間以 RTOS tick 週期指定.
        >> pdMS_TO_TICKS() 可用於將以 msec 為單位的時間, 轉換為以 tick 數為單位的時間


        ```c
        /*中斷處理程序。中斷處理程序不執行任何處理, 相反, 它會解除阻止高優先級任務, 其中生成中斷被處理。
          如果任務的優先級足夠高, 則中斷將直接返回到任務(因此它將中斷一個任務, 但是返回到其他任務),
          因此處理將在時間上連續進行 - 就好像所有的處理都是在中斷處理程序本身中完成的一樣. */
        void vAnInterruptHandler( void )
        {
            BaseType_t xHigherPriorityTaskWoken;

            /* Clear the interrupt. */
            prvClearInterruptSource();

            /* xHigherPriorityTaskWoken must be initialised to pdFALSE.  If calling
             * vTaskNotifyGiveFromISR() unblocks the handling task, and the priority of
             * the handling task is higher than the priority of the currently running task,
             * then xHigherPriorityTaskWoken will automatically get set to pdTRUE.
             */
            xHigherPriorityTaskWoken = pdFALSE;

            /* Unblock the handling task so the task can perform any processing necessitated
             * by the interrupt.  xHandlingTask is the task's handle, which was obtained
             * when the task was created.
             */
             vTaskNotifyGiveFromISR( xHandlingTask, &xHigherPriorityTaskWoken );

            /* Force a context switch if xHigherPriorityTaskWoken is now set to pdTRUE.
             * The macro used to do this is dependent on the port and may be called
             * portEND_SWITCHING_ISR.
             */
            portYIELD_FROM_ISR( xHigherPriorityTaskWoken );
        }
        /*-----------------------------------------------------------*/

        /* A task that blocks waiting to be notified that the peripheral needs servicing,
        processing all the events pending in the peripheral each time it is notified to do so. */
        void vHandlingTask( void *pvParameters )
        {
            BaseType_t xEvent;

            for( ;; )
            {
                /* Block indefinitely (without a timeout, so no need to check the function's
                 * return value) to wait for a notification.  Here the RTOS task notification
                 * is being used as a binary semaphore, so the notification value is cleared
                 * to zero on exit.  NOTE!  Real applications should not block indefinitely,
                 * but instead time out occasionally in order to handle error conditions
                 * that may prevent the interrupt from sending any more notifications.
                 */
                ulTaskNotifyTake( pdTRUE,          /* Clear the notification value before exiting. */
                                  portMAX_DELAY ); /* Block indefinitely. */

                /* The RTOS task notification is used as a binary (as opposed to a
                 * counting) semaphore, so only go back to wait for further notifications
                 * when all events pending in the peripheral have been processed.
                 */
                do {
                    xEvent = xQueryPeripheral();

                    if( xEvent != NO_MORE_EVENTS )
                    {
                        vProcessPeripheralEvent( xEvent );
                    }

                } while( xEvent != NO_MORE_EVENTS );
            }
        }
        ```

+ Example usage

    ```c
    /* Prototypes of the two tasks created by main(). */
    static void prvTask1( void *pvParameters );
    static void prvTask2( void *pvParameters );

    /* Handles for the tasks create by main(). */
    static TaskHandle_t xTask1 = NULL, xTask2 = NULL;

    /* Create two tasks that send notifications back and forth to each other, then
     * start the RTOS scheduler.
     */
    void main( void )
    {
        xTaskCreate( prvTask1, "Task1", 200, NULL, tskIDLE_PRIORITY, &xTask1 );
        xTaskCreate( prvTask2, "Task2", 200, NULL, tskIDLE_PRIORITY, &xTask2 );
        vTaskStartScheduler();
    }
    /*-----------------------------------------------------------*/

    static void prvTask1( void *pvParameters )
    {
        for( ;; )
        {
            /* Send a notification to prvTask2(), bringing it out of the Blocked state. */
            xTaskNotifyGive( xTask2 );

            /* Block to wait for prvTask2() to notify this task. */
            ulTaskNotifyTake( pdTRUE, portMAX_DELAY );
        }
    }
    /*-----------------------------------------------------------*/

    static void prvTask2( void *pvParameters )
    {
        for( ;; )
        {
            /* Block to wait for prvTask1() to notify this task. */
            ulTaskNotifyTake( pdTRUE, portMAX_DELAY );

            /* Send a notification to prvTask1(), bringing it out of the Blocked state. */
            xTaskNotifyGive( xTask1 );
        }
    }
    ```

# xTaskNotify

+ prototype

    - xTaskNotify

        ```c
        #define xTaskNotify( xTaskToNotify, ulValue, eAction ) \
            xTaskGenericNotify( ( xTaskToNotify ), ( tskDEFAULT_INDEX_TO_NOTIFY ), ( ulValue ), ( eAction ), NULL )

        #define xTaskNotifyIndexed( xTaskToNotify, uxIndexToNotify, ulValue, eAction ) \
            xTaskGenericNotify( ( xTaskToNotify ), ( uxIndexToNotify ), ( ulValue ), ( eAction ), NULL )

        xTaskNotifyFromISR( xTaskToNotify, ulValue, eAction, pxHigherPriorityTaskWoken );
        xTaskNotifyIndexedFromISR( xTaskToNotify, uxIndexToNotify, ulValue, eAction, pxHigherPriorityTaskWoken );
        ```

        1. **ulValue**
            > 用於更新 targert task 的 notify value

        1. **eAction**
            > 如果 targert task 已有一個待處理的 notify, 則其**通知值不會更新**, 因為這樣做會在使用前覆蓋先前的值.
            在這種情況下, 對xTaskNotify() 的調用將失敗, 並返回 pdFALSE.
            >> RTOS task notify 機制, 等同於輕量 Queue 長度為 1 的 xQueueSend()

            | eAction設置                  | 動作已執行                                                                                                       |
            |----------------------------|-----------------------------------------------------------------------------------------------------------------|
            | eNoAction                  | targert task 接收到事件, 但是其通知值未更新. 在這種情況下, 不使用 ulValue。                                              |
            | eSetBits                   | targert task 的通知值將與 ulValue 按 bitmap. 例如, 如果 `ulValue = 0x01`, 則將通知值內設置 bit[0].                     |
            | -                          | 同樣, 如果ulValue為0x04, 則將在主題任務的通知值中設置位2。這樣, RTOS任務通知機制可以用作事件組的輕量級替代方案                  |
            | eIncrement                 | targert task 的通知值將 +1, 從而使對 xTaskNotify() 的調用等效於對 xTaskNotifyGive() 的調用. 在這種情況下, 不使用 ulValue  |
            | eSetValueWithOverwrite     | targert task 的通知值無條件設置為 ulValue. 通過這種方式, RTOS task notify 機制被用作 xQueueOverwrite() 的輕量替代方案     |
            | eSetValueWithoutOverwrite  | 如果 targert task 尚未有待處理的通知, 則其通知值將設置為 ulValue

        1. **uxIndexToNotify**
            > 當 `configTASK_NOTIFICATION_ARRAY_ENTRIES > 1`, 可以使用多組 task notifies, uxIndexToNotify 用來指定使用哪一組

    - xTaskNotifyAndQuery

        ```c
        xTaskNotifyAndQuery( xTaskToNotify, ulValue, eAction, pulPreviousNotifyValue );
        xTaskNotifyAndQueryIndexed( xTaskToNotify, uxIndexToNotify, ulValue, eAction, pulPreviousNotifyValue );

        xTaskNotifyAndQueryFromISR( xTaskToNotify, ulValue, eAction, pulPreviousNotificationValue, pxHigherPriorityTaskWoken );
        xTaskNotifyAndQueryIndexedFromISR( xTaskToNotify, uxIndexToNotify, ulValue, eAction, pulPreviousNotificationValue, pxHigherPriorityTaskWoken );
        ```

        1. **ulValue**, **eAction**, **uxIndexToNotify**
            > 皆等同 `xTaskNotify`

        1. **pulPreviousNotifyValue**
            > 回傳原本的 Notify Value



+ Example usage

    ```c
    /* Set bit 8 in the notification value of the task referenced by xTask1Handle. */
    xTaskNotify( xTask1Handle, ( 1UL << 8UL ), eSetBits );

    /* Send a notification to the task referenced by xTask2Handle, potentially
     * removing the task from the Blocked state, but without updating the task's
     * notification value.
     */
    xTaskNotify( xTask2Handle, 0, eNoAction );

    /* Set the notification value of the task referenced by xTask3Handle to 0x50,
     * even if the task had not read its previous notification value.
     */
    xTaskNotify( xTask3Handle, 0x50, eSetValueWithOverwrite );

    /* Set the notification value of the task referenced by xTask4Handle to 0xfff,
     * but only if to do so would not overwrite the task's existing notification
     * value before the task had obtained it (by a call to xTaskNotifyWait()
     * or ulTaskNotifyTake()).
     */
    if( xTaskNotify( xTask4Handle, 0xfff, eSetValueWithoutOverwrite ) == pdPASS )
    {
        /* The task's notification value was updated. */
    }
    else
    {
        /* The task's notification value was not updated. */
    }
    ```

# xTaskNotifyWait

+ prototype

    ```
    #define xTaskNotifyWait( ulBitsToClearOnEntry, ulBitsToClearOnExit, pulNotificationValue, xTicksToWait ) \
        xTaskGenericNotifyWait( tskDEFAULT_INDEX_TO_NOTIFY, ( ulBitsToClearOnEntry ), ( ulBitsToClearOnExit ), ( pulNotificationValue ), ( xTicksToWait ) )

    #define xTaskNotifyWaitIndexed( uxIndexToWaitOn, ulBitsToClearOnEntry, ulBitsToClearOnExit, pulNotificationValue, xTicksToWait ) \
        xTaskGenericNotifyWait( ( uxIndexToWaitOn ), ( ulBitsToClearOnEntry ), ( ulBitsToClearOnExit ), ( pulNotificationValue ), ( xTicksToWait ) )
    ```

    - **ulBitsToClearOnEntry**
        > 在使用通知之前, 先將 Notify Value 對應到 ulBitsToClearOnEntry 中 bit field 為 1 的部分, 清為 0
        >> 設置參數 `ulBitsToClearOnEntry = 0xFFFFFFFF`(ULONG_MAX), 表示清零 Notify Value

        ```c
        pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] &= ~ulBitsToClearOnEntry;
        ```

    - **ulBitsToClearOnExit**
        > 在 xTaskNotifyWait() 退出前, 先將 Notify Value 對應到 ulBitsToClearOnExit 中 bit field 為 1 的部分, 清為 0
        設置參數 `ulBitsToClearOnExit = 0xFFFFFFFF`(ULONG_MAX), 表示清零 Notify Value

        ```c
        pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] &= ~ulBitsToClearOnExit;
        ```

    - **pulNotificationValue**
        > 用於向外回傳任務的 Notify Value
        這個通知值在參數 ulBitsToClearOnExit 起作用前, 將通知值 copy 到 `*pulNotificationValue`中. 如果不需要返回任務的通知值, 這裡設置成 NULL。

    - **xTicksToWait**
        > 因等待通知而進入 blocking 狀態的最大時間.
        時間單位為系統 tick 週期. `pdMS_TO_TICKS` 用於將指定的 msec 時間轉化為相應的系統 tick 數

+ Example usage

    ```c
    /* 這個 task 使用任務通知值的位來傳遞不同的事件,
     * 這在某些情況下可以代替 event group
     */
    void vAnEventProcessingTask( void *pvParameters )
    {
        uint32_t    ulNotifiedValue;

        for( ;; )
        {
            /* 等待 notify, 無限期阻塞(沒有超時, 所以不用檢查函數返回值).
             * 其它 task 或者中斷設置的通知值中的不同位表示不同的事件。
             * 參數 0x00 表示使用通知前, 不清除任務的通知值位,
             * 參數 ULONG_MAX 表示函數 xTaskNotifyWait() 退出前, 將任務通知值設置為 0
             */
            xTaskNotifyWait( 0x00, ULONG_MAX, &ulNotifiedValue, portMAX_DELAY );

            /* 根據通知值處理事件 */
            if( ( ulNotifiedValue & 0x01 ) != 0)
            {
                prvProcessBit0Event();
            }

            if( ( ulNotifiedValue & 0x02 ) != 0)
            {
                prvProcessBit1Event();
            }

            if( ( ulNotifiedValue & 0x04 ) != 0)
            {
                prvProcessBit2Event();
            }

            ...
        }
    }
    ```

# xTaskNotifyStateClear

進入臨界區清除 task 的 notify state, 但不會對 Notified Value 進行任何操作

```c
#define xTaskNotifyStateClear( xTask ) \
    xTaskGenericNotifyStateClear( ( xTask ), ( tskDEFAULT_INDEX_TO_NOTIFY ) )

#define xTaskNotifyStateClearIndexed( xTask, uxIndexToClear ) \
    xTaskGenericNotifyStateClear( ( xTask ), ( uxIndexToClear ) )


BaseType_t xTaskGenericNotifyStateClear( TaskHandle_t xTask,
                                         UBaseType_t uxIndexToClear )
{
    TCB_t * pxTCB;
    BaseType_t xReturn;

    configASSERT( uxIndexToClear < configTASK_NOTIFICATION_ARRAY_ENTRIES );

    /* If null is passed in here then it is the calling task that is having
     * its notification state cleared. */
    pxTCB = prvGetTCBFromHandle( xTask );

    taskENTER_CRITICAL();
    {
        if( pxTCB->ucNotifyState[ uxIndexToClear ] == taskNOTIFICATION_RECEIVED )
        {
            pxTCB->ucNotifyState[ uxIndexToClear ] = taskNOT_WAITING_NOTIFICATION;
            xReturn = pdPASS;
        }
        else
        {
            xReturn = pdFAIL;
        }
    }
    taskEXIT_CRITICAL();

    return xReturn;
}

```

# xTaskGenericNotify

    ```c
    BaseType_t xTaskGenericNotify( TaskHandle_t xTaskToNotify,
                                   UBaseType_t uxIndexToNotify,
                                   uint32_t ulValue,
                                   eNotifyAction eAction,
                                   uint32_t * pulPreviousNotificationValue )
    {
        TCB_t * pxTCB;
        BaseType_t xReturn = pdPASS;
        uint8_t ucOriginalNotifyState;

        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );
        configASSERT( xTaskToNotify );
        pxTCB = xTaskToNotify;

        /* 進入臨界區 */
        taskENTER_CRITICAL();
        {
            if( pulPreviousNotificationValue != NULL )
            {
                /*如果 pulPreviousNotificationValue 不為空, 將被通知任務的 ulNotifiedValue 返回 */
                *pulPreviousNotificationValue = pxTCB->ulNotifiedValue[ uxIndexToNotify ];
            }

            /*保存任務原始的 notify state*/
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];

            /*設置任務的 notify state 為 taskNOTIFICATION_RECEIVED */
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;

            switch( eAction )
            {
                case eSetBits: /* bitmap 操作 */
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] |= ulValue;
                    break;

                case eIncrement: /* 加操作, ulNotifiedValue進行累加, 這時忽略 ulValue */
                    ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
                    break;

                case eSetValueWithOverwrite: /* 不理會任務 notify state, 直接覆蓋 */
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
                    break;

                case eSetValueWithoutOverwrite:

                    if( ucOriginalNotifyState != taskNOTIFICATION_RECEIVED )
                    {
                        /* 如果上次 notify 的事件被讀走, state 將不為 taskNOTIFICATION_RECEIVED ,
                           這時才設置 ulNotifiedValue, 否則返回失敗 */
                        pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
                    }
                    else
                    {
                        /* The value could not be written to the task. */
                        xReturn = pdFAIL;
                    }

                    break;

                case eNoAction: /* 不更新任何值, 但是 eNotifyState 被設置 taskNOTIFICATION_RECEIVED */

                    /* The task is being notified without its notify value being
                     * updated. */
                    break;

                default:

                    /* Should not get here if all enums are handled.
                     * Artificially force an assert by testing a value the
                     * compiler can't assume is const. */
                    configASSERT( xTickCount == ( TickType_t ) 0 );

                    break;
            }

            traceTASK_NOTIFY( uxIndexToNotify );

            /* If the task is in the blocked state specifically to wait for a
             * notification then unblock it now.
             */
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
            {
                /* 如果被通知任務正處於等待通知狀態, 那麼將等待任務從阻塞隊列中刪除,
                 * 然後添加到 ready list中, 如果你看過之前 task 的介紹, 一定清楚
                 * prvAddTaskToReadyList 的操作(即更新了就緒隊列又更新了就緒任務標記)
                 */
                ( void ) uxListRemove( &( pxTCB->xStateListItem ) );
                prvAddTaskToReadyList( pxTCB );

                /* The task should not have been on an event list. */
                /* 等待 task notify 的 task, 必然不會等待 queue 等內核對象的資源, 否則進入 ASSERT */
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );

                #if ( configUSE_TICKLESS_IDLE != 0 )
                {
                    /* If a task is blocked waiting for a notification then
                     * xNextTaskUnblockTime might be set to the blocked task's time
                     * out time.  If the task is unblocked for a reason other than
                     * a timeout xNextTaskUnblockTime is normally left unchanged,
                     * because it will automatically get reset to a new value when
                     * the tick count equals xNextTaskUnblockTime.  However if
                     * tickless idling is used it might be more important to enter
                     * sleep mode at the earliest possible time - so reset
                     * xNextTaskUnblockTime here to ensure it is updated at the
                     * earliest possible time. */

                     /* 因為 remove 的 task 在 blocking 隊列裡,
                      * 因此要重新設置 blocking task 中, 下一個 running task 的 tick 點
                      */
                    prvResetNextTaskUnblockTime();
                }
                #endif

                if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
                {
                    /* The notified task has a priority above the currently
                     * executing task so a yield is required. */
                    /* 如果被通知的 task 優先級高於當前運行任務優先級, 則進行一次 task 切換 */
                    taskYIELD_IF_USING_PREEMPTION();
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
            else
            {
                /* 被通知任務的 notify state 不為 eWaitingNotification,
                 * 表示 task 沒有阻塞等待 notify 時間, 則不進行上面的切換操作,
                 * 被通知需要等待調度器調度到後取出通知事件*/
                mtCOVERAGE_TEST_MARKER();
            }
        }
        taskEXIT_CRITICAL();

        return xReturn;
    }
    ```

# ulTaskGenericNotifyTake

    ```c
    uint32_t ulTaskGenericNotifyTake( UBaseType_t uxIndexToWait,
                                      BaseType_t xClearCountOnExit,
                                      TickType_t xTicksToWait )
    {
        uint32_t ulReturn;

        configASSERT( uxIndexToWait < configTASK_NOTIFICATION_ARRAY_ENTRIES );

        /* 進入臨界區 */
        taskENTER_CRITICAL();
        {
            /* Only block if the notification count is not already non-zero. */
            if( pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] == 0UL )
            {
                /* Mark this task as waiting for a notification. */
                /*如果 ulNotifiedValue 那麼久必須進行阻塞操作, 否則, 直接take and return*/
                /*設置 notify 狀態為 taskWAITING_NOTIFICATION */
                pxCurrentTCB->ucNotifyState[ uxIndexToWait ] = taskWAITING_NOTIFICATION;

                if( xTicksToWait > ( TickType_t ) 0 )
                {
                    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
                    traceTASK_NOTIFY_TAKE_BLOCK( uxIndexToWait );

                    /* All ports are written to allow a yield in a critical
                     * section (some will yield immediately, others wait until the
                     * critical section exits) - but it is not something that
                     * application code should ever do. */

                    /* 因為當前 task 已經從 ready 狀態變為 blocking 或者 suspend 狀態,
                     * 那麼就讓出 cpu, 等待喚醒或者超時後, 從此處繼續往下執行,
                     * 而且所有的切換操作必須支持在臨界區內進行切換
                     */
                    portYIELD_WITHIN_API();
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
            else
            {
                mtCOVERAGE_TEST_MARKER();
            }
        }
        taskEXIT_CRITICAL();
        /* 程序執行到這裡有一下幾種情況:
         * 1. ulNotifiedValue 一開始不為 0, 直接執行到這裡;
         * 2. ulNotifiedValue 一開始為 0, 任務進入阻塞, 然後期間被別的任務或者中斷回調使用 give 操作喚醒
         * 3. 和情況2 不同的時, 沒有第三者在等待期間喚醒任務, 任務等待超時執行到此處 ]
         */

        taskENTER_CRITICAL();
        {
            traceTASK_NOTIFY_TAKE( uxIndexToWait );
            ulReturn = pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ];

            if( ulReturn != 0UL )
            {
                if( xClearCountOnExit != pdFALSE )
                {
                    pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] = 0UL;
                }
                else
                {
                    pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] = ulReturn - ( uint32_t ) 1;
                }
            }
            else
            {
                mtCOVERAGE_TEST_MARKER();
            }

            /* 將 task 的 notify state 設置為沒有在等待通知 */
            pxCurrentTCB->ucNotifyState[ uxIndexToWait ] = taskNOT_WAITING_NOTIFICATION;
        }
        taskEXIT_CRITICAL();

        /* 如果是情形3 這裡返回的就是 0, 也就是flase */
        return ulReturn;
    }

    ```

# xTaskGenericNotifyFromISR

    ```c
    BaseType_t xTaskGenericNotifyFromISR( TaskHandle_t xTaskToNotify,
                                          UBaseType_t uxIndexToNotify,
                                          uint32_t ulValue,
                                          eNotifyAction eAction,
                                          uint32_t * pulPreviousNotificationValue,
                                          BaseType_t * pxHigherPriorityTaskWoken )
    {
        TCB_t * pxTCB;
        uint8_t ucOriginalNotifyState;
        BaseType_t xReturn = pdPASS;
        UBaseType_t uxSavedInterruptStatus;

        configASSERT( xTaskToNotify );
        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );

        /* RTOS ports that support interrupt nesting have the concept of a
         * maximum  system call (or maximum API call) interrupt priority.
         * Interrupts that are  above the maximum system call priority are keep
         * permanently enabled, even when the RTOS kernel is in a critical section,
         * but cannot make any calls to FreeRTOS API functions.  If configASSERT()
         * is defined in FreeRTOSConfig.h then
         * portASSERT_IF_INTERRUPT_PRIORITY_INVALID() will result in an assertion
         * failure if a FreeRTOS API function is called from an interrupt that has
         * been assigned a priority above the configured maximum system call
         * priority.  Only FreeRTOS functions that end in FromISR can be called
         * from interrupts  that have been assigned a priority at or (logically)
         * below the maximum system call interrupt priority.  FreeRTOS maintains a
         * separate interrupt safe API to ensure interrupt entry is as fast and as
         * simple as possible.  More information (albeit Cortex-M specific) is
         * provided on the following link:
         * https://www.FreeRTOS.org/RTOS-Cortex-M3-M4.html */
        portASSERT_IF_INTERRUPT_PRIORITY_INVALID();

        pxTCB = xTaskToNotify;

        /* 設置中斷優先級標誌, 暫時屏蔽中斷 */
        uxSavedInterruptStatus = portSET_INTERRUPT_MASK_FROM_ISR();
        {
            if( pulPreviousNotificationValue != NULL )
            {
                *pulPreviousNotificationValue = pxTCB->ulNotifiedValue[ uxIndexToNotify ];
            }

            /* 保存 task 原始 notify 狀態 */
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];

            /* 設置 task notify 狀態為 taskNOTIFICATION_RECEIVED */
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;

            switch( eAction )
            {
                case eSetBits:
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] |= ulValue;
                    break;

                case eIncrement: /* give 操作就相當於 task notfiy 的加操作*/
                    ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
                    break;

                case eSetValueWithOverwrite:
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
                    break;

                case eSetValueWithoutOverwrite:

                    if( ucOriginalNotifyState != taskNOTIFICATION_RECEIVED )
                    {
                        pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
                    }
                    else
                    {
                        /* The value could not be written to the task. */
                        xReturn = pdFAIL;
                    }

                    break;

                case eNoAction:

                    /* The task is being notified without its notify value being
                     * updated. */
                    break;

                default:

                    /* Should not get here if all enums are handled.
                     * Artificially force an assert by testing a value the
                     * compiler can't assume is const. */
                    configASSERT( xTickCount == ( TickType_t ) 0 );
                    break;
            }

            traceTASK_NOTIFY_FROM_ISR( uxIndexToNotify );

            /* If the task is in the blocked state specifically to wait for a
             * notification then unblock it now. */
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
            {
                /* 如果 task 的原始狀態為等待任務通知, 表示 task 正在 blocking等待 notify */

                /* The task should not have been on an event list. */
                /* 這時候 task 必須不是在等待其他的時間, 而進入了阻塞狀態, 否則 ASSERT */
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );

                if( uxSchedulerSuspended == ( UBaseType_t ) pdFALSE )
                {
                    /* 如果調度器沒有暫停, 則將 task 從其他隊列刪除, 並且添加到 ready 隊列
                     * prvAddTaskToReadyList 也會更新 task ready 隊列標記*/
                    ( void ) uxListRemove( &( pxTCB->xStateListItem ) );
                    prvAddTaskToReadyList( pxTCB );
                }
                else
                {
                    /* 如果調度器暫停了, 這時候將 task 暫時添加到 xPendingReadyList
                     * 等待調度器再次運行時, 再添加到就緒隊列
                     */
                    /* The delayed and ready lists cannot be accessed, so hold
                     * this task pending until the scheduler is resumed. */
                    vListInsertEnd( &( xPendingReadyList ), &( pxTCB->xEventListItem ) );
                }

                if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
                {
                    /* 如果喚醒的 task 優先級比當前運行任務優先級高,
                     * 則設置 pxHigherPriorityTaskWoken, 中斷可以選擇在中斷回調結束後,
                     * 完成任務切換
                     */
                    /* The notified task has a priority above the currently
                     * executing task so a yield is required. */
                    if( pxHigherPriorityTaskWoken != NULL )
                    {
                        *pxHigherPriorityTaskWoken = pdTRUE;
                    }

                    /* Mark that a yield is pending in case the user is not
                     * using the "xHigherPriorityTaskWoken" parameter to an ISR
                     * safe FreeRTOS function. */
                    xYieldPending = pdTRUE;
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
        }

        /* 退出時回復中斷 */
        portCLEAR_INTERRUPT_MASK_FROM_ISR( uxSavedInterruptStatus );

        return xReturn;
    }
    ```

# xTaskGenericNotifyWait

    ```c
    BaseType_t xTaskGenericNotifyWait( UBaseType_t uxIndexToWait,
                                       uint32_t ulBitsToClearOnEntry,
                                       uint32_t ulBitsToClearOnExit,
                                       uint32_t * pulNotificationValue,
                                       TickType_t xTicksToWait )
    {
        BaseType_t xReturn;

        configASSERT( uxIndexToWait < configTASK_NOTIFICATION_ARRAY_ENTRIES );

        /* 進入臨界區 */
        taskENTER_CRITICAL();
        {
            /* Only block if a notification is not already pending. */
            if( pxCurrentTCB->ucNotifyState[ uxIndexToWait ] != taskNOTIFICATION_RECEIVED )
            {
                /* 如果 task 沒有未處理的 notify 事件則要進行阻塞操作
                 * Notify state 為 taskNOTIFICATION_RECEIVED 表示有未被處理的 notify 事件*/

                /* Clear bits in the task's notification value as bits may get
                 * set  by the notifying task or interrupt.  This can be used to
                 * clear the value to zero. */
                pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] &= ~ulBitsToClearOnEntry;

                /* Mark this task as waiting for a notification. */
                /* 將 task 的 notify 狀態修改為 taskWAITING_NOTIFICATION,，即等待notify*/
                pxCurrentTCB->ucNotifyState[ uxIndexToWait ] = taskWAITING_NOTIFICATION;

                if( xTicksToWait > ( TickType_t ) 0 )
                {
                    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
                    traceTASK_NOTIFY_WAIT_BLOCK( uxIndexToWait );

                    /* All ports are written to allow a yield in a critical
                     * section (some will yield immediately, others wait until the
                     * critical section exits) - but it is not something that
                     * application code should ever do. */

                    /* 因為當前 task 已經添加到阻塞隊列或者暫停隊列,
                     * 因此調用切換讓出 CPU 等待任務被喚醒後, 從該處繼續向下執行*/
                    portYIELD_WITHIN_API();
                }
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }
            }
            else
            {
                mtCOVERAGE_TEST_MARKER();
            }
        }
        taskEXIT_CRITICAL(); /* 退出臨界區 */

        /* 不管前面是怎麼操作, task 能夠運行到這裡,
         * 表示當前 task 的 notify 狀態為 taskNOTIFICATION_RECEIVED 或者阻塞操作超時了,
         * task 被喚醒後, 執行到此處, 則進入臨界區取走更新的 ulNotifiedValue
         */
        taskENTER_CRITICAL();
        {
            traceTASK_NOTIFY_WAIT( uxIndexToWait );

            if( pulNotificationValue != NULL )
            {
                /* Output the current notification value, which may or may not
                 * have changed. */
                /* 如果需要返回 ulNotifiedValue, 則返回該值 */
                *pulNotificationValue = pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ];
            }

            /* If ucNotifyValue is set then either the task never entered the
             * blocked state (because a notification was already pending) or the
             * task unblocked because of a notification.  Otherwise the task
             * unblocked because of a timeout. */
            if( pxCurrentTCB->ucNotifyState[ uxIndexToWait ] != taskNOTIFICATION_RECEIVED )
            {
                /* blocking 操作超時了, 在這期間沒有發生該任務的 notify, 返回 pdFALSE */
                /* A notification was not received. */
                xReturn = pdFALSE;
            }
            else
            {
                /* 其他情況下，表示成功獲取了事件，在退出前將 ulNotifiedValue 某些 bits 清除*/
                /* A notification was already pending or a notification was
                 * received while the task was waiting. */
                pxCurrentTCB->ulNotifiedValue[ uxIndexToWait ] &= ~ulBitsToClearOnExit;
                xReturn = pdTRUE;
            }

            /* 設置 task 的 NotifyState 為沒有等待通知 */
            pxCurrentTCB->ucNotifyState[ uxIndexToWait ] = taskNOT_WAITING_NOTIFICATION;
        }
        taskEXIT_CRITICAL();

        return xReturn;
    }
    ```


# reference

+ [FreeRTOS直接到任務通知](https://www.codenong.com/cs106622113/)
+ [freertos內核走讀2——task任務調度機制（四） notify機制](https://blog.csdn.net/jorhai/article/details/68937118)


