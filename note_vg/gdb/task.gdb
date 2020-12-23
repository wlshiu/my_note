# logging level control flags
set $PrintTCB_Raw=0
set $PrintTCB_Frame=0
set $PrintTCB_CallStack=0

# declare on-line document help-text
# (Use "help freertos {cmd}" to query cmd help in GDB)
define freertos
  # dumb cmd
end
document freertos 
  All customed FreeRTOS command list:  
  (use "help {cmd}" to query more details)
    - parseContextFromStack {*stack point}
    - dumpMemory {from} {to}
    - printTaskCB {*TCB}
end

init-if-undefined $TaskListAuxString={"SuspendedTask   ", \
                         "DelayedTaskList1", \
                         "DelayedTaskList2", \
                         "PendingReadyList"}

set $TaskListAuxArray={xSuspendedTaskList, \
                       xDelayedTaskList1, \
                       xDelayedTaskList2, \
                       xPendingReadyList}
set $TaskListPending=xSuspendedTaskList

# parse context from Top of Stack
define parseContextFromStack
  set $i=0
  printf "ulCriticalNesting = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "CPSR = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R0 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R1 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R2 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R3 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R4 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R5 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R6 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R7 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R8 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R9 = 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R10= 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R11= 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R12= 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R13= 0x%08x\n",*((unsigned int*)$arg0+$i++)
  printf "R14= 0x%08x\n",*((unsigned int*)$arg0+$i++)
  set $tempLR = *(unsigned int*)($arg0+64)
  printf "LR = 0x%08x\n",$tempLR
  printf "PC = 0x%08x\n",$tempLR-4
end
document parseContextFromStack 
  parsecontextFromStack {stack point}
end

# dump Memory 
# arg0: unsigned int* - start address
# arg1: unsigned int* - end address
define dumpMemory
    set $dmCurrAddr=$arg0
    set $dmLineCount=0
    printf "MEM DUMP [0x%x-0x%x]\n",$arg0,$arg1
    while $dmCurrAddr < $arg1
        printf "0x%08x: 0x%08x 0x%08x 0x%08x 0x%08x | \n", $dmCurrAddr,\
                                 *((unsigned int*)$dmCurrAddr),\
                                 *((unsigned int*)$dmCurrAddr+1),\
                                 *((unsigned int*)$dmCurrAddr+2),\
                                 *((unsigned int*)$dmCurrAddr+3)
        #set $dmLineCount++
        set $dmCurrAddr+=16
    end
end
document dumpMemory
  dumpMemory {from} {to}
end

# find highest priority task in ready list
# return point to task @ $pTask_next
define findHighestReadyTask
  set $i=(sizeof(pxReadyTasksLists)/sizeof(pxReadyTasksLists[0]))-1

  while $i >= 0 
    if(pxReadyTasksLists[$i].uxNumberOfItems == 0)
      set $i-=1
      loop_continue
    else
      #printf " ->Priority: %d, ", $i
      #printf "Number of Tasks: %d\n\n", pxReadyTasksLists[$i].uxNumberOfItems
      if pxReadyTasksLists[$i]->pxIndex.xItemValue == $ListItemMagicDumb
        # advance to next ListItem
        set $pTask_next=pxReadyTasksLists[$i]->pxIndex->pxNext->pvOwner
      else
        set $pTask_next=pxReadyTasksLists[$i]->pxIndex->pvOwner
      end
      #printTaskCB $pTask_next
      loop_break
    end
  end
end
document findHighestReadyTask
    Usage: findHighestReadyTask
    Return: point to task @ convineinet $pTask_next
end

# print RTOS Task Control Block
# arg0: TCB_t - task control block
define printTaskCB
    # print task CB
#    printf "=============================================================\n"
    printf "TASK: %s at 0x%08x\n",((TCB_t*)$arg0)->pcTaskName,$arg0
    printf "Stack: 0x%x--0x%x, %d (limit--current, free size)\n",((TCB_t*)$arg0)->pxStack,\
                                                     ((TCB_t*)$arg0)->pxTopOfStack,\
                            ((TCB_t*)$arg0)->pxTopOfStack-((TCB_t*)$arg0)->pxStack

    printf "Priority: %d\n",((TCB_t*)$arg0)->uxPriority
#    printf "-------------------------------------------------------------\n"
    # print RAW data
    if $PrintTCB_Raw == 1
        printf "\n-------> TCB RAW data ------->\n"
        print *(TCB_t*)$arg0
        printf "<------- TCB RAW data <-------\n"
#        printf "=============================================================\n\n"
    end
end
# declare on-line document help-text
# (Use "help {cmd}" to query cmd help in GDB)
document printTaskCB 
  print RTOS Task Control Block
  Usage: printTaskCB [arg0]
         [arg0] TCB_t - task control block
end


# traverse FreeRTOS Task List
# arg0: List_t - Task List
define traverseTaskList
    set $index=0
    set $ListItemMagicDumb=0xFFFFFFFF
    set $pHeadListItem=$arg0.pxIndex
    set $pCurListItem=$pHeadListItem

    printf "Number of Tasks: %d\n\n", $arg0.uxNumberOfItems

    while 1 
        # check valid ListItem
        if $pCurListItem->xItemValue == $ListItemMagicDumb
            # advance to next ListItem
            set $pCurListItem=$pCurListItem->pxNext
            # we're done
            if $pCurListItem == $pHeadListItem
                loop_break
            end
        end

        set $pTask_this=$pCurListItem->pvOwner
        printTaskCB $pTask_this
        printf "\n"

        # advance to next ListItem
        set $pCurListItem=$pCurListItem->pxNext
        # we're done
        if $pCurListItem == $pHeadListItem
            loop_break
        end
    end
end

set print pretty off
set logging off
set logging overwrite on 
set logging redirect off
set logging file ./vtec/tools/gdb/log/task.log 
set logging on

# print current task
printf "[Current Task]\n"
printTaskCB pxCurrentTCB
printf "\n"
if $PrintTCB_Frame == 1
  printf "-------> Task Frame ------->\n"
  info frame
  printf "<------- Task Frame <-------\n"
end
if $PrintTCB_CallStack == 1
  printf "-------> Call Stack ------->\n"
  backtrace full
  printf "<------- Call Stack <-------\n\n\n"
end

# print All Task List info
set $i=0
while  $i < (sizeof($TaskListAuxArray)/sizeof($TaskListAuxArray[0]))
  print $TaskListAuxString[$i]
  traverseTaskList $TaskListAuxArray[$i]
  set $i+=1
end

# print READY Task List info
printf "[READY Task]\n"
set $i=0
while $i < (sizeof(pxReadyTasksLists)/sizeof(pxReadyTasksLists[0]))
  printf " ->Priority: %d, ", $i
  traverseTaskList pxReadyTasksLists[$i]
  set $i+=1
end
set loggin off
