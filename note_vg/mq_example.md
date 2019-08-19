
[ref](https://www.itread01.com/content/1547441654.html)

# mq_attr

```c
struct mq_attr {
	long mq_flags;       /* Flags: 0 or O_NONBLOCK */
	long mq_maxmsg;      /* Max. # of messages on queue */
	long mq_msgsize;     /* Max. message size (bytes) */
	long mq_curmsgs;     /* # of messages currently in queue */
};
```

+ mq_setattr函式只允許設定mq_attr結構的mq_flags成員，其它三個成員被忽略。
+ 指向某個mq_attr結構的指標可作為mq_open的第四個引數傳遞，每個佇列的最大訊息數和每個訊息的最大位元組數隻能在建立佇列時設定，而且這兩者必須同時指定。

+ 訊息佇列中的當前訊息數則只能獲取不能設定。


# mq-send.c

    mq_send的prio引數是待發送訊息的優先順序，其值必須小於MQ_PRIO_MAX。如果應用不必使用優先順序不同的訊息，那就給mq_send指定值為0的優先順序，給mq_reveive指定一個空指標作為其最後一個引數

```c
// mq-send.c
#include <fcntl.h>
#include <sys/stat.h>
#include <mqueue.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    struct mq_attr attr;
    attr.mq_maxmsg = 24; /* 設定訊息佇列的最大訊息個數 */
    attr.mq_msgsize = 8192; /* 設定每個訊息的最大位元組數 */

    char *name = "/temp.mq"; /* linux必須是/filename這種格式，不能出現二級目錄 */
    mqd_t mqd = mq_open(name, O_RDWR | O_CREAT | O_EXCL, 0777, &attr);
    if (mqd == -1) {
        perror("create failed");
        mqd = mq_open(name, O_RDWR);
        if (mqd == -1) {
            perror("open failed");
            exit(EXIT_FAILURE);
        }
    }
    printf("mq_open %s success\n", name);

    /* 開啟成功，獲取當前屬性 */
    mq_getattr(mqd, &attr);
    printf("max msg = %ld, max bytes = %ld, currently = %ld\n",
            attr.mq_maxmsg, attr.mq_msgsize, attr.mq_curmsgs);

    char *msg_ptr1 = "hello world1";
    char *msg_ptr2 = "hello world2";
    char *msg_ptr3 = "hello world3";
    size_t msg_len1 = strlen(msg_ptr1);
    size_t msg_len2 = strlen(msg_ptr2);
    size_t msg_len3 = strlen(msg_ptr3);

    /* 先發送優先順序低的 */
    mq_send(mqd, msg_ptr1, msg_len1, 1);
    mq_send(mqd, msg_ptr2, msg_len2, 2);
    mq_send(mqd, msg_ptr3, msg_len3, 3);

    printf("mq_send success\n");
    if (mq_close(mqd) != -1)
        printf("mq_close %s success\n", name);

    return 0;
}
```



# mq-receive.c

    mq_receive總是返回所指定佇列中最高優先順序的最早訊息，而且該優先順序能隨該訊息的內容及其長度一同返回。

    mq_receive的len引數的值不能小於能加到所指定隊裡中的訊息的最大大小(該佇列mq_attr結構的mq_msgsize成員)。
    要是len小於該值，mq_reveive就立即返回EMSGSIZE錯誤。
    這意味著使用Posix訊息佇列的大多數應用程式必須在開啟某個佇列後呼叫mq_getattr確定最大訊息大小，然後分配一個或多個那樣大小的讀緩衝區。

```c
// mq-receive.c
#include <fcntl.h>
#include <sys/stat.h>
#include <mqueue.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    char *name = "/temp.mq"; /* linux必須是/filename這種格式，不能出現二級目錄 */
    mqd_t mqd = mq_open(name, O_RDWR);
    if (mqd == -1) {
        perror("open failed");
        exit(EXIT_FAILURE);
    }
    printf("mq_open %s success\n", name);

    struct mq_attr attr;
    if (mq_getattr(mqd, &attr) == -1) {
        perror("mq_getattr failed");
        exit(EXIT_FAILURE);
    }

    char *msg_ptr;
    size_t msg_len = attr.mq_msgsize;
    unsigned msg_prio;
    msg_ptr = (char *)malloc(msg_len);

    while (1) {
        bzero(msg_ptr, msg_len);
        int res = mq_receive(mqd, msg_ptr, msg_len, &msg_prio);
        if (res != -1) {
            printf("msg is:%s, msg_prio:%d\n", msg_ptr, msg_prio);
        } else {
            perror("mq_receive failed");
            break;
        }
    }

    if (mq_close(mqd) != -1)
        printf("mq_close %s success\n", name);

    return 0;
}

```
