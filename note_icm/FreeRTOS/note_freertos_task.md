FreeRTOS Task [[Back](note_freertos_guide.md)]
---

# 變數定義

## TCB (Task Control Block) member

```c
typedef struct tskTaskControlBlock
{
    volatile StackType_t    *pxTopOfStack;  /* 目前 stack pointer 的位置, 必須位於結構體的第一項 */

    #if ( portUSING_MPU_WRAPPERS == 1 )
        xMPU_SETTINGS   xMPUSettings;       /* MPU設置, 必須位於結構體的第二項 */
    #endif

    ListItem_t          xStateListItem;     /* 任務的狀態列表項, 以引用的方式表示 task 的狀態, 紀錄 blocking time */
    ListItem_t          xEventListItem;     /* 事件列表項, 用於將任務以引用的方式掛接到事件列表,
                                               紀錄 priority 的補數, 這意味著 xItemValue 的值越大, 對應的任務優先級越小
                                               (xItemValue = configMAX_PRIORITIES - tskPriority)*/
    UBaseType_t         uxPriority;         /* 保存任務優先級, 0 表示最低優先級 */
    StackType_t         *pxStack;           /* stack pool 的 base address */
    char                pcTaskName[configMAX_TASK_NAME_LEN]; /* 任務名字 */

    #if ( portSTACK_GROWTH > 0 )
        StackType_t     *pxEndOfStack;      /* 指向堆棧的尾部 */
    #endif

    #if ( portCRITICAL_NESTING_IN_TCB == 1 )
        UBaseType_t     uxCriticalNesting;  /* 紀錄 nesting 的深度 */
    #endif

    #if ( configUSE_TRACE_FACILITY == 1 )
        UBaseType_t     uxTCBNumber;       /* 保存一個數值, 每個任務都有唯一的值 */
        UBaseType_t     uxTaskNumber;      /* 存儲一個特定數值 */
    #endif

    #if ( configUSE_MUTEXES == 1 )
        UBaseType_t     uxBasePriority;    /* 保存任務的基礎優先級 */
        UBaseType_t     uxMutexesHeld;
    #endif

    #if ( configUSE_APPLICATION_TASK_TAG == 1 )
        TaskHookFunction_t pxTaskTag;
    #endif

    #if( configNUM_THREAD_LOCAL_STORAGE_POINTERS > 0 )
        void *pvThreadLocalStoragePointers[configNUM_THREAD_LOCAL_STORAGE_POINTERS ];
    #endif

    #if( configGENERATE_RUN_TIME_STATS == 1 )
        uint32_t        ulRunTimeCounter;  /*記錄任務在運行狀態下執行的總時間*/
    #endif

    #if ( configUSE_NEWLIB_REENTRANT == 1 )
        /* 為任務分配一個Newlibreent結構體變量。Newlib是一個C庫函數, 並非FreeRTOS維護, FreeRTOS也不對使用結果負責。如果用戶使用Newlib, 必須熟知Newlib的細節*/
        struct _reent xNewLib_reent;
    #endif

    #if( configUSE_TASK_NOTIFICATIONS == 1 )
        volatile uint32_t ulNotifiedValue; /*與任務通知相關*/
        volatile uint8_t ucNotifyState;
    #endif

    #if( configSUPPORT_STATIC_ALLOCATION == 1 )
        uint8_t ucStaticAllocationFlags; /* 如果堆棧由靜態數組分配, 則設置為pdTRUE, 如果堆棧是動態分配的, 則設置為pdFALSE*/
    #endif

    #if( INCLUDE_xTaskAbortDelay == 1 )
        uint8_t ucDelayAborted;
    #endif

} tskTCB;

typedef tskTCB TCB_t;
```

+ xStateListItem
    > 紀錄 task 的狀態 (e.g. ready, suspend, delay, ...etc), 並將 TCB 接到對應的 TaskList

    ![xStateListItem of task](Task_State_ListItem.jpg)


```
# xEventListItem

                TCB_2             TCB_3             TCB_5
xxxQueue =>   xEventListItem <-> xEventListItem <-> xEventListItem

```

## 重要的 Global variables

+ Task List
    - `pxReadyTasksLists[configMAX_PRIORITIES]`
    - `pxDelayedTaskList`
    - `pxOverflowDelayedTaskList`
    - `xPendingReadyList`
    - `xSuspendedTaskList`



+ **pxCurrentTCB**
+ **uxTopReadyPriority**
+ **xNextTaskUnblockTime**
+ **xTickCount**
+ **uxCurrentNumberOfTasks**

# Macro API


+ `taskSELECT_HIGHEST_PRIORITY_TASK()`
    > 選最高優先權的 task
    >> 用 `uxTopReadyPriority` 的 bit field 來記錄, 目前不同 priority 的 **pxReadyTasksLists** 是否有存在 tasks

    ```c
    #define taskSELECT_HIGHEST_PRIORITY_TASK()                                                  \
    {                                                                                           \
        UBaseType_t uxTopPriority;                                                              \
        /* 找目前在 read task lists 中最高優先權的 list, 並更新到 uxTopPriority */                   \
        portGET_HIGHEST_PRIORITY( uxTopPriority, uxTopReadyPriority );                          \
        configASSERT( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ uxTopPriority ] ) ) > 0 ); \
        /* 獲取 ready list 中優先級最高的 TCB, 然後更新到 pxCurrentTCB */                            \
        listGET_OWNER_OF_NEXT_ENTRY( pxCurrentTCB, &( pxReadyTasksLists[ uxTopPriority ] ) );   \
    }
    ```

+ `taskRECORD_READY_PRIORITY( uxPriority )`
+ `taskRESET_READY_PRIORITY( uxPriority ) `
+ `taskSWITCH_DELAYED_LISTS()`

+ `prvAddTaskToReadyList(pxTCB)`


# Task status

![task_state](tskstate.jpg)

# Task Create/Delete

## create

+ xTaskCreate

    ```
    BaseType_t
    xTaskCreate(
        TaskFunction_t  pvTaskCode,     // 指向任務函數的入口
        const char      *const pcName,  // 任務名稱
        unsigned short  usStackDepth,   // stack 深度, stack 大小為  usStackDepth * sizeof(StackType_t)
        void            *pvParameters,  // 參數傳遞給 task
        UBaseType_t     uxPriority,     // 任務的優先級
        TaskHandle_t    *pvCreatedTask);
    ```

+ Example usage

    ```c
    /* Task to be created. */
    void vTaskCode( void * pvParameters )
    {
        /* The parameter value is expected to be 1 as 1 is passed in the
        pvParameters value in the call to xTaskCreate() below.
        configASSERT( ( ( uint32_t ) pvParameters ) == 1 );

        for( ;; )
        {
            /* Task code goes here. */
        }

        vTaskDelete(NULL); /* 要退出且刪除任務, 一定要調用vTaskDelete() */
    }

    /* Function that creates a task. */
    void vOtherFunction( void )
    {
    BaseType_t xReturned;
    TaskHandle_t xHandle = NULL;

        /* Create the task, storing the handle. */
        xReturned = xTaskCreate(
                        vTaskCode,       /* Function that implements the task. */
                        "NAME",          /* Text name for the task. */
                        STACK_SIZE,      /* Stack size in words, not bytes. */
                        ( void * ) 1,    /* Parameter passed into the task. */
                        tskIDLE_PRIORITY,/* Priority at which the task is created. */
                        &xHandle );      /* Used to pass out the created task's handle. */

        if( xReturned == pdPASS )
        {
            /* The task was created.  Use the task's handle to delete the task. */
            vTaskDelete( xHandle );
        }
    }
    ```

+ pxPortInitialiseStack()
    > 初始化 stack layout.

    - Task Context-Switch 時, 會先將 CPU 資訊 (GPRs + CPU system registers) store (push) 到 stack 裡, 同時 Stack Pointer 往 Top 推.
    - 選擇下一個 task (TCB) 並將 CPU 資訊, 從 stack restore (pop) 到 CPU 對應的 system registers, 同時 Stack Pointer 往 End 降.
    - 系統第一次 Context-Switch 時, 會跳過 store 的步驟, 直接從 stack restore CPU 資訊
        > pxPortInitialiseStack() 需要配合預期 stack layout, 預先將 CPU 資訊填入 stack (模擬 store 步驟);
        其中包含 GPRs 的存入順序, 中斷的開啟 (Set CPU system register)等.

## delete

+ vTaskDelete

    ```c
    /**
     *  xTask == NULL, 則 delete current task
     */
    void vTaskDelete( TaskHandle_t xTask );
    ```

+ Example usage

    ```c
    void vOtherFunction( void )
    {
        TaskHandle_t xHandle = NULL;

        // Create the task, storing the handle.
        xTaskCreate( vTaskCode, "NAME", STACK_SIZE, NULL, tskIDLE_PRIORITY, &xHandle );

        // Use the handle to delete the task.
        if( xHandle != NULL )
        {
            vTaskDelete( xHandle );
        }
    }
    ```


# Task Schedule

## vTaskStartScheduler

用於啟動 RTOS Scheduler, 它會創建 Idle task and S/w timer task (optional), 同時初始化一些靜態變量.
最主要的, 它會初始化系統 Heartbeat (SysTick) 並設置好相應的中斷, 然後啟動第一個 task

+ vTaskStartScheduler()

    ```c
    /**** 精簡 source code *****/
    void vTaskStartScheduler( void )
    {
        BaseType_t xReturn;

        /* 創建 Idle task,使用最低優先級 (priority 0) */
        xReturn = xTaskCreate( prvIdleTask,
                               configIDLE_TASK_NAME,
                               configMINIMAL_STACK_SIZE,
                               ( void * ) NULL,
                               portPRIVILEGE_BIT,  /* In effect (tskIDLE_PRIORITY | portPRIVILEGE_BIT) */
                               &xIdleTaskHandle );


        #if ( configUSE_TIMERS == 1 )
        /* 創建 S/w timer task */
        if( xReturn == pdPASS )
        {
            xReturn = xTimerCreateTimerTask();
        }
        #endif

        if( xReturn == pdPASS )
        {
            /**
             * 先關閉中斷,確保 Heartbeat (SysTick) 中斷不會在調用 xPortStartScheduler() 時或之前發生.
             * 當第一個任務啟動時, 會重新啟動中斷
             */
            portDISABLE_INTERRUPTS();

            /******** 初始化靜態變量 *******/
            xNextTaskUnblockTime = portMAX_DELAY;
            xSchedulerRunning    = pdTRUE;

            /* Heartbeat tick count */
            xTickCount = ( TickType_t ) configINITIAL_TICK_COUNT;

            /**
             * 如果 configGENERATE_RUN_TIME_STATS 被定義, 表示使用運行時間統計功能,
             * 則下面這個宏必須被定義, 用於初始化一個基礎 timer.
             */
            portCONFIGURE_TIMER_FOR_RUN_TIME_STATS();

            traceTASK_SWITCHED_IN();

            /* 設置 Heartbeat (SysTick), 這與硬件特性相關, 因此被放在了移植層.*/
            if( xPortStartScheduler() != pdFALSE )
            {
                /* 如果調度器正確運行, 則不會執行到這裡, 函數也不會返回 */
            }
            else
            {
                /* 僅當任務調用API函數 xTaskEndScheduler() 後,會執行到這裡.*/
            }
        }
        else
        {
           /* 執行到這裡表示內核沒有啟動, 可能因為堆棧空間不夠 */
            configASSERT( xReturn != errCOULD_NOT_ALLOCATE_REQUIRED_MEMORY );
        }

        /* 預防編譯器警告*/
        ( void ) xIdleTaskHandle;
    }
    ```

    - xPortStartScheduler()
        > Cortex-M3 為例

        ```
        BaseType_t xPortStartScheduler( void )
        {
            #if(configASSERT_DEFINED == 1 )
            {
                volatile uint32_t   ulOriginalPriority;
                /* 中斷優先級寄存器0:IPR0 */
                volatile uint8_t    *constpucFirstUserPriorityRegister = ( uint8_t * ) (portNVIC_IP_REGISTERS_OFFSET_16 + portFIRST_USER_INTERRUPT_NUMBER );
                volatile uint8_t    ucMaxPriorityValue;

                /* 這一大段代碼用來確定一個最高 ISR 優先級, 在這個 ISR 或者更低優先級的 ISR 中可以安全的調用以 FromISR 結尾的API函數.*/

                /* 保存中斷優先級值,  因為下面要覆寫這個寄存器(IPR0) */
                ulOriginalPriority = *pucFirstUserPriorityRegister;

                /**
                 * 確定有效的優先級位個數.
                 * 首先向所有 field 寫 1, 然後再讀出來, 由於無效的優先級位讀出為 0,
                 * 然後數一數有多少個1, 就能知道有多少位優先級.
                 */
                *pucFirstUserPriorityRegister = portMAX_8_BIT_VALUE;
                ucMaxPriorityValue = *pucFirstUserPriorityRegister;

                /* 冗餘代碼, 用來防止用戶不正確的設置 RTOS 可屏蔽中斷優先級值 */
                ucMaxSysCallPriority = configMAX_SYSCALL_INTERRUPT_PRIORITY & ucMaxPriorityValue;

                /* 計算最大優先級組值 */
                ulMaxPRIGROUPValue = portMAX_PRIGROUP_BITS;
                while( (ucMaxPriorityValue & portTOP_BIT_OF_BYTE ) == portTOP_BIT_OF_BYTE )
                {
                    ulMaxPRIGROUPValue--;
                    ucMaxPriorityValue <<= ( uint8_t ) 0x01;
                }

                ulMaxPRIGROUPValue <<= portPRIGROUP_SHIFT;
                ulMaxPRIGROUPValue &= portPRIORITY_GROUP_MASK;

                /* 將IPR0 寄存器的值復原 */
                *pucFirstUserPriorityRegister = ulOriginalPriority;
            }
            #endif /*conifgASSERT_DEFINED */

            /* 將PendSV和SysTick中斷設置為最低優先級*/
            portNVIC_SYSPRI2_REG |= portNVIC_PENDSV_PRI;
            portNVIC_SYSPRI2_REG |= portNVIC_SYSTICK_PRI;

            /* 啟動系統節拍定時器, 即 SysTick 定時器, 初始化中斷週期並使能定時器*/
            vPortSetupTimerInterrupt();

            /* 初始化臨界區 Nesting counter */
            uxCriticalNesting = 0;

            /* 啟動第一個任務 */
            prvStartFirstTask();

            /* 永遠不會到這裡! */
            return 0;
        }        
        ```


## vTaskEndScheduler

停止 RTOS 內核系統節拍時鐘, 所有創建的任務自動刪除並停止多任務調度.

**僅用於x86硬件架構中**

## vTaskSwitchContext

## Suspend

將 task 進入 suspend state, 直到有 task resume 才會重新進入 scheduler

+ vTaskSuspend
    > ISR 中不能 suspend task

    ```c
    /**
     *  xTaskToSuspend: 要 Suspend (掛起)的 task handle, NULL 表示掛起當前任務
     */
    void vTaskSuspend(TaskHandle_t  xTaskToSuspend);
    ```

+ Example usage

    ```c
    void vAFunction( void )
    {
        xTaskHandle     xHandle;
        // 創建任務, 保存任務句柄.
        xTaskCreate( vTaskCode, "NAME", STACK_SIZE, NULL, tskIDLE_PRIORITY, &xHandle );
        ...

        /**
         *  suspend vTaskCode with xHandle
         *  vTaskCode 不再運行, 除非其它任務調用了 vTaskResume(xHandle)
         */
        vTaskSuspend( xHandle ); //  suspend xHandle

        ...

        vTaskSuspend( NULL ); // suspend current task.
        // 除非另一個 task 使用 handle 調用了 vTaskResume, 否則永遠不會執行到這裡
    }
    ```

## Resume

將 task 離開 suspend state

+ vTaskResume
    > 調用一次或多次 vTaskSuspend() 掛起的 task, 可以調用一次 vTaskResume() 來再次恢復運行

    ```c
    void vTaskResume( TaskHandle_t  xTaskToResume );
    ```

    - Example usage

        ```c
        TaskHandle_t    g_HTask_KEY0;
        TaskHandle_t    g_HTask_KEY1;

        // KEY0 任務函數
        void _task_key0(void *pvParameters)
        {
            u8  key;

            while(1)
            {
                key = KEY_Scan(0); //掃瞄按鍵

                switch(key)
                {
                    case KEY1_PRES:
                        vTaskSuspend(g_HTask_KEY1);
                        printf("suspend the key1 task\n");
                        break;
                    case KEY2_PRES:
                        vTaskResume(g_HTask_KEY1);
                        printf("resume the key1 task\n");
                        break;
                }

                vTaskDelay(10);
            }
        }

        void _task_key1(void *pvParameters)
        {
            while(1)
            {
                printf("TASK2\n");
                vTaskDelay(1000);
            }
        }

        void main()
        {
            // KEY0 task
            xTaskCreate((TaskFunction_t )_task_key0,
                        (const char* )"key0_task",
                        (uint16_t )KEY0_STK_SIZE,
                        (void* )NULL,
                        (UBaseType_t )KEY0_TASK_PRIO,
                        (TaskHandle_t* )&g_HTask_KEY0);

            // KEY1 task
            xTaskCreate((TaskFunction_t )_task_key1,
                        (const char* )"key1_task",
                        (uint16_t )KEY1_STK_SIZE,
                        (void* )NULL, (UBaseType_t )KEY1_TASK_PRIO,
                        (TaskHandle_t* )&g_HTask_KEY1);

            vTaskStartScheduler();
        }

        ```
+ xTaskResumeFromISR
    > 用在ISR中. 調用一次或多次 vTaskSuspend() 而掛起的 task, 只需調用一次 xTaskResumeFromISR() 即可恢復運行

    ```
    BaseType_t xTaskResumeFromISR(TaskHandle_t xTaskToResume);
    ```

    - Example usage

        ```c
        xTaskHandle  g_xHandle;

        void xxx_ISR( void )
        {
            portBASE_TYPE  xYieldRequired;

            // 恢復被掛起的任務
            xYieldRequired = xTaskResumeFromISR(g_xHandle);

            if( xYieldRequired == pdTRUE )
            {
                // 我們應該進行一次上下文切換
                portYIELD_FROM_ISR();
            }
        }

        void vTaskCode( void *pvParameters )
        {
            for( ;; )
            {
                ...

                // 掛起自己
                vTaskSuspend( NULL );

                // 直到 ISR 恢復它之前, 任務會一直掛起
            }
        }

        void vAFunction( void )
        {
            // 創建 task
            xTaskCreate(vTaskCode, "NAME", STACK_SIZE, NULL, tskIDLE_PRIORITY, &g_xHandle);

            ...
        }
        ```

# Delay

+ TaskDelay
    > task 進入 blocking (阻塞)狀態, 指定的延時時間是一個**相對時間**
    >> 延時時間也不總是固定的, 中斷或高優先級任務搶佔也可能會改變每一次執行時間

    ```
    /**
     *  xTicksToDelay: 單位是系統 Heartbeat (SysTick) 週期
     *  其指定的延時時間, 是從調用 vTaskDelay() 後開始計算的 '相對時間'
     */
    void vTaskDelay( portTickType xTicksToDelay )
    ```

    - Example usage

        ```
        void vTaskFunction( void * pvParameters )
        {
            /* 阻塞 500ms. */
            const portTickType xDelay = 500 / portTICK_RATE_MS;

            for( ;; )
            {
                /* 每隔 500ms 觸發一次 LED, 觸發後進入阻塞狀態 */
                vToggleLED();
                vTaskDelay( xDelay );
            }
        }
        ```


+ vTaskDelayUntil
    >  task 進入 blocking (阻塞)狀態, 指定的延時時間是一個**絕對時間**
    >> 依照 (*pxPreviousWakeTime + xTimeIncrement)的時間, 週期循環

    ```c
    /**
     *  pxPreviousWakeTime： 指向一個變量, 該變量保存任務最後一次解除阻塞的時間.
     *                      第一次使用前, 該變量必須初始化為當前時間.
     *                      之後這個變量會在 vTaskDelayUntil() 內自動更新.
     *  xTimeIncrement： 週期循環時間.
     *                  當時間等於 (*pxPreviousWakeTime + xTimeIncrement)時, 任務解除阻塞.
     *                  如果不改變參數 xTimeIncrement 的值, 調用該函數的任務會按照固定頻率執行.
     */
    void vTaskDelayUntil(TickType_t        *pxPreviousWakeTime,
                         const TickType_t  xTimeIncrement);
    ```

    - Example usage

        ```c
        // 每 10 次系統節拍執行一次
        void vTaskFunction( void * pvParameters )
        {
            static portTickType xLastWakeTime;
            const portTickType  xFrequency = 10;

            // 使用當前時間初始化變量 xLastWakeTime
            xLastWakeTime = xTaskGetTickCount();

            for( ;; )
            {
                //等待下一個週期
                vTaskDelayUntil( &xLastWakeTime, xFrequency );

                ...
            }
        }
        ```

# TaskNotify

# MISC

## Task Run-Time Statistics

+ vTaskList()
    > log stack usage and priority of tasks

    ```
    /* enable options At FreeRTOSconfig.h */
    #define configUSE_TRACE_FACILITY                1
    #define configUSE_STATS_FORMATTING_FUNCTIONS    1

    /* instance */
    void task_sys_monitor(void *arg)
    {
        char pWriteBuffer[2048];
        for(;;)
        {
            sys_msleep(10000);

            /* show task info */
            vTaskList((char *)&pWriteBuffer);
            printf("task_name   task_state  priority   stack  tasK_num\n");
            printf("%s\n", pWriteBuffer);
        }
        vTaskDelete(NULL);
        return;
    }

    /**
     *  output:
     *  task_name      task_state  priority   stack  tasK_num
     *  TASK_LIST             R       4       341     20
     *  LOGUART_T             B       5       457     1
     *
     *  'R'     : 代表準備態 ready
     *  'B'     : 代表阻塞態 blocked
     *  stack   : 代表最小未使用的 stack 空間
     *  tasK_num: task 創建順序
     */
    ```

+ vTaskGetRunTimeStats()
    > log CPU usage of tasks
    >> + 需要一個精準度高於 SysTick (10 ~ 20倍) 的 timer 來測量各 task 的 CPU 使用率.
    >> + 不支援 timer overflow reset, 即只能統計到 timer overflow 前的時間區間

    - configGENERATE_RUN_TIME_STATS
        > 開啟 task 統計功能

    - portCONFIGURE_TIMER_FOR_RUN_TIME_STATS()
        > 實作 timer 配置

    - portGET_RUN_TIME_COUNTER_VALUE()
        > 實作 獲取 timer 目前時間

    - example

        ```
        void task_cpu_monitor(void *arg)
        {
            char pWriteBuffer[2048];

            for(;;)
            {
                sys_msleep(10000);
                vTaskGetRunTimeStats(pWriteBuffer);
                printf("task_name   task_use_ticks   percentage\n");
                printf("%s", pWriteBuffer);
            }
        }

        /**
         *  output:
         *  task_name   task_use_ticks   percentage
         *  rtT                109791       < 1%
         *  IDLE              8569082       99%
         *
         *  task_use_ticks: task 目前累計佔用 CPU 的 ticks
         *  percentage    : task 目前累計使用 CPU 的 百分比
         */
        ```

+ uxTaskGetSystemState()
    > 獲得 Tasks 的狀態, 可包含 vTaskList() 和 vTaskGetRunTimeStats() 資訊

    ```c
    /* enable options At FreeRTOSconfig.h */
    #define configUSE_TRACE_FACILITY                1

    /* status info of a task */
    typedef struct xTASK_STATUS
    {
        /* 任務句柄 */
        TaskHandle_t        xHandle;

        /* 指針, 指向任務名 */
        const signed char   *pcTaskName;

        /* 任務ID, 是一個獨一無二的數字 */
        UBaseType_t         xTaskNumber;

        /* 填充結構體時, 任務當前的狀態(運行、就緒、掛起等等) */
        eTaskState          eCurrentState;

        /*填充結構體時, 任務運行(或繼承)的優先級。*/
        UBaseType_t         uxCurrentPriority;

        /* 當任務因繼承而改變優先級時, 該變量保存任務最初的優先級. 僅當 configUSE_MUTEXES = 1 有效 */
        UBaseType_t         uxBasePriority;

        /* 分配給任務的總運行時間. 僅當宏 configGENERATE_RUN_TIME_STATS = 1 時有效 */
        unsigned long       ulRunTimeCounter;

        /* 從任務創建起, 堆棧剩餘的最小數量, 這個值越接近0, 堆棧溢出的可能越大. */
        unsigned short      usStackHighWaterMark;
    } TaskStatus_t;
    ```

# Reference

+ [FreeRTOS基礎篇-朱工的專欄](https://blog.csdn.net/zhzht19861011/category_9265276.html)
+ [FreeRTOS高級篇-朱工的專欄](https://blog.csdn.net/zhzht19861011/category_9265965.html)
+ [FreeRTOS高級篇2---FreeRTOS任務創建分析](https://freertos.blog.csdn.net/article/details/51303639)
+ [FreeRTOS支持時間片](https://www.codenong.com/cs106307673/)
+ [FreeRTOS系列第16篇---可視化追蹤調試](https://blog.csdn.net/zhzht19861011/article/details/50717549)


