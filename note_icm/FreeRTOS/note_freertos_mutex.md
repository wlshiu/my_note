Freertos Mutex [[Back](note_freertos_queue.md)]
---

+ **有優先級繼承**機制, 可以避免優先級翻轉, 必須**在同一個 task 中 Take 信號, 且同一個 task 中 Give 信號**
    > 不可用於 ISR

+ 適用於互斥訪問 (Critical Section Protection)

# API
## xSemaphoreCreateMutex

```c
SemaphoreHandle_t xSemaphoreCreateMutex( void );

SemaphoreHandle_t xSemaphoreCreateMutexStatic(
                            StaticSemaphore_t *pxMutexBuffer );
```

+ Example usage

    - dynamic

        ```c
        SemaphoreHandle_t   xSemaphore;

        void vATask( void * pvParameters )
        {
           /* Create a mutex type semaphore. */
           xSemaphore = xSemaphoreCreateMutex();

           if( xSemaphore != NULL )
           {
               /* The semaphore was created successfully and
               can be used. */
           }
        }
        ```

    - static

        ```c
        SemaphoreHandle_t   xSemaphore = NULL;
        StaticSemaphore_t   xMutexBuffer;

        void vATask( void * pvParameters )
        {
            /* Create a mutex semaphore without using any dynamic memory
             * allocation.  The mutex's data structures will be saved into
             * the xMutexBuffer variable.
             */
            xSemaphore = xSemaphoreCreateMutexStatic( &xMutexBuffer );

            /* The pxMutexBuffer was not NULL, so it is expected that the
             * handle will not be NULL.
             */
            configASSERT( xSemaphore );

            /* Rest of the task code goes here. */
        }
        ```

## xSemaphoreCreateRecursiveMutex

```c
SemaphoreHandle_t xSemaphoreCreateRecursiveMutex( void );

SemaphoreHandle_t xSemaphoreCreateRecursiveMutexStatic(
                              StaticSemaphore_t *pxMutexBuffer );
```

+ Example usage

    - dynamic

        ```c
        SemaphoreHandle_t xMutex;

        void vATask( void * pvParameters )
        {
            Create a recursive mutex.
            xMutex = xSemaphoreCreateRecursiveMutex();

            if( xMutex != NULL )
            {
                /* The recursive mutex was created successfully and
                 * can now be used.
                 */
            }
        }
        ```

    - static

        ```c
        SemaphoreHandle_t   xSemaphore = NULL;
        StaticSemaphore_t   xMutexBuffer;

        void vATask( void * pvParameters )
        {
            /* Create a recursivemutex semaphore without using any dynamic
             * memory allocation.  The mutex's data structures will be saved into
             * the xMutexBuffer variable.
             */
            xSemaphore = xSemaphoreCreateRecursiveMutexStatic( &xMutexBuffer );

            /* The pxMutexBuffer was not NULL, so it is expected that the
             * handle will not be NULL.
             */
            configASSERT( xSemaphore );

            /* Rest of the task code goes here. */
        }
        ```

## xSemaphoreTakeRecursive/xSemaphoreGiveRecursive

用於 Mutex

+ xSemaphoreTakeRecursive

    ```c
    BaseType_t xSemaphoreTakeRecursive( SemaphoreHandle_t xMutex,
                                        TickType_t xTicksToWait );
    ```

+ xSemaphoreGiveRecursive

    ```c
    BaseType_t xSemaphoreGiveRecursive( SemaphoreHandle_t xMutex );
    ```

+ Example usage

    ```c
    SemaphoreHandle_t   xMutex = NULL;

    // A task that creates a mutex.
    void vATask( void * pvParameters )
    {
        // Create the mutex to guard a shared resource.
        xMutex = xSemaphoreCreateRecursiveMutex();
    }

    // A task that uses the mutex.
    void vAnotherTask( void * pvParameters )
    {
        if( xMutex != NULL )
        {
            /* See if we can obtain the mutex.  If the mutex is not available
             * wait 10 ticks to see if it becomes free.
             */
            if( xSemaphoreTakeRecursive( xMutex, ( TickType_t ) 10 ) == pdTRUE )
            {
                /* We were able to obtain the mutex and can now access the
                 * shared resource.
                 */

                ...
                /* For some reason due to the nature of the code further calls to
                 * xSemaphoreTakeRecursive() are made on the same mutex.  In real
                 * code these would not be just sequential calls as this would make
                 * no sense.  Instead the calls are likely to be buried inside
                 * a more complex call structure.
                 */
                xSemaphoreTakeRecursive( xMutex, ( TickType_t ) 10 );
                xSemaphoreTakeRecursive( xMutex, ( TickType_t ) 10 );

                /* The mutex has now been 'taken' three times, so will not be
                 * available to another task until it has also been given back
                 * three times.  Again it is unlikely that real code would have
                 * these calls sequentially, but instead buried in a more complex
                 * call structure.  This is just for illustrative purposes.
                 */
                xSemaphoreGiveRecursive( xMutex );
                xSemaphoreGiveRecursive( xMutex );
                xSemaphoreGiveRecursive( xMutex );

                // Now the mutex can be taken by other tasks.
            }
            else
            {
                /* We could not obtain the mutex and can therefore not access
                 * the shared resource safely.
                 */
            }
        }
    }
    ```

# xSemaphoreGetMutexHolder

目前得到 Mutex 的 task (TCB)

```c
TaskHandle_t xSemaphoreGetMutexHolder( SemaphoreHandle_t xMutex );

TaskHandle_t xSemaphoreGetMutexHolderFromISR( SemaphoreHandle_t xMutex );
```

# reference




