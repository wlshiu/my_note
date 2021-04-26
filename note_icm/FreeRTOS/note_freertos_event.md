FreeRTOs Event Group [[Back](note_freertos_guide.md)]
---

event group 是一種通信的機制, 主要用於實現 tasks 間或是 `ISR <-> task` 的同步, 但事件通信只能是 event 類型的通信, **無數據傳輸**.

```
        Task_1
        while(1)                            ISR()
        {                                   {

    +--->   xEventGroupWaitBits();  <---+---   xEventGroupSetBitsFromISR();
    |                                   |   }
    |       ...                         |
    +----   xEventGroupSetBits();       |   Task_2
        }                               |   {
                                        +----   xEventGroupSetBits();
                                            }
```

+ EventGroup 是由 RTOS 提供的 system API, 支援 timeout 機制, race condition 保護及管理 task 的 status, 也能有效地解決 ISR 和 task 之間的同步問題.
+ 自定義的全域變數 event flags, 雖然速度快但**需要自行處理 timeout, race condition 等同步的問題**

# 變數定義

## EventBits_t

**configUSE_16_BIT_TICKS** 定義了 event 的最大個數, 其中 **High 8-Bits 被 RTOS 內部使用**.
> + `configUSE_16_BIT_TICKS = 0`
>> `EventBits_t = 32 bits`, event 個數為 24 (Low 24-bits)
> + `configUSE_16_BIT_TICKS = 1`
>> `EventBits_t = 16 bits`, event 個數為 8 (Low 8-bits)

```c
#if configUSE_16_BIT_TICKS == 1
    #define eventCLEAR_EVENTS_ON_EXIT_BIT   0x0100U
    #define eventUNBLOCKED_DUE_TO_BIT_SET   0x0200U
    #define eventWAIT_FOR_ALL_BITS          0x0400U
    #define eventEVENT_BITS_CONTROL_BYTES   0xff00U
#else
    #define eventCLEAR_EVENTS_ON_EXIT_BIT   0x01000000UL     /* 在退出時清除位 */
    #define eventUNBLOCKED_DUE_TO_BIT_SET   0x02000000UL
    #define eventWAIT_FOR_ALL_BITS          0x04000000UL     /* 等待所有位 */
    #define eventEVENT_BITS_CONTROL_BYTES   0xff000000UL
#endif
```

## Event Group

```c
typedef struct xEventGroupDefinition
{
    EventBits_t uxEventBits;        /* event 標誌組變量 */
    List_t xTasksWaitingForBits;    /* 等待事件組的 task list */

    #if( configUSE_TRACE_FACILITY == 1 )
        UBaseType_t uxEventGroupNumber;
    #endif

    #if( ( configSUPPORT_STATIC_ALLOCATION == 1 ) && ( configSUPPORT_DYNAMIC_ALLOCATION == 1 ) )
        uint8_t ucStaticallyAllocated;  /* 靜態 memory 標誌 */
    #endif
} EventGroup_t;
```

+ **xTasksWaitingForBits**
    > 所有在等待此 event 的 tasks 均會被掛載在 `xTasksWaitingForBits`
    >> 與 Queue 的 xTasksWaitingToSend/xTasksWaitingToReceive 相同概念

# API

## Create event

```c
EventGroupHandle_t xEventGroupCreate( void );

EventGroupHandle_t xEventGroupCreateStatic( StaticEventGroup_t * pxEventGroupBuffer );
```

## Delete event

```c
void vEventGroupDelete( EventGroupHandle_t xEventGroup );
```

## xEventGroupWaitBits

**xEventGroupWaitBits** 用於獲取 Event Group 中的一個或多個 event 發生 flag, 當要讀取的 flag 沒有被設定時, task 將進入 blocking 等待狀態

+ prototype

    ```c
    EventBits_t xEventGroupWaitBits( EventGroupHandle_t xEventGroup,
                                     const EventBits_t uxBitsToWaitFor,
                                     const BaseType_t xClearOnExit,
                                     const BaseType_t xWaitForAllBits,
                                     TickType_t xTicksToWait );
    ```

    - xEventGroup
        > event handle

    - uxBitsToWaitFor
        > A bitwise mask, 指定需要等待 event group 中的哪些 bits (不能設為 0)
        >> + 如果需要等待 bit 0 and/or bit 2, 那麼`uxBitsToWaitFor = 0x05(0101b)`.
        >> + 如果需要等待 bits 0 and/or bit 1 and/or bit 2, 那麼 `uxBitsToWaitFor = 0x07(0111b)`

    - xClearOnExit
        > + **pdTRUE**
        >> 當 xEventGroupWaitBits() 等待到滿足 task 喚醒的 event 時,  RTOS 將清除 uxBitsToWaitFor 指定的 event bit flag；
        > + **pdFALSE**
        >> 不清除 uxBitsToWaitFor 指定的 event bit flag

    - xWaitForAllBits
        > + **pdTRUE**
        >> 當 uxBitsToWaitFor 指定的 bits **都為 1** 時, 才滿足 task 喚醒的條件 (logic AND), 並且在沒有超時的情況下, 返回對應的 event bit flags 的值.
        > + **pdFALSE**
        >> 當 uxBitsToWaitFor 指定的 bits 有**任意一個為 1** 時, 才滿足 task 喚醒的條件 (logic OR), 在沒有超時的情況下, 返回對應的 event bit flags  的值；

    - xTicksToWait
        > 最大 timeoue, 單位為 system tick
        >> 常量 `portTICK_PERIOD_MS` 用於輔助把時間轉換成 MS.

    - return value
        > 回傳目前以經收到的 event bit flags
        >> `xClearOnExit == pdTRUE`時, 則是回傳清 0 前的值

+ Source code

    ```c
    EventBits_t xEventGroupWaitBits( EventGroupHandle_t xEventGroup, const EventBits_t uxBitsToWaitFor,
                        const BaseType_t xClearOnExit, const BaseType_t xWaitForAllBits, TickType_t xTicksToWait )
    {
        EventGroup_t *pxEventBits = ( EventGroup_t * ) xEventGroup;
        EventBits_t uxReturn, uxControlBits = 0;
        BaseType_t xWaitConditionMet, xAlreadyYielded;
        BaseType_t xTimeoutOccurred = pdFALSE;

        configASSERT( xEventGroup );
        /* Assert 判斷要設置的事件標志位是否有效, 防止用戶使用 High 8-bits */
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
        configASSERT( uxBitsToWaitFor != 0 );
        #if ( ( INCLUDE_xTaskGetSchedulerState == 1 ) || ( configUSE_TIMERS == 1 ) )
        {
            configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
        }
        #endif

        /* 先停止 task 調度 */
        vTaskSuspendAll();
        {
            const EventBits_t uxCurrentEventBits = pxEventBits->uxEventBits;

            /* 先看下當前事件中的標志位, 是否已經滿足條件了 */
            xWaitConditionMet = prvTestWaitCondition( uxCurrentEventBits, uxBitsToWaitFor, xWaitForAllBits );

            if( xWaitConditionMet != pdFALSE ) /* 滿足條件 */
            {
                /*直接返回, 注意這裡返回的, 是的當前事件的"所有"標志位 */
                uxReturn = uxCurrentEventBits;
                /* 等待時間強制置 0 */
                xTicksToWait = ( TickType_t ) 0;

                /* 若設置了退出的時候, 需要清除對應的事件標志位 */
                if( xClearOnExit != pdFALSE )
                {
                    /* 清除對應的標志位 */
                    pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
                }
            }
            else if( xTicksToWait == ( TickType_t ) 0 ) /* 不滿足條件, 且設置的是不等待 */
            {
                /* 也是返回當前事件的 "所有" 標志位 */
                uxReturn = uxCurrentEventBits;
            }
            else /* 不滿足條件, 且用戶指定了超時時間 */
            {
                /* 若設置了退出的時候需要清除對應的事件標志位 */
                if( xClearOnExit != pdFALSE )
                {
                    /* 保存一下當前 task 的信息標記, 以便在恢復 task 的時候, 對事件進行相應的操作 */
                    uxControlBits |= eventCLEAR_EVENTS_ON_EXIT_BIT; /* 0x01000000UL 退出時清除位 */
                }

                /* 若需要等待所有事件 */
                if( xWaitForAllBits != pdFALSE )
                {
                    /* 保存一下當前 task 的信息標記, 以便在恢復 task 的時候, 對事件進行相應的操作 */
                    uxControlBits |= eventWAIT_FOR_ALL_BITS; /*0x04000000UL 等待所有位*/
                }

                /* 當前 task 進入該事件組的 xTasksWaitingForBits 中,  task 將被 blocking 指定時間 xTicksToWait !!! */
                vTaskPlaceOnUnorderedEventList( &( pxEventBits->xTasksWaitingForBits ), ( uxBitsToWaitFor | uxControlBits ), xTicksToWait );

                uxReturn = 0;

                traceEVENT_GROUP_WAIT_BITS_BLOCK( xEventGroup, uxBitsToWaitFor );
            }
        }
        /* 恢復 task 調度 */
        xAlreadyYielded = xTaskResumeAll();

        /* xTicksToWait 為 0 時不執行
         *  case 1: 本身設置的為 0
         *  case 2: 符合的事件觸發後被清 0
         */
        if( xTicksToWait != ( TickType_t ) 0 )
        {
            /* 恢復 task 後, 還沒有進行 task 切換 */
            if( xAlreadyYielded == pdFALSE )
            {
                /* 進行一次 task 切換!!! */
                portYIELD_WITHIN_API();
            }

            /* 進入到這裡說明當前的 task 已經被重新調度了 !
             *  case 1: 符合的事件被觸發
             *  case 2: 事件等待超時
             */
            uxReturn = uxTaskResetEventItemValue();

            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
            {
                /* 進入臨界區 */
                taskENTER_CRITICAL();
                {
                    /* 超時返回時, 直接返回當前事件的 "所有" 標志位!!! */
                    uxReturn = pxEventBits->uxEventBits;

                    /* 再判斷一次是否發生了事件 */
                    if( prvTestWaitCondition( uxReturn, uxBitsToWaitFor, xWaitForAllBits ) != pdFALSE )
                    {
                        /* 若設置了退出的時候, 需要清除對應的事件標志位 */
                        if( xClearOnExit != pdFALSE )
                        {
                            /* 清除事件標志位並且返回 */
                            pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
                        }
                    }
                }
                /* 退出臨界區 */
                taskEXIT_CRITICAL();

                /* 在未使用跟蹤宏時, 防止編譯器警告 */
                xTimeoutOccurred = pdFALSE;
            }
            else
            {
                /* 因為已經設置了位, 所以 task 解除了阻塞 */
            }

            /* 清除內核使用的事件位 (High 8-bits) */
            uxReturn &= ~eventEVENT_BITS_CONTROL_BYTES; /* 0xff000000UL */
        }

        return uxReturn;
    }
    ```

+ Example usage

    ```c
    #define BIT_0   ( 1 << 0 )
    #define BIT_4   ( 1 << 4 )

    void aFunction( EventGroupHandle_t xEventGroup )
    {
        EventBits_t         uxBits;
        const TickType_t    xTicksToWait = 100 / portTICK_PERIOD_MS;

        /* Wait a maximum of 100ms for either bit 0 or bit 4 to be set within
         * the event group.  Clear the bits before exiting.
         */
        uxBits = xEventGroupWaitBits(
                     xEventGroup,   /* The event group being tested. */
                     BIT_0 | BIT_4, /* The bits within the event group to wait for. */
                     pdTRUE,        /* BIT_0 & BIT_4 should be cleared before returning. */
                     pdFALSE,       /* Don't wait for both bits, either bit will do. */
                     xTicksToWait );/* Wait a maximum of 100ms for either bit to be set. */

        if( ( uxBits & ( BIT_0 | BIT_4 ) ) == ( BIT_0 | BIT_4 ) )
        {
            /* xEventGroupWaitBits() returned because both bits were set. */
        }
        else if( ( uxBits & BIT_0 ) != 0 )
        {
            /* xEventGroupWaitBits() returned because just BIT_0 was set. */
        }
        else if( ( uxBits & BIT_4 ) != 0 )
        {
            /* xEventGroupWaitBits() returned because just BIT_4 was set. */
        }
        else
        {
            /* xEventGroupWaitBits() returned because xTicksToWait ticks passed
            without either BIT_0 or BIT_4 becoming set. */
        }
    }
    ```

## Set and Clear

+ Set Bits

    ```c
    EventBits_t xEventGroupSetBits( EventGroupHandle_t xEventGroup,
                                    const EventBits_t uxBitsToSet );

    BaseType_t xEventGroupSetBitsFromISR( EventGroupHandle_t xEventGroup,
                                          const EventBits_t uxBitsToSet,
                                          BaseType_t * pxHigherPriorityTaskWoken );
    ```

    - **xEventGroupSetBits**

        ```c
        EventBits_t xEventGroupSetBits( EventGroupHandle_t xEventGroup, const EventBits_t uxBitsToSet )
        {
            ListItem_t *pxListItem, *pxNext;
            ListItem_t const *pxListEnd;
            List_t *pxList;
            EventBits_t uxBitsToClear = 0, uxBitsWaitedFor, uxControlBits;
            EventGroup_t *pxEventBits = ( EventGroup_t * ) xEventGroup; /* 指定的事件標志組 */
            BaseType_t xMatchFound = pdFALSE;

            configASSERT( xEventGroup );
            /* Assert 判斷要設置的事件標志位是否有效, 防止用戶使用 High 8-bits */
            configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );/* 0xff000000UL */

            /* 獲取事件標志組的等待位列表 */
            pxList = &( pxEventBits->xTasksWaitingForBits );

            /* 獲取列表的末尾項 */
            pxListEnd = listGET_END_MARKER( pxList );

            /*先停止 task 調度*/
            vTaskSuspendAll();
            {
                /* 獲取列表的首項 */
                pxListItem = listGET_HEAD_ENTRY( pxList );

                /* 指定的事件標志組的事件位, 設置事件標志 */
                pxEventBits->uxEventBits |= uxBitsToSet;

                /* 設置這個事件標志位可能是某個 task 在等待的事件, 就遍歷等待事件列表中的 task  */
                while( pxListItem != pxListEnd )
                {
                    /* 從列表首項開始檢查 */
                    pxNext = listGET_NEXT( pxListItem );
                    /* 獲取列表的值 */
                    uxBitsWaitedFor = listGET_LIST_ITEM_VALUE( pxListItem );
                    xMatchFound = pdFALSE;

                    /* 將等待的位從控制位中分離出來*/  /* 0xff000000UL */
                    uxControlBits = uxBitsWaitedFor & eventEVENT_BITS_CONTROL_BYTES;  /* 控制位 */
                    uxBitsWaitedFor &= ~eventEVENT_BITS_CONTROL_BYTES;                /* 等待位 */

                     /* 0x04000000UL */
                    if( ( uxControlBits & eventWAIT_FOR_ALL_BITS ) == ( EventBits_t ) 0 )
                    {
                        /* 只需要有一個事件標志位滿足即可(等待所有的位沒有被標記) */
                        /* 判斷要等待的事件是否發生了 */
                        if( ( uxBitsWaitedFor & pxEventBits->uxEventBits ) != ( EventBits_t ) 0 )
                        {
                            xMatchFound = pdTRUE; /* 事件符合 */
                        }
                    }
                    else if( ( uxBitsWaitedFor & pxEventBits->uxEventBits ) == uxBitsWaitedFor )
                    {
                        /* 所有事件都發生的時候才能解除阻塞 */
                        xMatchFound = pdTRUE; /*事件符合*/
                    }
                    else
                    {
                        /* Need all bits to be set, but not all the bits were set. */
                    }

                    if( xMatchFound != pdFALSE )
                    {
                        /* 匹配了標志位, 然後看下是否需要清除標志位 */
                        if( ( uxControlBits & eventCLEAR_EVENTS_ON_EXIT_BIT ) != ( EventBits_t ) 0 )
                        {
                            /* 記錄下需要清除的標志位, 等遍歷完隊列之後統一處理 */
                            uxBitsToClear |= uxBitsWaitedFor;
                        }

                        /* 將滿足事件條件的 task 從等待列表中移除, 並且添加到就緒列表中 */
                        ( void ) xTaskRemoveFromUnorderedEventList( pxListItem, pxEventBits->uxEventBits | eventUNBLOCKED_DUE_TO_BIT_SET );
                    }

                    /* 循環遍歷事件等待列表, 可能不止一個 task 在等待這個事件!!! */
                    pxListItem = pxNext;
                }

                /* 遍歷完畢, 清除事件標志位 */
                pxEventBits->uxEventBits &= ~uxBitsToClear;
            }
            ( void ) xTaskResumeAll();

            return pxEventBits->uxEventBits;
        }
        ```

    - **xEventGroupSetBitsFromISR**
        > 通過 Queue 告知 S/w timer task, 然後在 timer task 中實現 bit field 操作
        >> 由於該函數對 EventGroup 的操作是不確定性操作 (因為不知道當前有多少個 task 在等待此事件標志).
        而 FreeRTOS 不允許在 ISR 和 Critical Section 中執行不確定性操作.

        >> 為了不在 ISR 中執行, 就通過 xEventGroupSetBitsFromISR() 給 FreeRTOS 的 S/w Timer task 發送消息, 並在 timer task 執行 EventGroup 的 bit field 操作.
        同時也為了不在 Critical Section 中執行此不確定操作, 將 Critical Section 改成由調度鎖來完成.
        這樣不確定性操作在 ISR 和 Critical Section 中執行的問題就都得到解決了

        ```c
        #if ( ( configUSE_TRACE_FACILITY == 1 ) && ( INCLUDE_xTimerPendFunctionCall == 1 ) && ( configUSE_TIMERS == 1 ) )

            BaseType_t xEventGroupSetBitsFromISR( EventGroupHandle_t xEventGroup,
                            const EventBits_t uxBitsToSet, BaseType_t *pxHigherPriorityTaskWoken )
            {
                BaseType_t xReturn;

                xReturn = xTimerPendFunctionCallFromISR( vEventGroupSetBitsCallback,
                                ( void * ) xEventGroup, ( uint32_t ) uxBitsToSet, pxHigherPriorityTaskWoken );

                return xReturn;
            }

        #endif

        void vEventGroupSetBitsCallback( void *pvEventGroup, const uint32_t ulBitsToSet )
        {
            ( void ) xEventGroupSetBits( pvEventGroup, ( EventBits_t ) ulBitsToSet );
        }

        BaseType_t xTimerPendFunctionCallFromISR( PendedFunction_t xFunctionToPend,
                                                  void * pvParameter1,
                                                  uint32_t ulParameter2,
                                                  BaseType_t * pxHigherPriorityTaskWoken )
        {
            DaemonTaskMessage_t xMessage;
            BaseType_t xReturn;

            /*  設置消息的參數 */
            xMessage.xMessageID = tmrCOMMAND_EXECUTE_CALLBACK_FROM_ISR;
            xMessage.u.xCallbackParameters.pxCallbackFunction = xFunctionToPend;
            xMessage.u.xCallbackParameters.pvParameter1 = pvParameter1;
            xMessage.u.xCallbackParameters.ulParameter2 = ulParameter2;

            /* 發送消息隊列到 S/w timer task */
            xReturn = xQueueSendFromISR( xTimerQueue, &xMessage, pxHigherPriorityTaskWoken );

            return xReturn;
        }
        ```

        1. Example usage

            ```c
            #define BIT_0    ( 1 << 0 )
            #define BIT_4    ( 1 << 4 )

            /* An event group which it is assumed has already been created by a call to
             * xEventGroupCreate().
             */
            EventGroupHandle_t  xEventGroup;

            void ISR_Handler( void )
            {
                BaseType_t  xHigherPriorityTaskWoken, xResult;

                /* xHigherPriorityTaskWoken must be initialised to pdFALSE. */
                xHigherPriorityTaskWoken = pdFALSE;

                /* Set bit 0 and bit 4 in xEventGroup. */
                xResult = xEventGroupSetBitsFromISR(
                              xEventGroup,   /* The event group being updated. */
                              BIT_0 | BIT_4, /* The bits being set. */
                              &xHigherPriorityTaskWoken );

                /* Was the message posted successfully? */
                if( xResult != pdFAIL )
                {
                    /* If xHigherPriorityTaskWoken is now set to pdTRUE then a context
                     * switch should be requested.  The macro used is port specific and will
                     * be either portYIELD_FROM_ISR() or portEND_SWITCHING_ISR() - refer to
                     * the documentation page for the port being used.
                     */
                    portYIELD_FROM_ISR( xHigherPriorityTaskWoken );
                }
            }
            ```

+ Clear Bits

    ```c
    EventBits_t xEventGroupClearBits( EventGroupHandle_t xEventGroup,
                                      const EventBits_t uxBitsToClear );

    BaseType_t xEventGroupClearBitsFromISR( EventGroupHandle_t xEventGroup,
                                            const EventBits_t uxBitsToClear );
    ```

+ Example usage



## **xEventGroupSync**

有時應用程序需要兩個或多個 tasks 彼此同步.

例如, task_A 接收事件, 將事件所需的一些處理委託給 task_B/task_C/task_D 三個 task, 如果 task_A 在其他三個 task 沒有完成當前事件的處理時無法接收下一個事件, 此時四個 tasks 就需要彼此同步.
> 每個 task 執行到同步點後, 將在此等待其他 task 完成處理, 並到達相應的同步點後才能繼續執行, 如此 task_A 只能在其他 task 都達到同步點後, 才能接收另一個事件.

EventGroup 可用於創建同步點, 並同步多個 tasks:
> + 必須為每個參與同步的 task 分配唯一的事件位.
> + 每個 task 在到達同步點時設置自己的事件位.
> + 設置自己的事件位後, 事件組上的每個 task 都會阻塞, 以等待代表其他同步 task 的事件位被設置.

但是在這個方案中**不能使用 xEventGroupSetBits() 和 xEventGroupWaitBits()**.
> 如果使用它們, 那麼設置一個 bit(表示 task 已達到同步點)和測試 bits(確定其他 task 是否已到達同步點)將會是兩個單獨的操作. 例如:
>> + task_A 和 task_B 已到達同步點, 因此它們的事件位被設置, 並且它們都處於阻塞態等待 task_C 到達同步點.
>> + task_C 到達同步點, 並調用 xEventGroupSetBits() 設置事件組中的 event bit 一旦設置了 task_C 的事件位,  task_A 和 task_B 就會離開 blocking, 並清除這三個 event bits.
>> + task_C 調用 xEventGroupWaitBits() 等待三個事件位, 但那時, 三個這三個事件位已被清除, task_A 和 task_B 已經離開了各自的同步點, 因此同步失敗.

要成功使用 EventGroup 來創建同步點, 事件位的設置以及事件位的測試, 必須作為單個不間斷操作執行, 為此, FreeRTOS 提供了 xEventGroupSync()

+ prototype
    > 提供使用 EventGroup 彼此同步兩個或多個 tasks 的功能.
    該函數作為單一的操作, 允許 task 在 EventGroup 中設置一個或多個 event bits, 然後等待 event bits 在同一 EventGroup 中被設置

    ```c
    EventBits_t xEventGroupSync( EventGroupHandle_t xEventGroup,
                                 const EventBits_t uxBitsToSet,
                                 const EventBits_t uxBitsToWaitFor,
                                 TickType_t xTicksToWait );
    ```

+ Source code

    ```c
    EventBits_t xEventGroupSync( EventGroupHandle_t xEventGroup, const EventBits_t uxBitsToSet,
                        const EventBits_t uxBitsToWaitFor, TickType_t xTicksToWait )
    {
        EventBits_t uxOriginalBitValue, uxReturn;
        EventGroup_t *pxEventBits = ( EventGroup_t * ) xEventGroup;
        BaseType_t xAlreadyYielded;
        BaseType_t xTimeoutOccurred = pdFALSE;

        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
        configASSERT( uxBitsToWaitFor != 0 );

        /* 如果使能函數 xTaskGetSchedulerState() 或 啟動軟件定時器功能 */
        #if ( ( INCLUDE_xTaskGetSchedulerState == 1 ) || ( configUSE_TIMERS == 1 ) )
        {
            configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
        }
        #endif

        vTaskSuspendAll();	/* 掛起調度器 */
        {
            uxOriginalBitValue = pxEventBits->uxEventBits;	/* 記錄原有 event bits */

            /* 將 event bit 設為 1 */
            ( void ) xEventGroupSetBits( xEventGroup, uxBitsToSet );

            /* 如果所有等待的 event bit 都為 1 */
            if( ( ( uxOriginalBitValue | uxBitsToSet ) & uxBitsToWaitFor ) == uxBitsToWaitFor )
            {
                uxReturn = ( uxOriginalBitValue | uxBitsToSet );

                pxEventBits->uxEventBits &= ~uxBitsToWaitFor;	/* 清除事件位 */

                xTicksToWait = 0;
            }
            else
            {
                /* 如果設置阻塞時間 xTicksToWait 不為 0 */
                if( xTicksToWait != ( TickType_t ) 0 )
                {
                    /* 將 task 添加到相應的 EventList 中 */
                    vTaskPlaceOnUnorderedEventList( &( pxEventBits->xTasksWaitingForBits ), ( uxBitsToWaitFor | eventCLEAR_EVENTS_ON_EXIT_BIT | eventWAIT_FOR_ALL_BITS ), xTicksToWait );

                    uxReturn = 0;
                }
                else
                {
                    uxReturn = pxEventBits->uxEventBits;
                }
            }
        }
        xAlreadyYielded = xTaskResumeAll();	/* 恢復調度器，有可能進行 task 切換 */

        /* 如果設置阻塞時間 xTicksToWait 不為 0 */
        if( xTicksToWait != ( TickType_t ) 0 )
        {
            /* 如果沒有進行任務切換 */
            if( xAlreadyYielded == pdFALSE )
            {
                portYIELD_WITHIN_API();
            }

            /* 獲取事件列表項的項值 */
            uxReturn = uxTaskResetEventItemValue();

            /* eventUNBLOCKED_DUE_TO_BIT_SET 用來任務已經解掛 */
            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
            {
                /* 進入臨界區 */
                taskENTER_CRITICAL();
                {
                    uxReturn = pxEventBits->uxEventBits;

                    /* 如果設置事件退出時清除事件位 */
                    if( ( uxReturn & uxBitsToWaitFor ) == uxBitsToWaitFor )
                    {
                        pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
                    }
                }
                taskEXIT_CRITICAL();	/* 退出臨界區 */

                xTimeoutOccurred = pdTRUE;
            }
            else
            {
                /* 執行到這裡, 表示任務已經解除阻塞態 */
            }

            uxReturn &= ~eventEVENT_BITS_CONTROL_BYTES;	/* 清除高 8 位的控制位 */
        }

        return uxReturn;
    }
    ```

+ Example usage

    ```c
    /* 定義 EventGroup 中 event field 的意義 */
    #define main_1st_TASK_BIT ( 1UL << 0UL )
    #define main_2nd_TASK_BIT( 1UL << 1UL )
    #define main_3th_TASK_BIT ( 1UL << 2UL )

    /* EventGroup handle */
    EventGroupHandle_t  xEventGroup;

    /* 任務函數 */
    static void vSyncingTask( void *pvParameters )
    {
        const TickType_t    xMaxDelay = pdMS_TO_TICKS( 4000UL );
        const TickType_t    xMinDelay = pdMS_TO_TICKS( 200UL );
        TickType_t          xDelayTime;
        EventBits_t         uxThisTasksSyncBit;

        const EventBits_t   uxAllSyncBits = ( main_1st_TASK_BIT |
                                              main_2nd_TASK_BIT |
                                              main_3th_TASK_BIT );

        uxThisTasksSyncBit = ( EventBits_t ) pvParameters;

        for( ;; )
        {
            /* 隨機的延時，防止單個任務一直同時到達同步點
             * (用於模擬每個任務處理事件的時間不同)
             */
            xDelayTime = ( rand() % xMaxDelay ) + xMinDelay;
            vTaskDelay( xDelayTime );

            vPrintTwoStrings( pcTaskGetTaskName( NULL ), "reached sync point" );

            /* 等待同步 */
            xEventGroupSync( xEventGroup,
                             uxThisTasksSyncBit, /* 表示這個 task 到達同步點時, 需要設置的 bit field */
                             uxAllSyncBits,      /* 需要等待同步的所有 bit field */
                             portMAX_DELAY );
            vPrintTwoStrings( pcTaskGetTaskName( NULL ), "exited sync point" );
        }
    }

    int main( void )
    {
        /* 創建用於同步的事件組 */
        xEventGroup = xEventGroupCreate();
        /* 創建三個任務 */
        xTaskCreate( vSyncingTask, "Task 1", 1000, main_1st_TASK_BIT, 1, NULL );
        xTaskCreate( vSyncingTask, "Task 2", 1000, main_2nd_TASK_BIT, 1, NULL );
        xTaskCreate( vSyncingTask, "Task 3", 1000, main_3th_TASK_BIT, 1, NULL );
        vTaskStartScheduler();
        for( ;; );
        return 0;
    }
    ```

## MISC

## Example usage

```c
/* 定義事件位的意義 */
#define main_1st_TASK_BIT   ( 1UL << 0UL )
#define main_2nd_TASK_BIT   ( 1UL << 1UL )
#define mainISR_BIT         ( 1UL << 2UL )

/* 設置事件位的任務 */
static void vEventBitSettingTask( void *pvParameters )
{
    const TickType_t xDelay200ms = pdMS_TO_TICKS( 200UL ), xDontBlock = 0;
    for( ;; )
    {
        vTaskDelay( xDelay200ms );

        /* 設置 bit 0 */
        vPrintString( "Bit setting task -\t about to set bit 0.\r\n" );
        xEventGroupSetBits( xEventGroup, main_1st_TASK_BIT );

        vTaskDelay( xDelay200ms );

        /* 設置 bit 1 */
        vPrintString( "Bit setting task -\t about to set bit 1.\r\n" );
        xEventGroupSetBits( xEventGroup, main_2nd_TASK_BIT );
    }
}

/* ISR */
static uint32_t ulEventBitSetting_ISR( void )
{
    static const char   *pcString = "Bit setting ISR -\t about to set bit 2.\r\n";
    BaseType_t          xHigherPriorityTaskWoken = pdFALSE;

    /* ISR 中輸出提示信息 */
    xTimerPendFunctionCallFromISR(  vPrintStringFromDaemonTask,
                                    ( void * ) pcString,
                                    0,
                                    &xHigherPriorityTaskWoken );
    /* 設置 bit 2 */
    xEventGroupSetBitsFromISR( xEventGroup, mainISR_BIT, &xHigherPriorityTaskWoken );

    /* 根據 xHigherPriorityTaskWoken 判斷是否需要調度程序 */
    portYIELD_FROM_ISR( xHigherPriorityTaskWoken );
}

/* 獲取事件位的任務 */
static void vEventBitReadingTask( void *pvParameters )
{
    EventBits_t         xEventGroupValue;
    const EventBits_t   xBitsToWaitFor = ( main_1st_TASK_BIT |
                                           main_2nd_TASK_BIT |
                                           mainISR_BIT );
    for( ;; )
    {
        /* 獲取事件位 */
        xEventGroupValue = xEventGroupWaitBits( xEventGroup,    /* 事件組的句柄 */
                                                xBitsToWaitFor, /* 待測試的事件位 */
                                                pdTRUE,         /* 滿足添加時清除上面的事件位 */
                                                pdFALSE,        /* 任意事件位被設置就會退出阻塞態 */
                                                portMAX_DELAY );/* 沒有超時 */
        /* 根據相應的事件位輸出提示信息 */
        if( ( xEventGroupValue & main_1st_TASK_BIT ) != 0 )
            vPrintString( "Bit reading task -\t Event bit 0 was set\r\n" );

        if( ( xEventGroupValue & main_2nd_TASK_BIT ) != 0 )
            vPrintString( "Bit reading task -\t Event bit 1 was set\r\n" );

        if( ( xEventGroupValue & mainISR_BIT ) != 0 )
            vPrintString( "Bit reading task -\t Event bit 2 was set\r\n" );
    }
}


int main( void )
{
    /* 創建事件組 */
    xEventGroup = xEventGroupCreate();

    /* 設置事件組的任務 */
    xTaskCreate( vEventBitSettingTask, "Bit Setter", 1000, NULL, 1, NULL );
    /* 讀取事件組的任務 */
    xTaskCreate( vEventBitReadingTask, "Bit Reader", 1000, NULL, 2, NULL );
    /* 使用軟件模擬中斷 */
    xTaskCreate( vInterruptGenerator, "Int Gen", 1000, NULL, 3, NULL );

    vPortSetInterruptHandler( mainINTERRUPT_NUMBER, ulEventBitSetting_ISR );
    vTaskStartScheduler();
    for( ;; );
    return 0;
}
```

# reference

+ [FreeRTOS源碼探析之——事件標志組](https://zhuanlan.zhihu.com/p/320664678)
+ [FreeRTOS原理剖析：事件標志組](https://blog.csdn.net/qq_31782183/article/details/102301470?utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-6.control&dist_request_id=&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-6.control)
+ [FreeRTOS學習筆記十三【事件組】](https://blog.csdn.net/qq_25370227/article/details/86635919)
