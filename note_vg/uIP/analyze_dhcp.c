/**
 * PT_INIT(pt)                     初始化任務變量，只在初始化函數中執行一次就行
 * PT_BEGIN(pt)                    啟動任務處理，放在函數開始處
 * PT_END(pt)                      結束任務，放在函數的最後
 * PT_WAIT_UNTIL(pt, condition)    等待某個條件（條件可以為時鐘或其它變量，IO等）成立，否則直接退出本函數，下一次進入本     函數就直接跳到這個地方判斷
 * PT_WAIT_WHILE(pt, cond)         和上面一個一樣，只是條件取反了
 * PT_WAIT_THREAD(pt, thread)      等待一個子任務執行完成
 * PT_SPAWN(pt, child, thread)     新建一個子任務，並等待其執行完退出
 * PT_RESTART(pt)                  重新啟動某個任務執行
 * PT_EXIT(pt)                     任務後面的部分不執行，直接退出重新執行
 * PT_YIELD(pt)                    鎖死任務
 * PT_YIELD_UNTIL(pt, cond)        鎖死任務並在等待條件成立，恢復執行
 *
 * 在pt中一共定義四種線程狀態，在任務函數退出到上一級函數時返回其狀態
 * PT_WAITING      等待
 * PT_EXITED       退出
 * PT_ENDED        結束
 * PT_YIELDED      鎖死
 */

static struct dhcpc_state   s;

/**
 *  protothreads:
 *      thread-like of state machine
 */

static
PT_THREAD(handle_dhcp(void))
{
    PT_BEGIN(&s.pt);

    /* try_again:*/
    s.state = STATE_SENDING;
    s.ticks = CLOCK_SECOND;

    do {
        send_discover();
        timer_set(&s.timer, s.ticks);
        PT_WAIT_UNTIL(&s.pt, uip_newdata() || timer_expired(&s.timer));

        if(uip_newdata() && parse_msg() == DHCPOFFER) {
            s.state = STATE_OFFER_RECEIVED;
            break;
        }

        if(s.ticks < CLOCK_SECOND * 60) {
            s.ticks *= 2;
        }
    } while(s.state != STATE_OFFER_RECEIVED);

    s.ticks = CLOCK_SECOND;

    do {
        send_request();
        timer_set(&s.timer, s.ticks);
        PT_WAIT_UNTIL(&s.pt, uip_newdata() || timer_expired(&s.timer));

        if(uip_newdata() && parse_msg() == DHCPACK) {
            s.state = STATE_CONFIG_RECEIVED;
            break;
        }

        if(s.ticks <= CLOCK_SECOND * 10) {
            s.ticks += CLOCK_SECOND;
        } else {
            PT_RESTART(&s.pt);
        }
    } while(s.state != STATE_CONFIG_RECEIVED);


    dhcpc_configured(&s);

    /*
     * PT_END restarts the thread so we do this instead. Eventually we
     * should reacquire expired leases here.
     */
    while(1) {
        PT_YIELD(&s.pt);
    }

    PT_END(&s.pt);
}

static char handle_dhcp(void)
{
    // PT_BEGIN(&s.pt);
    char PT_YIELD_FLAG = 1;
    switch(s.pt->lc) {
        case 0: /** current state */
    //------------------

            s.state = STATE_SENDING;
            s.ticks = CLOCK_SECOND;

            do {
                send_discover();    //發送dhcpc探求包
                timer_set(&s.timer, s.ticks);

                //  PT_WAIT_UNTIL(&s.pt, uip_newdata() || timer_expired(&s.timer));
                do {
                    s.pt->lc = __LINE__;
        case __LINE__: /** current state */
                    if(!(uip_newdata() || timer_expired(&s.timer))) {
                        return PT_WAITING;
                    }
                } while(0)
                //------------------

                if(uip_newdata() && parse_msg() == DHCPOFFER) {
                    s.state = STATE_OFFER_RECEIVED;
                    break;
                }

                if(s.ticks < CLOCK_SECOND * 60) {
                    s.ticks *= 2;
                }
            } while(s.state != STATE_OFFER_RECEIVED);

            s.ticks = CLOCK_SECOND;

            do {
                send_request();    //發送dhcpc接受包
                timer_set(&s.timer, s.ticks);

                // PT_WAIT_UNTIL(&s.pt, uip_newdata() || timer_expired(&s.timer));
                do {
                    s.pt->lc = __LINE__;
        case __LINE__: /** current state */
                    if(!( uip_newdata() || timer_expired(&s.timer))) {
                        return PT_WAITING;
                    }
                } while(0)
                //---------------------------

                if(uip_newdata() && parse_msg() == DHCPACK) {
                    s.state = STATE_CONFIG_RECEIVED;
                    break;
                }

                if(s.ticks <= CLOCK_SECOND * 10) {
                    s.ticks += CLOCK_SECOND;
                } else {
                    // PT_RESTART(&s.pt);
                    do {
                        s.pt->lc = 0;
                        return PT_WAITING;
                    } while(0)
                    //-------------------
                }
            } while(s.state != STATE_CONFIG_RECEIVED);

            dhcpc_configured(&s);

            while(1) {      //這個死循環是應用中的需求，dhcp後這個程序不要再執行了
                // PT_YIELD(&s.pt);
                do {
                    PT_YIELD_FLAG = 0;
                    s.pt->lc = __LINE__;
        case __LINE__: /** current state */
                    if(PT_YIELD_FLAG == 0) {
                        return PT_YIELDED;
                    }
                } while(0)  //可以看出此宏功能是，此次程序執行到這裡就返回，下次再到本協程函數，不返回繼續往後執行。
                //-----------------------
            }
    }

    // PT_END(&s.pt);
    PT_YIELD_FLAG = 0;
    s.pt->lc = 0;
    return PT_ENDED;
    //-----------------------
}