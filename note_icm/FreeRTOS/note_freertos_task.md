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
    ListItem_t          xEventListItem;     /* 事件列表項, 用於將任務以引用的方式掛接到事件列表, 紀錄 priority */
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

+ ready
+ delay
+ overflow
+ suspend

# Task Schedule

## vTaskStartScheduler
## vTaskSwitchContext

# TaskDelay


# TaskNotify

# Reference

+ [FreeRTOS高級篇2---FreeRTOS任務創建分析](https://freertos.blog.csdn.net/article/details/51303639)
+ [FreeRTOS支持時間片](https://www.codenong.com/cs106307673/)



