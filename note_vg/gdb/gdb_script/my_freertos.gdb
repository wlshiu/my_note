
set prompt \033[31mgdb$ \033[0m
# set trace-commands on
set logging file ~/working/image/gdg.log
# set logging on
# set logging redirect off
# set logging off

#######################
## These make gdb never pause in its output
set height 0
set width 0

set pagination off


set $BLUE=\033[34m
set $CYAN=\033[36m
set $MAGENTA=\033[35m
set $YELLOW=\033[33m
set $GREEN=\033[32m
set $RED=\033[31
set $NC=\033[0m

# set $BLUE=\e[34m
# set $CYAN=\e[36m
# set $MAGENTA=\e[35m
# set $YELLOW=\e[33m
# set $GREEN=\e[32m
# set $RED=\e[31
# set $NC=\e[0m


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

	if ((List_t*)$arg0)->uxNumberOfItems > 0

		if $arg1 != -1
			echo \033[33m
			printf "@@@ ReadyTasksLists Prior %d \n", $arg1
			echo \033[0m
		end

		echo \033[32m
		printf "Number of Tasks: %d\n\n", ((List_t*)$arg0)->uxNumberOfItems
		echo \033[0m


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

		dump_list &pxReadyTasksLists[$i] $i

		set $i-=1
	end

	echo \033[33m
	printf "@@@ DelayedTaskList1 \n"
	echo \033[0m
	dump_list &xDelayedTaskList1 -1

	echo \033[33m
	printf "@@@ DelayedTaskList2 \n"
	echo \033[0m
	dump_list &xDelayedTaskList2 -1

	# Pending
	echo \033[33m
	printf "@@@ PendingReadyList \n"
	echo \033[0m
	dump_list &xPendingReadyList -1

	# Suspended
	echo \033[33m
	printf "@@@ SuspendedTaskList \n"
	echo \033[0m
	dump_list &xSuspendedTaskList -1

	echo \033[33m
	printf "@@@ OverflowDelayedTaskList \n"
	echo \033[0m
	dump_list pxOverflowDelayedTaskList -1

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

set $ISR_SWI=xPortPendSVHandler

# input: TCB_t* or TCB address
define dump_task_backtrace
    save breakpoints ~/tmp_brk_____.rec

    delete
    delete

	## return from vTaskSwitchContext
	b *($ISR_SWI + 92)

    continue

	echo \033[36m
	echo pxCurrentTCB=
	p/x pxCurrentTCB
	echo \033[0m

	set $pTCB_org=pxCurrentTCB
    set pxCurrentTCB=$arg0

	## stop at the last line of ISR_SWI
	b *($ISR_SWI + 152)
	continue

	echo \033[36m
	backtrace
	echo \033[0m

	set $pc=$ISR_SWI
	delete
	delete

	## before enter vTaskSwitchContext
	b *($ISR_SWI + 80)
	continue

	set $pc=*($ISR_SWI + 92)
	set pxCurrentTCB=$pTCB_org
	delete
	delete

    source ~/tmp_brk_____.rec
    shell rm -f ~/tmp_brk_____.rec

	echo \033[36m
	echo pxCurrentTCB=
	p/x pxCurrentTCB
	echo \033[0m

	continue

end

# input: filename, start_addr, end_addr
define save_mem
    dump memory $arg0 $arg1 $arg2
end
document save_mem
Write a range of memory to a file in raw format.
The range is specified by ADDR1 and ADDR2 addresses.
Usage: save_mem FILENAME Start_ADDR End_ADDR
end

# enable breakpoint
define bpe
    if $argc != 1
        help bpe
    else
        enable $arg0
    end
end
document bpe
Enable breakpoint with number NUM.
Usage: bpe NUM
end

# disable breakpoint
define bpd
    if $argc != 1
        help bpd
    else
        disable $arg0
    end
end
document bpd
Disable breakpoint with number NUM.
Usage: bpd NUM
end

# list assembly
define la
    disassemble ($pc - 16),+60
end












