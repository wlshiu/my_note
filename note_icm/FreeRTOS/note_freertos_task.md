FreeRTOS Task [[Back](note_freertos_guide.md)]
---


# TCB member

```
# xStateListItem

                      TCB_1             TCB_3             TCB_9
xxxTaskList =>   xStateListItem <-> xStateListItem <-> xStateListItem
```

```
# xEventListItem

                TCB_2             TCB_3             TCB_5
xxxQueue =>   xEventListItem <-> xEventListItem <-> xEventListItem

```

# Task status

+ ready
+ delay
+ overflow
+ suspend

# TaskDelay

# xNextTaskUnblockTime

# TaskNotify
