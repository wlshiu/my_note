MCU Debugging
---

# Memory usage

## system memory usage

靜態分析

## Run-Time usage

## Heap Pollution

over flow


# CPU usage

## Bare-metal


## OS

Task + ISR

```
                Task       ISR
                  |
    switch_in --->|
                  |
                  |    ISR_in
                  +-------->+
                            |
                            |
                  +<--------+
                  |    ISR_out
                  |
   switch_out <---|
                  |

   task_use_time = switch_out - switch_in - (ISR_out - ISR_in)
```

# Critical Section detection

performance analysis (the max spend-time)

# Dead-lock detection

mutex/semaphore

