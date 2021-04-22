Freertos Semaphore [[Back](note_freertos_queue.md)]
---

# Semaphore

## xSemaphoreCreateCounting

```c
SemaphoreHandle_t xSemaphoreCreateCounting( UBaseType_t uxMaxCount,
                                            UBaseType_t uxInitialCount);

SemaphoreHandle_t xSemaphoreCreateCountingStatic(
                                 UBaseType_t uxMaxCount,
                                 UBaseType_t uxInitialCount
                                 StaticSemaphore_t *pxSemaphoreBuffer );
```

+ Example usage

    - dynamic

        ```c
        void vATask( void * pvParameters )
        {
            SemaphoreHandle_t   xSemaphore;

            /* Create a counting semaphore that has a maximum count of 10 and an
             * initial count of 0.
             */
            xSemaphore = xSemaphoreCreateCounting( 10, 0 );

            if( xSemaphore != NULL )
            {
                /* The semaphore was created successfully. */
            }
        }
        ```

    - static

        ```c
        static StaticSemaphore_t    xSemaphoreBuffer;

        void vATask( void * pvParameters )
        {
            SemaphoreHandle_t xSemaphore;

            /* Create a counting semaphore that has a maximum count of 10 and an
             * initial count of 0.  The semaphore's data structures are stored in the
             * xSemaphoreBuffer variable - no dynamic memory allocation is performed.
             */
            xSemaphore = xSemaphoreCreateCountingStatic( 10, 0, &xSemaphoreBuffer );

            /* pxSemaphoreBuffer was not NULL so it is expected that the semaphore
             * will be created.
             */
            configASSERT( xSemaphore );
        }
    ```

# Binary Semaphore

## xSemaphoreCreateBinary

```c
SemaphoreHandle_t xSemaphoreCreateBinary( void );

SemaphoreHandle_t xSemaphoreCreateBinaryStatic(
                          StaticSemaphore_t *pxSemaphoreBuffer );
```

+ Example usage

    - dynamic

        ```c
        SemaphoreHandle_t   xSemaphore;

        void vATask( void * pvParameters )
        {
            /* Attempt to create a semaphore. */
            xSemaphore = xSemaphoreCreateBinary();

            if( xSemaphore == NULL )
            {
                /* There was insufficient FreeRTOS heap available for the semaphore to
                 * be created successfully.
                 */
            }
            else
            {
                /* The semaphore can now be used. Its handle is stored in the
                 * xSemahore variable.  Calling xSemaphoreTake() on the semaphore here
                 * will fail until the semaphore has first been given.
                 */
            }
        }
        ```

    - static

        ```c
        SemaphoreHandle_t   xSemaphore = NULL;
        StaticSemaphore_t   xSemaphoreBuffer;

        void vATask( void * pvParameters )
        {
            /* Create a binary semaphore without using any dynamic memory
             * allocation.  The semaphore's data structures will be saved into
             * the xSemaphoreBuffer variable.
             */
            xSemaphore = xSemaphoreCreateBinaryStatic( &xSemaphoreBuffer );

            /* The pxSemaphoreBuffer was not NULL, so it is expected that the
             * handle will not be NULL.
             */
            configASSERT( xSemaphore );

            /* Rest of the task code goes here. */
        }
        ```

# Common

## vSemaphoreDelete

可用於 **xSemaphoreCreateCounting()**, **xSemaphoreCreateBinary()** 或 **xSemaphoreCreateMutex()**.

```c
void vSemaphoreDelete( SemaphoreHandle_t xSemaphore );
```

## uxSemaphoreGetCount

獲取信號量值
> 當 Binary Semaphore 情況時
> + `1`: semaphore 可得
> + `0`: semaphore 不可得

```c
UBaseType_t uxSemaphoreGetCount( SemaphoreHandle_t xSemaphore );
```

## xSemaphoreTake

`xSemaphoreTake`可用於 **xSemaphoreCreateCounting()**, **xSemaphoreCreateBinary()** 或 **xSemaphoreCreateMutex()**.

`xSemaphoreTakeFromISR`則用於 **xSemaphoreCreateCounting()** 或 **xSemaphoreCreateBinary()**.


```c
BaseType_t xSemaphoreTake( SemaphoreHandle_t xSemaphore,
                           TickType_t xTicksToWait );

BaseType_t xSemaphoreTakeFromISR( SemaphoreHandle_t xSemaphore,
                                  signed BaseType_t *pxHigherPriorityTaskWoken );
```

+ Example usage

    ```c
    SemaphoreHandle_t   xSemaphore = NULL;

    /* A task that creates a semaphore. */
    void vATask( void * pvParameters )
    {
        /* Create the semaphore to guard a shared resource.  As we are using
         * the semaphore for mutual exclusion we create a mutex semaphore
         * rather than a binary semaphore.
         */
        xSemaphore = xSemaphoreCreateMutex();
    }

    /* A task that uses the semaphore. */
    void vAnotherTask( void * pvParameters )
    {
        if( xSemaphore != NULL )
        {
            /* See if we can obtain the semaphore.  If the semaphore is not
             * available wait 10 ticks to see if it becomes free.
             */
            if( xSemaphoreTake( xSemaphore, ( TickType_t ) 10 ) == pdTRUE )
            {
                /* We were able to obtain the semaphore and can now access the
                 * shared resource.
                 */

                ...

                /* We have finished accessing the shared resource.
                 * Release the semaphore.
                 */
                xSemaphoreGive( xSemaphore );
            }
            else
            {
                /* We could not obtain the semaphore and can therefore not access
                 * the shared resource safely.
                 */
            }
        }
    }
    ```


## xSemaphoreGive

`xSemaphoreGive`可用於 **xSemaphoreCreateCounting()**, **xSemaphoreCreateBinary()** 或 **xSemaphoreCreateMutex()**.

`xSemaphoreGiveFromISR`則用於 **xSemaphoreCreateCounting()** 或 **xSemaphoreCreateBinary()**


```c
BaseType_t xSemaphoreGive( SemaphoreHandle_t xSemaphore );

BaseType_t xSemaphoreGiveFromISR( SemaphoreHandle_t xSemaphore,
                                  signed BaseType_t *pxHigherPriorityTaskWoken );



```

+ Example usage

    ```c
    SemaphoreHandle_t   xSemaphore = NULL;

    void vATask( void * pvParameters )
    {
        /* Create the semaphore to guard a shared resource.  As we are using
         * the semaphore for mutual exclusion we create a mutex semaphore
         * rather than a binary semaphore.
         */
        xSemaphore = xSemaphoreCreateMutex();

        if( xSemaphore != NULL )
        {
            if( xSemaphoreGive( xSemaphore ) != pdTRUE )
            {
                /* We would expect this call to fail because we cannot give
                 * a semaphore without first "taking" it!
                 */
            }

            /* Obtain the semaphore - don't block if the semaphore is not
             * immediately available.
             */
            if( xSemaphoreTake( xSemaphore, ( TickType_t ) 0 ) )
            {
                /* We now have the semaphore and can access the shared resource.
                 * ...
                 * We have finished accessing the shared resource so can free the
                 * semaphore.
                 */
                if( xSemaphoreGive( xSemaphore ) != pdTRUE )
                {
                    /* We would not expect this call to fail because we must have
                     * obtained the semaphore to get here.
                     */
                }
            }
        }
    }
    ```

    - FromISR

        ```c
        #define LONG_TIME           0xffff
        #define TICKS_TO_WAIT       10

        SemaphoreHandle_t   xSemaphore = NULL;

        /* Repetitive task. */
        void vATask( void * pvParameters )
        {
            /* We are using the semaphore for synchronisation so we create a binary
             * semaphore rather than a mutex.  We must make sure that the interrupt
             * does not attempt to use the semaphore before it is created!
             */
            xSemaphore = xSemaphoreCreateBinary();

            for( ;; )
            {
                /* We want this task to run every 10 ticks of a timer.  The semaphore
                 * was created before this task was started.
                 */

                /* Block waiting for the semaphore to become available. */
                if( xSemaphoreTake( xSemaphore, LONG_TIME ) == pdTRUE )
                {
                    /* It is time to execute. */

                    ...

                    /* We have finished our task.  Return to the top of the loop where
                    * we will block on the semaphore until it is time to execute
                    * again.  Note when using the semaphore for synchronisation with an
                    * ISR in this manner there is no need to 'give' the semaphore back.
                    */
                }
            }
        }

        /* Timer ISR */
        void vTimerISR( void * pvParameters )
        {
            static unsigned char        ucLocalTickCount = 0;
            static signed BaseType_t    xHigherPriorityTaskWoken;

            /* A timer tick has occurred. */

            ... Do other time functions.

            /* Is it time for vATask() to run? */
            xHigherPriorityTaskWoken = pdFALSE;
            ucLocalTickCount++;
            if( ucLocalTickCount >= TICKS_TO_WAIT )
            {
                /* Unblock the task by releasing the semaphore. */
                xSemaphoreGiveFromISR( xSemaphore, &xHigherPriorityTaskWoken );

                /* Reset the count so we release the semaphore again in 10 ticks time. */
                ucLocalTickCount = 0;
            }

            /* If xHigherPriorityTaskWoken was set to true you
             * we should yield.  The actual macro used here is
             * port specific.
             */
            portYIELD_FROM_ISR( xHigherPriorityTaskWoken );
        }
        ```

# reference

+ [FreeRTOS系列第19篇---FreeRTOS信號量](https://blog.csdn.net/zhzht19861011/article/details/50835613)

+ [Semaphore / Mutexes](https://www.freertos.org/a00113.html)

