# Qt Multi-thread Sync [[Back](note_qt_prog.md#Multi-thread)]

## QMutex

All functions in QMutex class are thread-safe.

QMutex(QMutex::RecursionMode mode)
> enum RecursionMode { Recursive, NonRecursive }
> + QMutex::Recursive    = 1
> + QMutex::NonRecursive = 0 (default)
>> In this mode, a thread may only lock a mutex once.

+ Methods

    ```C++
    QMutex  mutex;

    void Thread::run()
    {
        mutex.lock();  // mutex lock

        qDebug() << "123" << QThread::currentThreadId();
        qDebug() << "456" << QThread::currentThreadId();

        mutex.unlock(); // mutex unlock
    }
    ```

    - QMutex::lock()
        > 等同於 `pthread_mutex_lock()`, 會 **Blocking** 程式流程

    - QMutex::unlock()
        > 等同於 `pthread_mutex_unlock()`

    - bool QMutex::tryLock(int timeout = 0)
        > 如果可以 lock 則會回傳 ture, 否則回傳 false, 可看做 mutex lock 的 Non-Blcoking mode
        >> `timeout < 0` 則等同 Blcoking mode

        ```c++
        void Thread_A::run()
        {
            mutex.tryLock();

            while( flgRunning == true )
            {
                printf("Hello,World!\n");

                sleep(1);
            }

            mutex.unlock();
        }
        ```

        1. Support recursive lock
            > 當 Non-Recursive mode 時, 會在 recursive lock 時, 回傳 false



## QMutexLocker

All functions in QMutexLocker class are thread-safe.

**QMutexLocker** 簡化 QMutex 的使用並增加可讀性, user 只需要注意 **Life-Cycle**
> + Constructor 時, 執行 mutex lock
> + Destructor 時, 執行 mutex unlock

QMutexLocker(QMutex *mutex);

```c++
int complexFunction(int flag)
{
    QMutexLocker    locker(&mutex); // 需帶入一個 QMutex

    ...

    /**
     *  End of life-cycle of the locker object,
     *  unlock mutex in Destructor of locker
     */
    return 0;
}
```

+ Methods

    - `QMutex *QMutexLocker::mutex()`
        > 傳回帶入的 QMutex

    - `void QMutexLocker::unlock()`
        > 直接 unlock, 不用等到 Destructor

    - `void QMutexLocker::relock()`
        > 重新 lock mutex, 搭配 unlock() 使用


## QWaitCondition

```c++
QMutex          mutex;
QWaitCondition  keyPressed;

void Thread_A::run()
{
    mutex.lock();

    keyPressed.wait(&mutex);

    // do_something...

    mutex.unlock();
}

void Thread_B::run()
{
    ...

    keyPressed.wakeAll();

    ...
    return;
}
```

+ Methods

    - `bool QWaitCondition::wait(QMutex * mutex, unsigned long time = ULONG_MAX)`
        > 等同於 `pthread_cond_wait()`

    - `void QWaitCondition::wakeOne()`
        > 等同 `pthread_cond_signal()`
        >> 依照 OS scheduling policies 來喚醒所有等待此 mutex 的 threads 中的其中一個 thread

    - `void QWaitCondition::wakeAll()`
        > 等同 `pthread_cond_broadcast()`
        >> 喚醒所有等待此 mutex 的 threads (順序無法預期)


## QReadWriteLock

## QSemaphore




## QQueue

Provide a generic container (Template attribute) with FIFO (First In, First Out) queue.
> Inherits:	QList

可用於 Multi-thread 間 Asynchronous 訊息傳遞,

```c++
void foo()
{
    QQueue<int>     queue;

    queue.enqueue(1);
    queue.enqueue(2);
    queue.enqueue(3);

    while( !queue.isEmpty() )
        cout << queue.dequeue() << Qt::endl;

    /**
     *  Output reault:
     *      1 2 3
     */
}
```

+ Methods

    - `T QQueue::dequeue()`
        > Get item from this QQueue with FIFO order

    - `void QQueue::enqueue(const T &t)`
        > Push item to this QQueue

    - `QQueue::isEmpty()`
        > method of QList

# Reference

+ [Qt同步線程(QMutex QMutexLocker QReadWriteLock QSemaphore QWaitCondition)](https://www.cnblogs.com/xiangtingshen/p/11267523.html)
+ [C++中的queue類與QT中的QQueue類](https://www.twblogs.net/a/5d2dcbcabd9eee1ede077dad)
