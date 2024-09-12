Nuclei RISCV SDK [[Back](n_riscv_intro.md#Nuclei_SDK)]
---

# APIs analysis

## `measure_cpu_freq()`

```
static unsigned long __attribute__((noinline)) measure_cpu_freq(size_t n)
{
    uint32_t start_mcycle, delta_mcycle;
    uint32_t start_mtime, delta_mtime;
    uint64_t mtime_freq = get_timer_freq();

    /**
     *  Don't start measuruing until we see an mtime tick.
     *  SysTimer_GetLoadValue() return 'CSR_MTIME' value
     */
    uint32_t tmp = (uint32_t)SysTimer_GetLoadValue();
    do {
        start_mtime = (uint32_t)SysTimer_GetLoadValue(); // monitor CSR_MTIME 並將其值作為初始時間值
        start_mcycle = __RV_CSR_READ(CSR_MCYCLE);        // monitor CSR_MCYCLE 並將其值作為初始時間值
    } while (start_mtime == tmp);

    do {
        // monitor CSR_MTIME 直到預期的 duration ticks
        delta_mtime = (uint32_t)SysTimer_GetLoadValue() - start_mtime;

        // 紀錄在 CSR_MTIME 間隔時間中, CSR_MCYCLE 的 duration ticks
        delta_mcycle = __RV_CSR_READ(CSR_MCYCLE) - start_mcycle;
    } while (delta_mtime < n);


    /**
     *  由於 CSR_MTIME 的 freq 是 Always-On Domain 的參考頻率(e.g. 32.768 KHz),
     *  而 Core 的運行頻率與 CSR_MCYCLE 的值一致.
     *  因此可以通過 CSR_MCYCLE 和 CSR_MTIME 的"比例關係", 計算出當前 Core 的 freq
     *
     *  ps.有關 N200 系列配套 SoC 的 clock domain 劃分, 請參見單獨文件: Nuclei_N200系列配套SoC介紹
     */
    return (delta_mcycle / delta_mtime) * mtime_freq
           + ((delta_mcycle % delta_mtime) * mtime_freq) / delta_mtime;
}
```


# Reference

