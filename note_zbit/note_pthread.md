note_pthread
---

# APIs of Pthreads

在 pthreads 函數介面可以分為以下三類(關於函數的具體介面參考文章末尾)
> + 執行緒管理(thread management)
>> 用於執行緒建立, detach, join 已經設定和查詢執行緒屬性的函數 <br>
主要函數有: pthread_create, pthread_exit, pthread_detach, pthread_join, pthread_self
> + Mutex 操作函數：用來保證資源的互斥訪問, 它用來實現多執行緒訪問資料時的同步機制.
>> 主要函數有： pthread_mutex_init, pthread_mutex_lock, pthread_mutex_unlock
> + 狀態變數操作函數. 這類函數用來建立共享 mutex 的多執行緒通訊. 它根據程式設計師設定的條件, 來決定是否發出訊號(signal)或者等待(wait).
>> 主要函數有： pthread_cond_init, pthread_cond_signal, pthread_cond_wait.


## pthreads 常用API 參考(源於網路)

### Thread management

+ pthread_create
    > 建立一個執行緒

    ```
    pthread_create(pthread_t *tid,
                   const pthread_attr_t *attr,
                   void*(*start_routine)(void*),
                   void *arg);

    用途: 建立一個執行緒
    參數：
    + tid 用於返回新建立執行緒的執行緒號；
    + start_routine 是執行緒函數指針, 執行緒從這個函數開始獨立地運行；
    + arg 是傳遞給執行緒函數的參數. 由於 start_routine 是一個指向參數類型為void*, 返回值為 void* 的指針,
            所以如果需要傳遞或返回多個參數時, 可以使用強制類型轉化.
    ```

+ pthread_exit
    > 退出執行緒

    ```
    void pthread_exit(void* value_ptr);

    用途: 退出執行緒
    參數： value_ptr 是一個指向返回狀態值的指針.
    ```

    - example

        ```
        int main(void)
        {
            pthread_t tid[2];
            pthread_create(&tid[0],NULL,thread_one,NULL);
            pthread_create(&tid[1],NULL,thread_two,NULL);

            // pthread_exit(NULL); <--- 會等待 sub-thereads exit
            return 0;              <--- 直接 close program (sub-thereads 強制 cancel)
        }
        ```

+ pthread_join
    > 用來等待一個其他特定 thread 跑完時, 再繼續往下執行的情境使用

    ```
    int pthread_join(pthread_t tid, void **status);

    參數:
    + tid 是希望等待的執行緒的執行緒號,
    + status 是指向執行緒返回值的指針,
    + 執行緒的返回值就是
        - pthread_exit 中的 value_ptr 參數,
        - 或者是 return 語句中的返回值
    ```

### Synchronization and Protect resource

用來保護 resource 免於競爭狀態 (race condition) 而造成的 inconsistencies

+ pthread_mutex_init
    > 初始化一個互斥體變數

    ```
    int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutex_attr_t *attr);

    參數:
    + mutex 互斥體變數
    + attr 如果為 NULL, 則使用默認的屬性.
    ```

+ pthread_mutex_lock
    > 鎖住所指的互斥體變數 (blocking mode)

    ```
    int pthread_mutex_lock(pthread_mutex_t *mutex);

    // 如果參數 mutex 所指的互斥體已經被鎖住了, 那麼發出呼叫的執行緒將被阻塞, 直到其他執行緒對 mutex 解鎖.
    ```

+ pthread_mutex_trylock
    > 鎖住所指的互斥體變數 (non-blocking mode)

    ```
    int pthread_mutex_trylock(pthread_t *mutex);

    // 用來鎖住 mutex 所指定的互斥體, 但不阻塞.
    // 如果該互斥體已經被上鎖, 該 function 不會阻塞等待, 而會返回一個錯誤程式碼.
    ```

+ pthread_mutex_unlock
    > 解鎖所指的互斥體變數

    ```
    int pthread_mutex_unlock(pthread_mutex_t *mutex);

    // 用來對一個互斥體解鎖.
    // 如果當前執行緒, 擁有參數 mutex 所指定的互斥體, 該呼叫將解鎖該互斥體.
    ```

+ pthread_mutex_destroy
    > 釋放分配給參數 mutex 的 resource

    ```
    int pthread_mutex_destroy(pthread_mutex_t *mutex);

    // 用來釋放分配給參數mutex 的資源.
    // 成功時, 返回值 0, 否則返回一個 非0 的錯誤程式碼.
    ```

### Condition Variables Synchronization

條件變量 (condition variable) 是一種機制，它能夠允許 thread 暫時 suspend 並放棄搶 CPU 資源, 直到條件變量為 True 時. <br>
> 條件變量一定要搭配 mutex 使用, 以避免掉`race condition`的情境.
>> 比如說 `thread 1` 準備等待, 而另一個`thread 2`可能會在`thread 1`實際開始等待前, 便先 **signal** 了條件變量,
這將導致死結的發生 (互相等待，永不開始), 因為`thread 1`會一直等待不會被送來的 signal

+ pthread_cond_init
    > 按參數 attr 指定的屬性, 建立一個條件變數

    ```
    int pthread_cond_init(pthread_cond_t *cond, const pthread_cond_attr_t*attr);

    // 按參數attr指定的屬性建立一個條件變數.
    // 呼叫成功返回, 並將條件變數 ID 賦值給參數 cond, 否則返回錯誤程式碼.
    ```

+ pthread_cond_wait
    > 等待一個事件(由 cond 指定的條件變數)發生時, 解鎖指定的互斥體 (blocking mode)

    ```
    int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);

    // 等待一個事件(由 cond 指定的條件變數)發生,並解鎖指定的互斥體(mutex).
    // 呼叫該函數的執行緒將被阻塞, 直到有其他執行緒,
    // 呼叫擁有相同 cond 及 相同互斥體(mutex) 的 'pthread_cond_signal' 或 'pthread_cond_broadcast' 函數時, 才解除阻塞.
    ```

+ pthread_cond_timewait
    > 等待一個事件(由 cond 指定的條件變數)發生時, 解鎖指定的互斥體 (non-blocking mode, 有 timeout 機制)

    ```
    int pthread_cond_timewait(pthread_cond_t *cond, pthread_mutex_t *mutex, const struct timespec *abstime);

    // 該函數與 pthread_cond_wait 不同的是, 當系統時間到達 abstime 參數指定的時間時, 被阻塞執行緒也可以被喚起繼續執行.
    ```

+ pthread_cond_broadcast
    > 對所有 cond 所指定的執行緒, 解除阻塞

    ```
    int pthread_cond_broadcast(pthread_cond_t *cond);

    // 用來對所有等待參數 cond, 所指定的執行緒, 解除阻塞.
    // 呼叫成功返回 0, 否則返回錯誤程式碼.
    ```

+ pthread_cond_signal
    > 對 **一個** cond 所指定的執行緒, 解除阻塞

    ```
    int pthread_cond_signal(pthread_cond_t *cond);

    // 對一個等待參數 cond, 所指定的執行緒, 解除阻塞. 當有多個執行緒掛起等待該條件變數時, 也只喚醒一個執行緒.
    ```

+ pthread_cond_destroy
    > 釋放 cond 所分配的資源

    ```
    int pthread_cond_destroy(pthread_cond_t *cond);

    // 釋放一個條件變數 cond 所分配的資源.
    // 呼叫成功返回值為 0, 否則返回錯誤程式碼.
    ```

### Thread Specific Data (TSB)

建立 `單一執行緒的全域資料`(其它執行緒忽略或無法存取)
> 限制共享資料的範圍

```c
#include <pthread.h>
#include <stdio.h>
#include <malloc.h>
#include <memory.h>

#define THREAD_COUNT    3

struct pair
{
    int x, y;
};

typedef void *(*thread_cb)(void *);

pthread_key_t   key;

void print_thread1_key(void)
{
    int *p = (int *)pthread_getspecific(key);//將值從私有空間中取出來
    printf("thread 1 : %d\n", *p);
    return;
}

//thread 1 routine
void *thread1_proc(void *arg)
{
    int *p = (int *)malloc(sizeof(int));
    *p = 68725032;

    pthread_setspecific(key, p);//將 p 傳入私有空間中
    print_thread1_key();
    return;
}

void print_thread2_key(void)
{
    char *ptr = (char *) pthread_getspecific(key);
    printf("thread 2 : %s\n", ptr);
    return;
}

//thread 2 routine
void *thread2_proc(void *arg)
{
    char *ptr = (char *)malloc(1024 * sizeof(char));
    strcpy(ptr, "wxfnb");

    pthread_setspecific(key, ptr);
    print_thread2_key();
    return;
}

void print_thread3_key(void)
{
    struct pair *p = (struct pair *)pthread_getspecific(key);
    printf("thread 3  x: %d, y: %d\n", p->x, p->y);
    return;
}

//thread 3 routine
void *thread3_proc(void *arg)
{
    struct pair *p = (struct pair *)malloc(sizeof(struct pair));
    p->x = 1;
    p->y = 2;
    pthread_setspecific(key, p);
    print_thread3_key();
    return;
}

void destroy_func(void *val)
{
    printf("free key\n");
    free(val);
    return;
}

int main()
{
    pthread_t   th_id[THREAD_COUNT] = {0};    //3個執行緒id

    pthread_key_create(&key, destroy_func); //建立key， 這個全域變數可以認為是執行緒內部的私有空間

    thread_cb callback[THREAD_COUNT] =  // thread routines
    {
        thread1_proc,
        thread2_proc,
        thread3_proc
    };

    for(int i = 0; i < THREAD_COUNT; i++)  //建立執行緒
    {
        pthread_create(&th_id[i], NULL, callback[i], NULL);
    }

    for(int i = 0; i < THREAD_COUNT; i++)
    {
        pthread_join(th_id[i], NULL);//主執行緒需要等待子執行緒執行完成之後再結束
    }

    pthread_key_delete(key);
    return;
}
```

+ pthread_key_create
    > 建立一個 key 值

    ```
    int pthread_key_create(pthread_key_t key, void (*cb_destructor)(void*));
    // 建立一個 key (pthread_key_t) 值, .
    // 如果第二個參數不是 NULL, 則這個 key 值被刪除時, 將呼叫這個 cb_destructor 來釋放資料空間.
    ```

+ pthread_key_delete
    > 刪除一個由 pthread_key_create 函數所建立的 key

    ```
    int pthread_key_delete(pthread_key_t *key);

    // 該函數用於刪除一個由 pthread_key_create 函數 所建立的 key.
    // 呼叫成功返回值為 0, 否則返回錯誤程式碼.
    ```

+ pthread_setspecific
    > 設定 key 的 TSB

    ```
    int pthread_setspecific(pthread_key_t key, const void *pointer);

    // 設定一個執行緒專有資料 (TSB, Thread Specific Data)的值, 賦給由 pthread_key_create 建立的 key->TSD,
    // 呼叫成功返回值為0, 否則返回錯誤程式碼.
    ```

+ pthread_getspecific

    ```
    void* pthread_getspecific(pthread_key_t *key);

    // 獲得繫結到指定 key->TSD 的值.
    // 呼叫成功, 返回 key 所對應的 TSB 資料. 如果沒有資料連接到 key->TSD, 則返回 NULL.
    ```

### MISC

+ int pthread_self
    > 獲得目前執行緒的 UID (Multi-cores 時, 可能會出現相同的 thread UID)
    >> `system call: gettid()` 則是更嚴謹, 在 multi-cores 時, 也會有不同的 ID,

    ```
    int pthread_self(void)
    ```

+ pthread_once
    > 在多執行緒程式設計環境下, 儘管 pthread_once() 呼叫, 會出現在多個執行緒中, 但 `init_routine()`僅執行一次.
    >> `init_routine()` 究竟在哪個執行緒中執行是不定的, 這是由核心調度來決定

    ```
    int pthread_once(pthread_once_t* once_control, void (*cb_init_routine)(void));
    // 確保 cb_init_routine 函數, 在呼叫 pthread_once 的執行緒中, 只被運行一次.
    // once_control 指向一個靜態或全域的變數.
    ```


# Reference

+ [POSIX Threads Programming](https://hpc-tutorials.llnl.gov/posix/)
+ [跨平台多執行緒程式設計](http://blog.chinaunix.net/uid-20776117-id-1847029.html)
+ [Pthread tutorial](https://hackmd.io/@Scherzando/Hy4S4y8JB#Pthread-tutorial)
+ [Linux執行緒私有資料Thread-specific Data(TSD) 詳解](https://zhuanlan.zhihu.com/p/554292655)

