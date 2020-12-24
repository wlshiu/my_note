
set prompt \033[31mgdb$ \033[0m
set logging file ~/working/image/gdg.log
# set logging on
# set logging redirect off
# set logging off


# input: List_t*
define dump_list_2

    set $pxList = $arg0
    set $pxListEnd = &($pxList->xListEnd)
	set $pListItem=$pxList->xListEnd.pxNext

	set $i = 0
    while $pListItem != $pxListEnd
        set $pxNext = $pListItem->pxNext

		# BLUE
		# echo \033[34m

		# CYAN
		echo \033[36m

		# MAGENTA
		# echo \033[35m
        p/x *(TCB_t*)$pListItem->pvOwner
		echo \033[0m

        set $pListItem = $pxNext
		set $i+=1
    end

	printf "Number of Item: %d\n\n", $i
end

# arg0: List_t  pointer
define dump_list

	set $pHeadListItem=((List_t*)$arg0)->pxIndex
	set $pCurListItem=$pHeadListItem

	echo \033[32m
	printf "Number of Tasks: %d\n\n", ((List_t*)$arg0)->uxNumberOfItems
	echo \033[0m

	if ((List_t*)$arg0)->uxNumberOfItems > 0
		while 1

			set $pTCB=((ListItem_t *)$pCurListItem)->pvOwner

			printf "TASK: %s at 0x%08x\n", ((TCB_t*)$pTCB)->pcTaskName, $pTCB
			printf "\n"

			set $pCurListItem=$pCurListItem->pxNext

			# get head item
			if ((List_t*)$pCurListItem) == $pHeadListItem
				loop_break
			end
		end
	end
end

define dump_freertos_tasks

	set $i=(sizeof(pxReadyTasksLists)/sizeof(pxReadyTasksLists[0]))-1

	while $i >= 0

		echo \033[33m
		printf "@@@ ReadyTasksLists Prior %d \n", $i
		echo \033[0m
		dump_list &pxReadyTasksLists[$i]

		set $i-=1
	end

	echo \033[33m
	printf "@@@ DelayedTaskList1 \n"
	echo \033[0m
	dump_list &xDelayedTaskList1

	echo \033[33m
	printf "@@@ DelayedTaskList2 \n"
	echo \033[0m
	dump_list &xDelayedTaskList2

	# Pending
	echo \033[33m
	printf "@@@ PendingReadyList \n"
	echo \033[0m
	dump_list &xPendingReadyList

	# Suspended
	echo \033[33m
	printf "@@@ SuspendedTaskList \n"
	echo \033[0m
	dump_list &xSuspendedTaskList

	echo \033[33m
	printf "@@@ OverflowDelayedTaskList \n"
	echo \033[0m
	dump_list pxOverflowDelayedTaskList

end

# input: Queue_t*
define dump_queue
    echo \033[36m
	set $CurQueue=$arg0
	p/x *(Queue_t*)$CurQueue
	echo \033[0m

	echo QData:\n

	set $Cnt = $CurQueue->uxLength * $CurQueue->uxItemSize
	printf "Queue buf size: %d\n\n", $Cnt

	# x/$Cntxw $CurQueue->pcHead

end


define dump_current_task
    printf "%s: 0x%x\n", ((TCB_t *)pxCurrentTCB)->pcTaskName, pxCurrentTCB
end


# input: EventGroup_t*
define print_event_group_handle
	p/x *(EventGroup_t*)$arg0
	echo \nxTasksWaitingForBits:\n
    dump_list_2 &((EventGroup_t*)$arg0)->xTasksWaitingForBits
end

# input: TCB_t*
define print_tcb
	echo \033[36m
	echo \nTCB:\n
	p/x *(TCB_t*)$arg0
	echo \033[0m
end

# input: TCB_t* or TCB address
define do_switch_task
    d
    b vTaskSwitchContext

    continue

    finish
    set pxCurrentTCB=$arg0

	# check opcode of return instruction
    while (*(unsigned long *)$pc != 0x4000064)
        si
    end

    si
    bt
end





















