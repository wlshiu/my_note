FreeRTOS Queue [[Back](note_freertos_guide.md)]
---

Queue 是 FreeRTOS 主要的 tasks 間通訊方式, 可以在 `task <-> task`, `interrupt <-> task` 間傳送信息
> 發送到 queue 的消息是通過拷貝實現的, 即 backup 在 Queue 裡

BinarySemaphores (二進制信號量), Semaphores (計數信號量), Mutex (互斥量) 和 RecursiveMutex (遞歸互斥量)都是使用 Queue 來實現的

# 變數定義

## Queue structure

```c
typedef struct QueueDefinition
{
    int8_t * pcHead;           /*< 指向 Queue 存儲區起始位置, 即第一個 Queue 項. */
    int8_t * pcWriteTo;        /*< 指向下 Queue 存儲區的下一個空閒位置. */

    /* 互斥,  只能擇一 */
    union {
        QueuePointers_t xQueue;     /*< 使用 queue . */
        SemaphoreData_t xSemaphore; /*< 使用 semaphore (藉由 queue 的方式來實現). */
    } u;

    List_t xTasksWaitingToSend;             /*< 等待 send/give 而阻塞的 task 列表, 按照優先級順序存儲. */
    List_t xTasksWaitingToReceive;          /*< 等待 receive/take 而阻塞的 task 列表, 按照優先級順序存儲. */

    volatile UBaseType_t uxMessagesWaiting; /*< 目前 Queue 內的 item 數目. */
    UBaseType_t uxLength;                   /*< item 的數目. */
    UBaseType_t uxItemSize;                 /*< 每個 item 的大小. */

    volatile int8_t cRxLock;                /*<  Queue 上鎖後, 存儲從 Queue 收到的列表項數目, 如果 Queue 沒有上鎖, 設置為 queueUNLOCKED. */
    volatile int8_t cTxLock;                /*<  Queue 上鎖後, 存儲發送到 Queue 的列表項數目, 如果 Queue 沒有上鎖, 設置為 queueUNLOCKED. */

    #if ( ( configSUPPORT_STATIC_ALLOCATION == 1 ) && ( configSUPPORT_DYNAMIC_ALLOCATION == 1 ) )
        uint8_t ucStaticallyAllocated; /*< 使用靜態 memory. */
    #endif

    #if ( configUSE_QUEUE_SETS == 1 )
        struct QueueDefinition * pxQueueSetContainer;
    #endif

    #if ( configUSE_TRACE_FACILITY == 1 )
        UBaseType_t uxQueueNumber;
        uint8_t ucQueueType;
    #endif
} xQUEUE;

typedef xQUEUE Queue_t;
```

![queue_struct](queue_struct.jpg)


+ prvLockQueue()/prvUnlockQueue()
    > 如果 watiing time 不為 0, 則 task 會因為等待 Enqueue 而進入 blocking.
    在將 task 設置為 blocking 的過程中, 是不希望有其它 task 和 ISR 操作這個 qeueu 的 **xTasksWaitingToReceive** 和 **xTasksWaitingToSend**;
    因為操作它們可能引起其它 task 解除 blocking, 這可能會發生優先級翻轉. 因此 FreeRTOS 使用 **vTaskSuspendAll()** 來簡單粗暴的禁止其它 task 操作 queue (停止切換 tasks).
    >> **優先級翻轉**: 比如 task A 的優先級低於本 task, 但是在本 task 進入 blocking 的過程中, task A 卻因為其它原因解除 blocking 了, 這顯然是要絕對禁止的.


    > 但 **vTaskSuspendAll()** 並不會禁止中斷, ISR 仍然可以操作 **xTasksWaitingToReceive** 和 **xTasksWaitingToSend**, 也可能會解除 task 阻塞或進行切換 task, 這是不允許的.
    於是, 解決辦法是不但 Suspend 調度器, 還要給 queue 上鎖.
    >> 在 ISR 操作 Queue 並且導致阻塞的 task 解除阻塞時, 會首先判斷該 Queue 是否上鎖,
    如果沒有上鎖, 則解除被 block 的 task, 還會根據需要設置上下文切換請求 flag.
    如果 Queue 已經上鎖, 則不會解除被 block 的 task, 取而代之的是, 將 cRxLock 或 cTxLock 加 1, 表示 Queue 上鎖期間 dequeue 或 enqueue 的數目, 也表示有 task 可以解除阻塞了.

    > 有將 Queue 上鎖操作, 就會有解除 Queue 鎖操作.
    prvUnlockQueue() 用於解除 Queue 鎖, 將可以解除 blocking 的 task 插入到 ready list of tasks, 解除 task 的最大數量由 xRxLock 和 xTxLock 指定

# Queue API


+ xQueueCreate/xQueueCreateStatic
    > create a queue

    - xQueueCreate

        ```c
        #define xQueueCreate( uxQueueLength, uxItemSize )    xQueueGenericCreate( ( uxQueueLength ), ( uxItemSize ), ( queueQUEUE_TYPE_BASE ) )
        ```

    - xQueueCreateStatic

        ```c
        #define xQueueCreateStatic( uxQueueLength, uxItemSize, pucQueueStorage, pxQueueBuffer )    \
                    xQueueGenericCreateStatic( ( uxQueueLength ), ( uxItemSize ), ( pucQueueStorage ), ( pxQueueBuffer ), ( queueQUEUE_TYPE_BASE ) )
        ```

+ vQueueDelete
    > delete a queue

    ```c
    void vQueueDelete( QueueHandle_t xQueue );
    ```

+ xQueueSend
    > 將 item 接到 Queue 的後面

    ```c
    #define xQueueSend( xQueue, pvItemToQueue, xTicksToWait ) \
                xQueueGenericSend( ( xQueue ), ( pvItemToQueue ), ( xTicksToWait ), queueSEND_TO_BACK )

    #define xQueueSendFromISR( xQueue, pvItemToQueue, pxHigherPriorityTaskWoken ) \
                xQueueGenericSendFromISR( ( xQueue ), ( pvItemToQueue ), ( pxHigherPriorityTaskWoken ), queueSEND_TO_BACK )
    ```

    - xQueueSendToBack
        > 等同於 **xQueueSend()**

        ```c
        #define xQueueSendToBack( xQueue, pvItemToQueue, xTicksToWait ) \
                    xQueueGenericSend( ( xQueue ), ( pvItemToQueue ), ( xTicksToWait ), queueSEND_TO_BACK )

        #define xQueueSendToBackFromISR( xQueue, pvItemToQueue, pxHigherPriorityTaskWoken ) \
                    xQueueGenericSendFromISR( ( xQueue ), ( pvItemToQueue ), ( pxHigherPriorityTaskWoken ), queueSEND_TO_BACK )
        ```

        1. Example usage

            ```c
            void vBufferISR( void )
            {
                char        cIn;
                BaseType_t  xHigherPrioritTaskWoken;

                // We have not woken a task at the start of the ISR.
                xHigherPriorityTaskWoken = pdFALSE;

                // Loop until the buffer is empty.
                do
                {
                    // Obtain a byte from the buffer.
                    cIn = portINPUT_BYTE( RX_REGISTER_ADDRESS );

                    // Post the byte.
                    xQueueSendToBackFromISR( xRxQueue, &cIn, &xHigherPriorityTaskWoken );

                } while( portINPUT_BYTE( BUFFER_COUNT ) );

                // Now the buffer is empty we can switch context if necessary.
                if( xHigherPriorityTaskWoken )
                {
                    taskYIELD ();
                }
            }
            ```

    - xQueueSendToFront
        > 將 item 接在 Queue 的前面

        ```c
        #define xQueueSendToFront( xQueue, pvItemToQueue, xTicksToWait ) \
                    xQueueGenericSend( ( xQueue ), ( pvItemToQueue ), ( xTicksToWait ), queueSEND_TO_FRONT )

        #define xQueueSendToFrontFromISR( xQueue, pvItemToQueue, pxHigherPriorityTaskWoken ) \
                    xQueueGenericSendFromISR( ( xQueue ), ( pvItemToQueue ), ( pxHigherPriorityTaskWoken ), queueSEND_TO_FRONT )
        ```

        1. Example usage

            ```c
            void vBufferISR( void )
            {
                char        cIn;
                BaseType_t  xHigherPrioritTaskWoken;

                // We have not woken a task at the start of the ISR.
                xHigherPriorityTaskWoken = pdFALSE;

                // Loop until the buffer is empty.
                do
                {
                    // Obtain a byte from the buffer.
                    cIn = portINPUT_BYTE( RX_REGISTER_ADDRESS );

                    // Post the byte.
                    xQueueSendToFrontFromISR( xRxQueue, &cIn, &xHigherPriorityTaskWoken );

                } while( portINPUT_BYTE( BUFFER_COUNT ) );

                // Now the buffer is empty we can switch context if necessary.
                if( xHigherPriorityTaskWoken )
                {
                    taskYIELD ();
                }
            }
            ```

+ xQueueReceive
    > 從 Queue 接收

    ```c
    BaseType_t xQueueReceive( QueueHandle_t xQueue,
                              void * const pvBuffer,
                              TickType_t xTicksToWait );

    BaseType_t xQueueReceiveFromISR( QueueHandle_t xQueue,
                                 void * const pvBuffer,
                                 BaseType_t * const pxHigherPriorityTaskWoken )
    ```

    1. Example usage

        ```c
        QueueHandle_t   xQueue;

        /* Function to create a queue and post some values. */
        void vAFunction( void *pvParameters )
        {
            char cValueToPost;
            const TickType_t xTicksToWait = ( TickType_t )0xff;

            /* Create a queue capable of containing 10 characters. */
            xQueue = xQueueCreate( 10, sizeof( char ) );
            if( xQueue == 0 )
            {
                /* Failed to create the queue. */
            }

            ...

            /* Post some characters that will be used within an ISR.
             * If the queue is full then this task will block for xTicksToWait ticks.
             */
            cValueToPost = 'a';
            xQueueSend( xQueue, ( void * ) &cValueToPost, xTicksToWait );
            cValueToPost = 'b';
            xQueueSend( xQueue, ( void * ) &cValueToPost, xTicksToWait );

            /* ... keep posting characters ...
             * this task may block when the queue becomes full.
             */
            cValueToPost = 'c';
            xQueueSend( xQueue, ( void * ) &cValueToPost, xTicksToWait );
        }

        /* ISR that outputs all the characters received on the queue. */
        void vISR_Routine( void )
        {
            BaseType_t xTaskWokenByReceive = pdFALSE;
            char cRxedChar;

            while( xQueueReceiveFromISR( xQueue,
                                         ( void * ) &cRxedChar,
                                         &xTaskWokenByReceive) )
            {
                /* A character was received.  Output the character now. */
                vOutputCharacter( cRxedChar );

                /* If removing the character from the queue woke the task that was
                posting onto the queue xTaskWokenByReceive will have been set to
                pdTRUE.  No matter how many times this loop iterates only one
                task will be woken. */
            }

            if( xTaskWokenByReceive != pdFALSE )
            {
                /* We should switch context so the ISR returns to a different task.
                NOTE:  How this is done depends on the port you are using.  Check
                the documentation and examples for your port. */
                taskYIELD ();
            }
        }
        ```

+ uxQueueMessagesWaiting
    > 回傳在 Queue 中, 有效的 item 數目

    ```c
    UBaseType_t uxQueueMessagesWaiting( const QueueHandle_t xQueue );

    UBaseType_t uxQueueMessagesWaitingFromISR( const QueueHandle_t xQueue );
    ```

    - Example usage

        ```c
        // uxQueueMessagesWaiting Demo
        int dummy_value = 3;
        xQueueHandle demo_queue = xQueueCreate(5, sizeof(int));

        // Initial size is 0
        if (demo_queue != NULL)
        {
            unsigned int q_size = uxQueueMessagesWaiting(demo_queue);
            // Output q_size here; should be 0
        }

        // Push 3 items
        portBASE_TYPE xStatus;
        xStatus = xQueueSendToBack(demo_queue, &dummy_value, 0);
        xStatus = xQueueSendToBack(demo_queue, &dummy_value, 0);
        xStatus = xQueueSendToBack(demo_queue, &dummy_value, 0);

        // New size is 3
        if (xStatus == pdPASS)
        {
            unsigned int q_size = uxQueueMessagesWaiting(demo_queue);
            // Output q_size here; should be 3
        }
        ```

+ uxQueueSpacesAvailable
    > Queue 還剩多少空閒可使用的 item 數目

    ```c
    UBaseType_t uxQueueSpacesAvailable( const QueueHandle_t xQueue );
    ```

+ xQueueReset
    > 將 queue 回復到初始狀態 (always returns pdPASS)

    ```c
    #define xQueueReset( xQueue )    xQueueGenericReset( xQueue, pdFALSE )
    ```

+ xQueuePeek
    > 從 Queue 中讀取一個 item, 但不會把該 item 從 Queue 中移除

    ```
    BaseType_t xQueuePeek( QueueHandle_t xQueue,
                           void * const pvBuffer,
                           TickType_t xTicksToWait );

    BaseType_t xQueuePeekFromISR( QueueHandle_t xQueue,
                                  void * const pvBuffer );
    ```

    - Example usage

        ```c
        struct AMessage
        {
            char ucMessageID;
            char ucData[ 20 ];
        } xMessage;

        QueueHandle_t   xQueue;

        // Task to create a queue and post a value.
        void vATask( void *pvParameters )
        {
            struct AMessage     *pxMessage;

            /* Create a queue capable of containing 10 pointers to AMessage structures.
             * These should be passed by pointer as they contain a lot of data.
             */
            xQueue = xQueueCreate( 10, sizeof(struct AMessage*) );
            if( xQueue == 0 )
            {
                // Failed to create the queue.
            }

            ...

            /* Send a pointer to a struct AMessage object.
             * Don't block if the queue is already full.
             */
            pxMessage = &xMessage;
            xQueueSend( xQueue, (void*) &pxMessage, (TickType_t) 0 );

            // ... Rest of task code.
        }

        // Task to peek the data from the queue.
        void vADifferentTask( void *pvParameters )
        {
            struct AMessage     *pxRxedMessage;

            if( xQueue != 0 )
            {
                /* Peek a message on the created queue.
                 * Block for 10 ticks if a message is not immediately available.
                 */
                if( xQueuePeek( xQueue, &(pxRxedMessage), (TickType_t) 10 ) )
                {
                    /* pcRxedMessage now points to the struct AMessage variable posted by vATask,
                     * but the item still remains on the queue.
                     */
                }
            }

            // ... Rest of task code.
        }
        ```

+ vQueueAddToRegistry/vQueueUnregisterQueue/pcQueueGetName
    > 可以將 Queue handle 紀錄在 kernel space 中, 方便 debug (透過 Queue Name)
    >> 因為 semaphore 和 mutex 是繼承 Queue, 此 functions 也可以用來追蹤 semaphore/mutex

    ```c
    #define configQUEUE_REGISTRY_SIZE       6   /* configQUEUE_REGISTRY_SIZE 需大於 0 */

    void vQueueAddToRegistry( QueueHandle_t xQueue,
                              onst char * pcQueueName );

    void vQueueUnregisterQueue( QueueHandle_t xQueue );

    const char * pcQueueGetName( QueueHandle_t xQueue );
    ```


+ xQueueIsQueueEmptyFromISR
+ xQueueIsQueueFullFromISR

+ xQueueOverwrite
    > 通常用於 `uxQueueLength = 1`, 是 **xQueueSendToBack()**的另一個版本.
    enqueue 到 Queue 的尾巴, 如果 queue 已滿, 則覆寫之前的 itme

    ```c
    #define xQueueOverwrite( xQueue, pvItemToQueue ) \
                xQueueGenericSend( ( xQueue ), ( pvItemToQueue ), 0, queueOVERWRITE );

    #define xQueueOverwriteFromISR( xQueue, pvItemToQueue, pxHigherPriorityTaskWoken ) \
                xQueueGenericSendFromISR( ( xQueue ), ( pvItemToQueue ), ( pxHigherPriorityTaskWoken ), queueOVERWRITE );
    ```


## Example usage

```c
struct AMessage
{
    char ucMessageID;
    char ucData[ 20 ];
} xMessage;

QueueHandle_t   xStructQueue = NULL;
QueueHandle_t   xPointerQueue = NULL;


void vCreateQueues( void )
{
    xMessage.ucMessageID = 0xab;
    memset( &( xMessage.ucData ), 0x12, 20 );

    xStructQueue = xQueueCreate(
                       /* The number of items the queue can hold. */
                       10,
                       /* Size of each item is big enough to hold the whole structure. */
                       sizeof( xMessage ) );

    xPointerQueue = xQueueCreate(
                        /* The number of items the queue can hold. */
                        10,
                        /* Size of each item is big enough to hold only a pointer. */
                        sizeof( &xMessage ) );

    if( ( xStructQueue == NULL ) || ( xPointerQueue == NULL ) )
    {
        /* One or more queues were not created successfully as there was not enough heap memory available.
         * Handle the error here.  Queues can also be created statically.
         */
    }
}

/* Task that writes to the queues. */
void vTask_1( void *pvParameters )
{
    struct AMessage *pxPointerToxMessage;

    /* Send the entire structure to the queue created to hold 10 structures. */
    xQueueSend(
        xStructQueue, /* The handle of the queue. */
        /* The address of the xMessage variable.
         * sizeof(struct AMessage) bytes are copied from here into the queue.
         */
        ( void * ) &xMessage,
        /* Block time of 0 says don't block if the queue is already full.
         * Check the value returned by xQueueSend() to know if the message
         * was sent to the queue successfully.
         */
        ( TickType_t ) 0 );

    /* Store the address of the xMessage variable in a pointer variable. */
    pxPointerToxMessage = &xMessage;

    /* Send the address of xMessage to the queue created to hold 10 pointers. */
    xQueueSend(
        xPointerQueue,  /* The handle of the queue. */
        /* The address of the variable that holds the address of xMessage.
         * sizeof( &xMessage ) bytes are copied from here into the queue.
         * As the variable holds the address of xMessage it is the address of xMessage
         * that is copied into the queue.
         */
        ( void * ) &pxPointerToxMessage,
        ( TickType_t ) 0 );

    /* ... Rest of task code goes here. */
}

/* Task that reads from the queues. */
void vTask_2( void *pvParameters )
{
    struct AMessage xRxedStructure, *pxRxedPointer;

    if( xStructQueue != NULL )
    {
        /* Receive a message from the created queue to hold complex struct AMessage structure.
         * Block for 10 ticks if a message is not immediately available.
         * The value is read into a struct AMessage variable, so after calling
         * xQueueReceive() xRxedStructure will hold a copy of xMessage.
         */
        if( xQueueReceive( xStructQueue,
                           &( xRxedStructure ),
                           ( TickType_t ) 10 ) == pdPASS )
        {
            /* xRxedStructure now contains a copy of xMessage. */
        }
    }

    if( xPointerQueue != NULL )
    {
        /* Receive a message from the created queue to hold pointers.
         * Block for 10 ticks if a message is not immediately available.
         * The value is read into a pointer variable, and as the value received is the address of the xMessage variable,
         * after this call pxRxedPointer will point to xMessage.
         */
        if( xQueueReceive( xPointerQueue,
                           &( pxRxedPointer ),
                           ( TickType_t ) 10 ) == pdPASS )
        {
            /* *pxRxedPointer now points to xMessage. */
        }
    }

    /* ... Rest of task code goes here. */
}
```

# xQueueGenericSend

```c
/* 精簡 source code */
BaseType_t
xQueueGenericSend(
    QueueHandle_t xQueue,
    const void * const pvItemToQueue,
    TickType_t xTicksToWait,
    const BaseType_t xCopyPosition )
{
    BaseType_t xEntryTimeSet = pdFALSE,  xYieldRequired;
    TimeOut_t xTimeOut;
    Queue_t * const pxQueue = ( Queue_t * ) xQueue;

    for( ;; )
    {
        taskENTER_CRITICAL();
        {
            /*  Queue 還有空間?
             * 正在運行的 task 一定要比等待訪問 Queue 的 task 優先級高.
             * 如果使用 over-write 入隊, 則不需要關注 Queue 是否滿
             */
            if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
            {
                /* 完成數據拷貝工作, 分為 從 Queue 尾入隊/從 Queue 首入隊/覆蓋式入隊 */
                xYieldRequired = prvCopyDataToQueue( pxQueue,  pvItemToQueue,  xCopyPosition );

                /* 如果有 task 在此等待 Queue 數據到來, 則將該 task 解除阻塞 */
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
                {
                    /* 有 task 因等待出隊而阻塞, 則將 task 從 xTasksWaitingToReceive 接收列表中刪除, 然後加入到 ready 列表 */
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
                    {
                        /* 如果解除 blocking 的 task 有更高的優先級, 則當前 task 要讓出 CPU, 因此觸發一個上下文切換.
                         * 又因為現在還在臨界區, 要等退出臨界區 taskEXIT_CRITICAL() 後, 才會執行上下文切換.
                         */
                        queueYIELD_IF_USING_PREEMPTION();
                    }
                }
                else if( xYieldRequired != pdFALSE )
                {
                    /* 這個分支處理特殊情況 */
                    queueYIELD_IF_USING_PREEMPTION();
                }

                taskEXIT_CRITICAL();
                return pdPASS;
            }
            else
            {
                if( xTicksToWait == ( TickType_t ) 0 )
                {
                    /* 如果 Queue 滿並且沒有設置 timeout, 則直接退出 */
                    taskEXIT_CRITICAL();

                    /* 返回 Queue 滿錯誤碼 */
                    return errQUEUE_FULL;
                }
                else if( xEntryTimeSet == pdFALSE )
                {
                    /* Queue 滿並且設定了等待時間, 因此需要配置 timeout 結構體對象 */
                    vTaskInternalSetTimeOutState( &xTimeOut );
                    xEntryTimeSet = pdTRUE;
                }
            }
        }
        taskEXIT_CRITICAL();

        /* 退出臨界區, 至此, 中斷和其它 task 可以向這個 Queue 執行入隊(投遞)或出隊(讀取)操作.
         * 因為 Queue 滿,  task 無法入隊, 下面的代碼將當前 task 將阻塞在這個 Queue 上,
         * 在這段代碼執行過程中我們需要掛起調度器, 防止其它 task 操作 Queue 事件列表;
         * 掛起調度器雖然可以禁止其它 task 操作這個 Queue , 但並不能阻止中斷服務程序操作這個 Queue ,
         * 因此還需要將 Queue 上鎖, 防止中斷程序讀取 Queue 後, 使阻塞在出隊操作其它 task 解除阻塞,
         * 執行上下文切換(因為調度器掛起後, 不允許執行上下文切換)
         */
        vTaskSuspendAll();
        prvLockQueue( pxQueue );

        /* 查看 timeout 的超時時間是否到期 */
        if( xTaskCheckForTimeOut( &xTimeOut,  &xTicksToWait ) == pdFALSE )
        {
            if( prvIsQueueFull( pxQueue ) != pdFALSE )
            {
                /* timeout 時間未到期, 並且 Queue 仍然滿 */
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToSend ),  xTicksToWait );

                /* 解除 Queue 鎖, 如果有 task 要解除阻塞,
                 * 則將 task 移到掛起就緒列表中(因為當前調度器掛起, 所以不能移到 ready 列表)
                 */
                prvUnlockQueue( pxQueue );

                /* 恢復調度器, 將 task 從掛起就緒列表移到 ready 列表中*/
                if( xTaskResumeAll() == pdFALSE )
                {
                    portYIELD_WITHIN_API();
                }
            }
            else
            {
                /*  Queue 有空間, 重試 */
                prvUnlockQueue( pxQueue );
                ( void ) xTaskResumeAll();
            }
        }
        else
        {
            /* 超時時間到期, 返回 Queue 滿錯誤碼 */
            prvUnlockQueue( pxQueue );
            ( void ) xTaskResumeAll();

            traceQUEUE_SEND_FAILED( pxQueue );
            return errQUEUE_FULL;
        }
    }
}
```

+ Flow chart
![Flow_chart](QueueSend_flow.jpg)


# xQueueReceive

```c
/* 精簡 source code */
BaseType_t xQueueReceive( QueueHandle_t xQueue,
                          void * const pvBuffer,
                          TickType_t xTicksToWait )
{
    BaseType_t xEntryTimeSet = pdFALSE;
    TimeOut_t xTimeOut;
    Queue_t * const pxQueue = xQueue;

    for( ; ; )
    {
        taskENTER_CRITICAL();
        {
             // 獲取有效 msg 數目
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;

            if( uxMessagesWaiting > ( UBaseType_t ) 0 ) // 有 msg 存在
            {
                // 從隊列中拷貝數據到 pvBuffer
                prvCopyDataFromQueue( pxQueue, pvBuffer );

                /* 目前隊列中的有效 items 數減少一個 */
                pxQueue->uxMessagesWaiting = uxMessagesWaiting - ( UBaseType_t ) 1;

                // Queue 中有 task 等待發送而排隊
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
                {
                    /* task 從 xTasksWaitingToSend 搬移入 ready list
                     * 若使用 configUSE_TICKLESS_IDLE (tickless 機制),
                     * 需要刷新最新 task unblock 的時間 (xNextTaskUnblockTime)
                     */
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
                    {
                        /* 如果解除 blocking 的 task 有更高的優先級, 則當前 task 要讓出 CPU, 因此觸發一個上下文切換.
                         * 又因為現在還在臨界區, 要等退出臨界區 taskEXIT_CRITICAL() 後, 才會執行上下文切換.
                         */
                        queueYIELD_IF_USING_PREEMPTION();
                    }
                }

                taskEXIT_CRITICAL();
                return pdPASS;
            }
            else
            {
                if( xTicksToWait == ( TickType_t ) 0 ) // 沒有設置 timeout
                {
                    taskEXIT_CRITICAL();

                    /* 返回 Queue 空錯誤碼 */
                    return errQUEUE_EMPTY;
                }
                else if( xEntryTimeSet == pdFALSE )
                {
                    /* Queue 空的並且設定了等待時間, 因此需要配置 timeout 結構體對象 */
                    vTaskInternalSetTimeOutState( &xTimeOut );
                    xEntryTimeSet = pdTRUE;
                }
            }
        }
        taskEXIT_CRITICAL();

        vTaskSuspendAll();
        prvLockQueue( pxQueue );

        /* 查看 timeout 的超時時間是否到期 */
        if( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE )
        {
            if( prvIsQueueEmpty( pxQueue ) != pdFALSE ) // 沒有 timeout 且 Queue 空
            {
                /* 按優先級順序, 將目前的 task 的 xEventListItem 移到 xTasksWaitingToReceive,
                 * 而 xStateListItem 則移到 Delay List (沒 msg 可以處理, 所以讓出 CPU),
                 * 更新最新 task unblock 的時間 (xNextTaskUnblockTime)
                 */
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );

                /* 解除 Queue 鎖, 如果有 task 要解除阻塞,
                 * 則將 task 移到掛起就緒列表中(因為當前調度器掛起, 所以不能移到 ready 列表)
                 */
                prvUnlockQueue( pxQueue );

                /* 恢復調度器, 將 task 從掛起就緒列表移到 ready 列表中*/
                if( xTaskResumeAll() == pdFALSE )
                {
                    portYIELD_WITHIN_API();
                }
            }
            else
            {
                /*  Queue 有 msg, 重試 */
                prvUnlockQueue( pxQueue );
                ( void ) xTaskResumeAll();
            }
        }
        else
        {
            /* timeout, 如果 Queue 裡有資料則 retry */
            prvUnlockQueue( pxQueue );
            ( void ) xTaskResumeAll();

            if( prvIsQueueEmpty( pxQueue ) != pdFALSE )
            {
                /* Queue 裡沒有資料, Queue 空錯誤碼 */
                return errQUEUE_EMPTY;
            }
        }
    }
}
```

# Task Synchronization

## [Semaphore](note_freertos_semaphore.md)

可以被認為長度大於 1 的 Queue. 此外, Semaphore (信號量)使用者不必關心存儲在 queue 中的 value, 只需關心 queue 是否為 empty.

通常計數信號量用於下面兩種情況
> + 計數事件
>> 每當事件發生, 事件處理程序將給出一個信號(信號量計數值加 1), 當處理事件時, 處理程序會取走信號量(信號量計數值減 1).
因此, 計數值是事件發生的數量和事件處理的數量差值. 在這種情況下, **計數信號量在創建時, 其值為 0**.

> + 資源管理
>> 計數值表示有效的資源數目, task 必須先獲取信號量才能獲取資源控制權. 當計數值減為 0 時表示沒有的資源 (當 task 完成後, 才會返還信號量, 讓信號量計數值增加).
在這種情況下, **計數值在創建時, 等於最大資源數目**.

+ **BinarySemaphore**
    > `count = 1` 的 semaphore

    - 與 Mutex 相似, 但**無優先級繼承**, 可能會發生**優先級翻轉**

    - 適用於同步
        1. `task <-> ISR` 之間
            > 可以用來實作 linux kernel 的 Top half 和 Bottom half
            > + Top half
            >> 在 ISR 中整理好所需的 info (應避免執行過久), 然後 GiveSemaphore 觸發對應的 task
            > + Bottom half
            >> 在 Task 中 TakeSemaphore 來接收信號量, 並執行中斷所對應的行為.
            此時 interrupt 可以是開啟的, 而 CPU 仍然可以接受 IRQ

        1. `task <-> task` 之間

## [Mutex/RecursiveMutex](note_freertos_mutex.md)

+ **有優先級繼承**機制, 可以避免優先級翻轉, 必須**在同一個 task 中 Take 信號, 且同一個 task 中 Give 信號**
    > 不可用於 ISR

+ 適用於互斥訪問 (Critical Section Protection)


## 優先級翻轉 (Priority Inversion)

當一個 High 優先級 task_A 通過信號量機制訪問共享資源時, 該信號量已被一 Low 優先級 task_C 佔有,
而這個 Low 優先級 task_C 在訪問共享資源時, 可能又被其它一些 Middle 優先級 task_B 搶先,
因此造成 High 優先級 task_A 被許多具有較低優先級 task_C 阻塞, real-time 難以得到保證.

+ Examples
    > 有優先級為 A, B 和 C 三個任務, 優先級 `A > B > C`,
    > + task_A, task_B 處於 suspend 狀態, 等待某一事件發生, 此時 **task_C 正在運行**, 並**正在使用某一共享資源 S (Critical Section)**.
    > + 在使用中, task_A 等待 event 到來, task_A 轉為 ready 態, 因為它比 task_C 優先級高, 所以立即執行.
    > + 當 **task_A 想要使用共享資源 S (Critical Section)** 時, 由於其正在被 task_C 使用, 因此 **task_A 被 suspend**, task_C 開始運行.
    > + 如果此時 **task_B 等待的 event 到來**, 則 task_B 轉為 ready 態.
    由於 task_B 優先級比 task_C 高, 因此 **task_B 開始運行**, 直到其運行完畢, task_C 才開始運行.
    > + 直到 **task_C 釋放共享資源 S (Critical Section)** 後, **task_A 才得以執行**.
    > + 在這種情況下, 優先級發生了翻轉, **task_B 先於 task_A 運行**

## 優先級繼承 (Priority Inheritance)

為了解決**優先級翻轉**問題, 暫時提高 Low 優先級 task 到 High 優先級

+ Examples
    > 有優先級為 A, B 和 C 三個任務, 優先級 `A > B > C`,
    > + task_A, task_B 處於 suspend 狀態, 等待某一事件發生, 此時 **task_C 正在運行**, 並**正在使用某一共享資源 S (Critical Section)**.
    > + 在使用中, task_A 等待 event 到來, task_A 轉為 ready 態, 因為它比 task_C 優先級高, 所以立即執行.
    > + 當 **task_A 想要使用共享資源 S (Critical Section)** 時, 由於其正在被 task_C 使用, **暫時提高 task_C 的優先級 (和 task_A 相同)**, 同時 **task_A 被 suspend**, task_C 開始運行.
    > + 如果此時 **task_B 等待的 event 到來**, 則 task_B 轉為 ready 態.
    由於 task_B 優先級低於 task_C, 因此 **task_C 繼續運行**, task_B 等待
    > + 直到 **task_C 釋放共享資源 S (Critical Section)** 並 **恢復 task_C 原本的優先級** 後, **task_A 開始執行**.
    > + task_A 執行結束, 換 **task_B 開始執行**

# reference

+ [FreeRTOS高級篇5---FreeRTOS Queue 分析](https://blog.csdn.net/zhzht19861011/article/details/51510384)
+ [freertos-  Queue 及其操作API](https://blog.csdn.net/Life_Maze/article/details/84710099)
+ [二值信號量和互斥鎖到底有什麼區別？](https://blog.csdn.net/weixin_30641465/article/details/97959399?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-11.control&dist_request_id=1328679.53135.16163967298235921&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-11.control)
