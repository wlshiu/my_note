# QThread [[Back](note_qt_prog.md#Multi-thread)]

早期 QT (< Qt v4.4) 只能使用 `QThread` 來建立 multi-thread, 但後來完善了 `Signal &　Slot`機制後,
`QThread` 除了友善化 interface 外, 更進一步提升到 **Thread Management** 層級

Official description
> The QThread class provides a platform-independent way to manage threads.


+ QThread object 主要用來管理 thread, 本身不等同於 thread_routine

    ```
    class Server: public QThread
    {
        Q_OBJECT

    public:
        Server(QObject* parent = 0): QThread(parent)
        {
            //moveToThread(this);
        }

    public slots:
        void recv_handle()
        {
            qDebug() << "from Server recv_handle():" << currentThreadId();
        }

    protected:
        void run()
        {
            qDebug() << "Server run():" << currentThreadId();
            exec();
        }
    };

    void thread_routine_A()
    {
        Server      srv;

        srv.start();
        ...
    }
    ```

    - Server object 中的所有 members 都會在 Constructor 所在的 thread
        > 產生在被宣告的 thread (thread_routine_A) 中

    - Server::run() 則會被放到新建立的 thread_routine 中
        > 相當於 `pthread_create(&th, 0, Server::run(), 0);`


## Methods

+ QPthread::run()
    > the routine of a thread, 離開 run() 即表示離開開 thread routine

+ QPthread::exec()
    > 啟動 thread 內部的 Event Loop (Signals & Slots), 必須在 run() 內呼叫

+ QThread::wait()
    > 相當於 pthread_join(),
    >> 通常會考慮發出 Signal finished() 來取代 wait()

+ QThread::isFinished() 和 QThread::isRunning()
    > Get thread status

+ QThread::exit() 或 QThread::quit()
    > leave thread

+ QThread *QThread::currentThread()
    > Returns a pointer to a QThread which manages the currently executing thread.

+ Qt::HANDLE QThread::currentThreadId()
    > Returns the thread handle of the currently executing thread.

+ QThread::sleep(), QThread::msleep(), QThread::usleep()
    > 通常會考慮使用 QTimer 來取代 sleep, 以提升效率

+ QThread::yieldCurrentThread()
    > 強制 context switch 到別的 thread

+ Slots

    - QThread::start(QThread::Priority priority = InheritPriority)
        > 相當於 pthread_create()

    - QThread::quit()

+ Signals

    - QThread::finished()
        > Signal finished() 連接到 Slot QObject::deleteLater()
        >> After Qt 4.8

    - QThread::started()


+ QThread::setPriority(QThread::Priority priority)
    > 設定優先權

+ enum Qthread::Priority

    | enumeration                     | value | description |
    | :-                              | :-:   | :-         |
    | QThread::IdlePriority           | 0     | 沒有其他 thread 執行時才進行排程 |
    | QThread::LowestPriority         | 1     | 不比 LowPriority 排程頻繁       |
    | QThread::LowPriority            | 2     | 不比 NormalPriority 排程頻繁    |
    | QThread::NormalPriority         | 3     | 作業系統的預設優先順序           |
    | QThread::HighPriority           | 4     | 比 NormalPriority 排程頻繁      |
    | QThread::HighestPriority        | 5     | 比 HighPriority 排程頻繁       |
    | QThread::TimeCriticalPriority   | 6     | 儘可能頻繁的進行排程            |
    | QThread::InheritPriority        | 7     | 使用和建立自己的 thread 同樣的優先順序，這是預設屬性 |


## 分析

### 建議用法 (Recommend from Bradley T. Hughes)

配合 Qt Event Loop framework, 不需 Mutex 來進行同步

```c++
#include <QtCore/QCoreApplication>
#include <QtCore/QObject>
#include <QtCore/QThread>
#include <QtCore/QDebug>

class Client: public QObject
{
    Q_OBJECT

public:
    Client(QObject* parent = 0): QObject(parent) {}

signals:
    void send_event();

public:
    void emit_send_data()
    {
        emit send_event();
    }
};

class ServerImpl: public QObject
{
    Q_OBJECT

public:
    ServerImpl() {}

public slots:
    void recv_handle()
    {
        qDebug() << "from ServerImpl recv_handle():" << QThread::currentThreadId();
    }
};


int main(int argc, char *argv[])
{
    QCoreApplication    a(argc, argv);
    qDebug() << "main thread:" << QThread::currentThreadId();

    QThread         server_rx;  // 建立一個 QThread 來管理 server_rx
    ServerImpl      srv_impl;   // server 實際的行為
    Client          clnt;

    srv_impl.moveToThread(&server_rx);  // attach srv_impl instance to server_rx thread
    QObject::connect(&clnt, SIGNAL(send_event()), &srv_impl, SLOT(recv_handle()));

    server_rx.start();      // create server_rx thread
    clnt.emit_send_data();  // client trigger event

    return a.exec();
}

/**
 *  Output result:
 *      main thread: 0x1a5c
 *      from ServerImpl recv_handle(): 0x186c
 */
```

### 多數用法 (No recommend)

+ 從 Thread_A 發 signal 給 Thread_B, 對應的 Slot 卻在 Thread_A
    > 因為 thread_routine 和 Slot 在不同 threads, 需要使用 Mutex 來同步

    ```c++
    class Client: public QObject
    {
        Q_OBJECT
    public:
        Client() {}

    signals:
        void send_event();

    public:
        void emit_send_data()
        {
            emit send_event();
        }
    };

    class ServerRx: public QThread
    {
        Q_OBJECT

    public:
        ServerRx(QObject* parent = 0): QThread(parent)
        {
            /**
             *  moveToThread() 將 the instance of a Object 移到目前的 QThread.
             *      雖然可以避免使用 Mutex, 但操作起來不是很直覺
             */
            // moveToThread(this);
        }

    public slots:
        void recv_handle()
        {
            qDebug() << "from ServerRx recv_handle():" << currentThreadId();
        }

    protected:
        void run()
        {
            qDebug() << "ServerRx run():" << currentThreadId();
            exec();
        }
    };

    int main(int argc, char *argv[])
    {
        QCoreApplication    a(argc, argv);
        qDebug() << "main thread:" << QThread::currentThreadId();

        ServerRx        srv_rx; // construct Slot
        Client          clnt;

        QObject::connect(&clnt, SIGNAL(send_event()), &srv_rx, SLOT(recv_handle()));

        srv_rx.start();     // phtread_create(&t1, 0, ServerRx::run(), 0);
        clnt.emit_send_data();

        return a.exec();
    }

    /**
     *  Outupt result:
     *      main thread: 0x1a40,
     *      from ServerRx recv_handle(): 0x1a40,  # case of Ignore 'moveToThread()'
     *      ServerRx run(): 0x1a48
     */
    ```

+ 從 Thread_B 發 signal 給 Thread_B, 對應的 Slot 卻在 Thread_A
    > 因為 thread_routine 和 Slot 在不同 threads, 需要使用 Mutex 來同步

    ```c++
    class Client: public QObject
    {
        Q_OBJECT

    public:
        Client(QObject* parent = 0): QObject(parent) {}

    signals:
        void send_event();

    public:
        void emit_send_data()
        {
            emit send_event();
        }
    };

    class ServerRx: public QThread
    {
        Q_OBJECT

    public:
        ServerRx(QObject* parent = 0): QThread(parent)
        {
            /**
             *  moveToThread() 將 the instance of a Object 移到目前的 QThread.
             *      雖然可以避免使用 Mutex, 但操作起來不是很直覺
             */
            // moveToThread(this);
        }

    public slots:
        void recv_handle()
        {
            qDebug() << "from ServerRx recv_handle():" << currentThreadId();
        }

    protected:
        void run()
        {
            qDebug() << "ServerRx run():" << currentThreadId();

            Client   clnt;
            connect(&clnt, SIGNAL(send_event()), this, SLOT(recv_handle()));
            clnt.emit_send_data();

            exec();
        }
    };

    int main(int argc, char *argv[])
    {
        QCoreApplication    a(argc, argv);
        qDebug() << "main thread:" << QThread::currentThreadId();

        ServerRx      srv_rx;   // construct Slot
        srv_rx.start();         // phtread_create(&t1, 0, ServerRx::run(), 0);

        return a.exec();
    }

    /**
     *  Outupt result:
     *      main thread: 0x15c0
     *      ServerRx run(): 0x1750
     *      from ServerRx recv_handle(): 0x15c0
     */
    ```

## Reference

+ [QThread Class (Official)](https://doc.qt.io/qt-5/qthread.html)
+ [QThread使用——關於run和movetoThread的區別](https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/615721/)
+ [*Qt - 一文理解QThread多執行緒(萬字剖析整理)](https://www.gushiciku.cn/pl/pDpV/zh-tw)
