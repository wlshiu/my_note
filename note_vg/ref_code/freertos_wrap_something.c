/**
 * Copyright (c) 2019 Wei-Lun Hsu. All Rights Reserved.
 */
/** @file hplc_freertos.c
 *
 * @author Wei-Lun Hsu
 * @version 0.1
 * @date 2019/01/23
 * @license
 * @description
 */


#include "hplc_socket.h"
#include "hplc_timer.h"
#include "hplc_event.h"
#include "hplc_evflag.h"
#include "hplc_util.h"

#include "hplc_mem.h"

/* freertos */
#include "task.h"
#include "semphr.h"
#include "event_groups.h"
//=============================================================================
//                  Constant Definition
//=============================================================================

//=============================================================================
//                  Macro Definition
//=============================================================================

#if 0
inline bool _is_isr(void)
{
    // 0: not in ISR, others: in ISR
    return (SCB->ICSR & SCB_ICSR_VECTACTIVE_Msk);
}
#endif
//=============================================================================
//                  Structure Definition
//=============================================================================
typedef struct timer_mgr
{
    uint32_t            is_used;

    TimerHandle_t       tm;
    CB_TIMER_ROUTINE    cb_routine;
    void                *pArgv;
} timer_mgr_t;

typedef event_mgr
{
    SemaphoreHandle_t   sem;
} event_mgr_t;

typedef struct evflag_mgr
{
    EventGroupHandle_t  evg;
} evflag_mgr_t;
//=============================================================================
//                  Global Data Definition
//=============================================================================
static timer_mgr_t      g_timer_mgr[HPLC_TIMER_MAX_NUM] = {[0] = {.is_used = 0,}};
//=============================================================================
//                  Private Function Definition
//=============================================================================
//---------------------------------
// timer
static void
_timer_callback(
    TimerHandle_t   pxTimer)
{
    int             id = 0;
    timer_mgr_t     *pTmr = 0;

    id = (int)pvTimerGetTimerID(pxTimer);

    _assert(id < TIMER_NUM_PER_NODE);

    pTmr = &g_timer_mgr[id];

    _assert(pTmr->is_used);

    if( pTmr->cb_routine )
        pTmr->cb_routine(pTmr->pArgv);

    return;
}

static hplc_timer_t
_rots_timer_create(hplc_timer_cfg_t *pCfg)
{
    timer_mgr_t     *pTmgr = 0;

    _assert(pCfg);
    _assert(pCfg->cb_routine);

    do {
        timer_mgr_t     *pCur = g_timer_mgr;
        uint32_t        period_ms = pCfg->period_usec / 1000;

        for(int i = 0; i < TIMER_NUM_PER_NODE; ++i)
        {
            if( !pCur->is_used )
            {
                pCur->tm = xTimerCreate("tm", (period_ms / portTICK_PERIOD_MS),
                                        pdTRUE, (void*)i, _timer_callback);
                if( pCur->tm == NULL )      break;

                pCur->is_used    = true;
                pCur->cb_routine = pCfg->cb_routine;
                pCur->pArgv      = pCfg->pArgv;

                pTmgr = pCur;
                break;
            }

            pCur++;
        }
    } while(0);

    return (hplc_timer_t)pTmgr;
}

static int
_rots_timer_start(hplc_timer_t  timer)
{
    int             rval = 0;
    timer_mgr_t     *pTmgr = (timer_mgr_t*)timer;

    _assert(timer);

    rval = (xTimerStart(pTmgr->tm, 0) == pdPASS) ? 0 : -1;
    return rval;
}

static int
_rots_timer_stop(hplc_timer_t  timer)
{
    int             rval = 0;
    timer_mgr_t     *pTmgr = (timer_mgr_t*)timer;

    _assert(timer);

    rval = (xTimerStop(pTmgr->tm, 0) == pdPASS) ? 0 : -1;
    return rval;
}

static int
_rots_timer_destroy(hplc_timer_t  timer)
{
    int             rval = -1;
    do {
        timer_mgr_t     *pTmgr = (timer_mgr_t*)timer;
        BaseType_t      xResult = pdFALSE;

        _assert(timer);

        xResult = xTimerDelete(pTmgr->tm, 0);
        if( xResult == pdFAIL )     break;

        memset(pTmgr, 0x0, sizeof(timer_mgr_t));
        rval = 0;
    } while(0);

    return rval;
}

static uint32_t
_rots_timer_get_msec(void)
{
    TickType_t      base_ticks = 0;

    base_ticks = xTaskGetTickCount();
    return (uint32_t)(base_ticks & 0xFFFFFFFF);
}

static uint32_t
_rots_timer_get_usec(void)
{
    TickType_t      base_ticks = 0;

    // FIXME: it should use H/W clock to convert
    base_ticks = xTaskGetTickCount() * 1000;
    return (uint32_t)(base_ticks & 0xFFFFFFFF);
}

/**
 *  \brief  _rots_timer_set_attr
 *              This function will stop timer, user should call timer_start() by self.
 *
 *  \param [in] timer           handle of timer
 *  \param [in] period_usec     new period msec
 *  \param [in] cb_routine      new callback routine
 *  \return
 *      0       : success
 *      others  : fail
 *  \details
 */
static int
_rots_timer_set_attr(hplc_timer_t  timer, uint32_t  period_usec, CB_TIMER_ROUTINE  cb_routine)
{
    int     rval = -1;

    _assert(timer);
    _assert(cb_routine);

    do {
        timer_mgr_t     *pTmgr = (timer_mgr_t*)timer;
        uint32_t        period_ms = pCfg->period_usec / 1000;
        BaseType_t      xHigherPriorityTaskWoken = pdFALSE;

        if( xTimerStopFromISR(pTmgr->tm, &xHigherPriorityTaskWoken) != pdPASS )
            break;

        if( xTimerChangePeriodFromISR(pTmgr->tm, (period_ms / portTICK_PERIOD_MS,
                                      &xHigherPriorityTaskWoken) != pdPASS )
        {
            xTimerStartFromISR(pTmgr->tm, &xHigherPriorityTaskWoken);
            break;
        }

        pTmgr->cb_routine = cb_routine;

        #if 0
        // context switch to higher priority task
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
        #endif

        rval = 0;
    } while(0);
    return rval;
}

//---------------------------------
// event
static hplc_event_t
_rtos_event_create(hplc_event_cfg_t *pCfg)
{
    int                 rval = -1;
    event_mgr_t         *pEv = 0;
    do {
        if( !(pEv = (event_mgr_t*)pvPortMalloc(sizeof(event_mgr_t))) )
            break;

        memset(pEv, 0x0, sizeof(event_mgr_t));

        pEv->sem = xSemaphoreCreateBinary();
        if( pEv->sem == NULL )     break;

        rval = 0;
    } while(0);

    if( rval )
    {
        if( pEv )       vPortFree(pEv);
        pEv = 0;
    }
    return (hplc_event_t)pEv;
}

static int
_rtos_event_destroy(hplc_event_t hEv)
{
    event_mgr_t         *pEv = (event_mgr_t*)hEv;

    _assert(hEv);

    vSemaphoreDelete(pEv->sem);
    vPortFree(pEv);
    return 0;
}

/**
 *  \brief  _rtos_event_wait
 *
 *  \param [in] hEv     handle of event
 *  \param [in] msec    milli-second
 *  \return
 *      false:  time out or some error
 *      true:   get event
 *
 *  \details
 */
static int
_rtos_event_wait(hplc_event_t hEv, int msec)
{
    event_mgr_t         *pEv = (event_mgr_t*)hEv;

    _assert(hEv);

    msec = (msec < 0) ? portMAX_DELAY : (msec / portTICK_PERIOD_MS);

    return xSemaphoreTake(pEv->sem, msec);
}

/**
 *  \brief  _rtos_event_signal
 *              This function will trigger event and context switch higher priority task
 *
 *  \param [in] hEv     handle of event
 *  \return
 *
 *  \details
 */
static int
_rtos_event_signal(hplc_event_t hEv)
{
    event_mgr_t         *pEv = (event_mgr_t*)hEv;
    BaseType_t          xHigherPriorityTaskWoken = pdFALSE;
    BaseType_t          xResult = pdFALSE;

    _assert(hEv);

    xResult = xSemaphoreGiveFromISR(pEv->sem, &xHigherPriorityTaskWoken);
    if( xResult == pdTRUE )
    {
        // context switch to higher priority task
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
    }

    return 0;
}


//---------------------------------
// event flag
static hplc_evflag_t
_rtos_evflag_create(
    hplc_evflag_cfg_t   *pCfg)
{
    int                 rval = -1;
    evflag_mgr_t        *pEvflg = 0;
    do {
        if( !(pEvflg = (evflag_mgr_t*)pvPortMalloc(sizeof(evflag_mgr_t))) )
            break;

        memset(pEv, 0x0, sizeof(evflag_mgr_t));

        pEvflg->evg = xEventGroupCreate();
        if( pEvflg->evg == NULL )   break;

        rval = 0;
    } while(0);

    if( rval )
    {
        if( pEvflg->evg )   vEventGroupDelete(pEvflg->evg);
        if( pEvflg )        vPortFree(pEvflg);

        pEvflg = 0;
    }
    return (hplc_evflag_t)pEvflg;
}

static int
_rtos_evflag_destroy(
    hplc_evflag_t   hEvflag)
{
    evflag_mgr_t        *pEvflg = (evflag_mgr_t*)hEvflag;

    _assert(hEvflag);

    vEventGroupDelete(pEvflg->evg);

    vPortFree(pEvflg);
    return 0;
}

/**
 *  \brief  _rtos_evflag_wait
 *
 *  \param [in] hEvflag     handle of event flag
 *  \param [in] wait_flags  the bitmap of waiting
 *  \param [in] msec        milli-second
 *  \return
 *      the bitmap of triggered events
 *  \details
 */
static uint32_t
_rtos_evflag_wait(
    hplc_evflag_t   hEvflag,
    uint32_t        wait_flags,
    int             msec)
{
    uint32_t        ev_flag = 0;
    evflag_mgr_t    *pEvflg = (evflag_mgr_t*)hEvflag;
    TickType_t      xTicksToWait = msec / portTICK_PERIOD_MS;

    _assert(hEvflag);

    ev_flag = (uint32_t)xEventGroupWaitBits(pEvflg->evg, wait_flags,
                                            pdTRUE, pdFALSE, xTicksToWait);

    return ev_flag;
}

/**
 *  \brief  _rtos_evflag_signal
 *              This function will trigger event and context switch higher priority task
 *
 *  \param [in] hEvflag     handle of event flag
 *  \param [in] ev_flag     the bitmap of triggered events
 *  \return
 *      0 : success
 *      -1: fail
 *  \details
 */
static int
_rtos_evflag_signal(
    hplc_evflag_t   hEvflag,
    uint32_t        ev_flag)
{
    evflag_mgr_t    *pEvflg = (evflag_mgr_t*)hEvflag;
    BaseType_t      xHigherPriorityTaskWoken = pdFALSE;
    BaseType_t      xResult = pdFALSE;

    _assert(hEvflag);

    xResult = xEventGroupSetBitsFromISR(pEvflg->evg, ev_flag, &xHigherPriorityTaskWoken);
    if( xResult != pdFAIL )
    {
        // context switch to higher priority task
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
    }
    return (xResult == pdFAIL) ? -1 : 0;
}
//=============================================================================
//                  Public Function Definition
//=============================================================================
hplc_timer_desc_t   g_hplc_rtos_timer =
{
    .timer_create   = _rots_timer_create,
    .timer_start    = _rots_timer_start,
    .timer_stop     = _rots_timer_stop,
    .timer_destroy  = _rots_timer_destroy,
    .timer_get_msec = _rots_timer_get_msec,
    .timer_get_usec = _rots_timer_get_usec,
    .timer_set_attr = _rots_timer_set_attr,
};


hplc_event_desc_t       g_hplc_rtos_event =
{
    .event_create  = _rtos_event_create,
    .event_destroy = _rtos_event_destroy,
    .event_wait    = _rtos_event_wait,
    .event_signal  = _rtos_event_signal,
};


hplc_evflag_desc_t      g_hplc_rtos_evflag =
{
    .evflag_create  = _rtos_evflag_create,
    .evflag_destroy = _rtos_evflag_destroy,
    .evflag_wait    = _rtos_evflag_wait,
    .evflag_signal  = _rtos_evflag_signal,
};

