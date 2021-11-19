

uint32_t    g_multipliter = SystemCoreClock / 4000000; // SystemClock / (1MHz * 4 Tick)

void DelayUs(uint32_t us)
{
    /* multiply micro with multipliter */
    us = g_multipliter * us - 10;
    /* 4 cycles for one loop */
    while(us--);
}


void DelayMs(uint32_t ms)
{
    /* multiply mills with multipliter */
    ms = g_multipliter * ms * 1000 - 10;
    /* 4 cycles for one loop */
    while(ms--);
}

//===========================================
// with H/w Timer HCLK 72MHz
// + First of all, set the clock source as internal clock.
// + Prescaler divides the Timer clock further, by the value that you input in the prescaler.
// + As we want the delay of 1 microsecond, the timer frequency must be (1/(1 us)), i.e 1 MHz.
//      And for this reason, the prescaler value is 72.
// + Note that it’s 72-1, because the prescaler will add 1 to any value that you input there.
// + The ARR I am setting is the max value it can have.
// + Basically, the counter is going to count from 0 to this value. Every count will take 1 us.
//      So setting this value as high as possible is the best, because this way you can have large delays also.
// + I have set it to 0xffff-1, and it is the maximum value that a 16 bit register (ARR) can have.
HAL_TIM_Base_Start(&htim1)
{
    prescaler           = 72 -1;
    AutoReloadReg (ARR) = 0xffff - 1;
}

void delay_us (uint16_t us)
{
    __HAL_TIM_SET_COUNTER(&htim1, 0);       // set the counter value a 0
    while (__HAL_TIM_GET_COUNTER(&htim1) < us);  // wait for the counter to reach the us input in the parameter
}
