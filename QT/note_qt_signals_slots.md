# Qt Signals & Slots [[Back](note_qt_prog.md#Event)]

`QObject` 提供了 **Signals & Slots** 機制, 並藉由 `connect()` 來連接 **Signal (Event)** 和 **Slot (Action)**
> `QObject` 是所有 Qt Classes 的 base class (祖先)

Signals 是由 Object 主動發送, 而 Slots 則是被動接收, 而一個 Signal 可以藉由 `QObject::connect()` 連接多個 Slots


## connect()/disconnect() method

```c++
QObject:connect(const QObject *sender, const QMetaMethod &signal,
        const QObject *receiver, const QMetaMethod &method,
        Qt::ConnectionType type = Qt::AutoConnection);

QObject::disconnect(const QObject *sender, const QMetaMethod &signal,
                    const QObject *receiver, const QMetaMethod &method);

// extended after Qt 5
QObject::connect(const QObject *sender, const char *signal,
                 const QObject *receiver, const char *method,
                 Qt::ConnectionType type = Qt::AutoConnection);

bool disconnect(const QObject *sender, const char *signal,
                const QObject *receiver, const char *method);
```


Qt::ConnectionType
> + Qt::AutoConnection
>> default type, 如果 Signal sender/receiver 在同一個 thread, 則使用 `Qt::DirectConnection`, 否則使用 `Qt::QueuedConnection` (在 `emit` 時決定).

> + Qt::DirectConnection
>> Signal 所連線至的 Slots methods 將會被立即執行, 並且是在發射訊號的 thread.
若 Slot methods 是耗時操作, 當 Signal 由 UI thread emit, 則會 blocking Qt event loop, UI就會進入無響應狀態.

> + Qt::QueuedConnection
>> Slot methods 將會在 receiver 的 thread 被執行. <br>
當 Signal 被多次 emit, 則對應的 Slot methods 會在 receiver 的 thread 裡, 順序執行對應次數.
當使用 QueuedConnection 時, 參數型別必須是 Qt 基本型別, 或者使用 qRegisterMetaType() 進行註冊了的自定義型別。

> + Qt::BlockingQueuedConnection
>> 和 QueuedConnection 類似, 區別在於 Signal sender 的 thread 會被 blocking, 直到 Slot methods 執行完畢.
sender/receiver 必須在不同的 thread, 否則會導致 deadlock.

> + Qt::UniqueConnection
>> 執行方式與 AutoConnection 相同, 不過只能單一連結. <br>
如果相同兩個物件, 相同的 Signal 關聯到相同的 Slot, 那麼第二次 connect 將失敗


+ Tradition

    ```c++
    QObject::connect(frontend, SIGNAL(press-button), backend, SLOT(handle_action));
    ```

    - Example

        ```
        class foo : public QObject
        {
            Q_OBJECT    // use Signal & Slot

        public:
            foo(QObject *parent = nullptr);
            ~foo();

        signals:
            void clickedStart(const Block &block);
            void clickedStop();

        public slots:
            void stopProcess();

        private slots:
            void startrProcess(const Block &block);

        private:
            ...
        };

        connect(ui.btnStart, SIGNAL(clickedStart(const Block &)), this, SLOT(startrProcess(const Block &)));
        connect(ui.btnStop, SIGNAL(clickedStop()), this, SLOT(stopProcess()));
        ```

        1. Class 中的 **`signals:`** 是 Qt 特別定義的 tag, 用來表示後面定義的 methods 都是 Signals
            > 此類 methods **不用實作**, 只要定義 `method name` 和所需 `paraments` 即可 (類似 Event 宣告),
            而這些 Signals 可以透過 **`emit`** 這個 keyword 發射

            ```
            emit clickedStart(myBlock);
            ```

        1. Class 中的 `public slots:` 及 `private slots` 也是 Qt 特別定義的 tag, 用來表示後面定義的 method, 都是用來接收 Signals 的 Slots
            > 此類 methods 是實際接收到 Signals 後, 執行相對應的行為, 因此需要 instance (函數實體)
            >> 也可以當一般 method (手動 call funcion)

        1. 使用 `SIGNAL()` 與 `SLOT()` 來對參數做型別檢查
            > signal 和 slot 的參數型別必須一致, 否則會連接無效


+ After Qt 5

    ```
    connect(frontend, signal_func_pointer, backend, handle_func_pointer);
    ```

    - Example

        ```
        class foo : public QObject
        {
            Q_OBJECT    // use Signal & Slot

        public:
            foo(QObject *parent = nullptr);
            ~foo();

            void stopProcess();

        signals:
            void clickedStart(const Block &block);
            void clickedStop();

        private:
            void startrProcess(const Block &block);
            ...
        };

        connect(ui.btnStart, &foo::clickedStart, this, &foo::startrProcess));
        connect(ui.btnStop, &foo::clickedStop, this, &foo::stopProcess);
        ```

        1. Signal 和 Slot 的 methods **不做參數型別檢查 (兩者參數可以不一致)**
        1. Slot 的 methods 不需要 `public slots:` or `private slots:`

    - Issue

        1. Signal & Slot 不匹配

            ```
            error: no matching member function for call to 'connect'  connect(m_pBtn, &MyButton::clickedStart, this, &Widget::onClicked);
            ```

            > 當 Object 中存在 Signal or Slot 的 overload (多型或重載)時, 只用 function pointer 無法識別是要連接到哪一個 overload, 因此需要強制轉型

            ```
            connect(ui.btnStart, static_cast<void (MyButton::*)(bool)>(&MyButton::clickedStart), this, &Widget::onClicked);
            ```

+ Lambda Expression (`>= c++11`)

    ```c++
    // overload Widget::onClicked() with Lambda Expression
    connect(ui.btnStart, static_cast<void (MyButton::*)(bool)>(&MyButton::clickedStart),
            this, [=](bool check) {
                //do something
            });
    ```



## Referenct

+ [Qt connect函數的幾種用法](https://www.twblogs.net/a/5caca974bd9eee2dd0f29783)
+ [一步一步學習Qt開發（五）：「信號/槽」(Signals & Slots) 的用法](https://kknews.cc/zh-tw/education/z3yk3qg.html)
+ [Qt 之connect 信號和槽函數連接的幾種方法的總結(含signalmaper, lamda方式)](https://www.twblogs.net/a/5d7dc877bd9eee5327ffab54)

