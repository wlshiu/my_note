# Timer [[Back](note_qt_prog.md#Timer)]

Qt中 Timer 的使用有兩種方法
> + 一種是使用`QObject` 提供的 timer
> + 還有一種就是使用`QTimer`
>> 簡單易用, 但是比較耗記憶體, 所以在不必要的時候就須終止它

+ Accuracy (精準度) and Timer Resolution
    > timer 的精準度取決於 OS 和硬體. 絕大多數平臺支援精度為 `1 ms`, 儘管 timer 的準確性在許多現實世界的情況下和這不相符.

    > 準確性也取決於 timer 型別(Qt::TimerType)
    > + 對於`Qt::PreciseTimer`來說, QTimer 將試圖保持精確度在 1ms. 精確的 timer 也不會比預計的還要早 timeout (只會慢不會提早)
    > + 對於`Qt::CoarseTimer`和`Qt::VeryCoarseTimer`型別, QTimer **可能早於預期**,
    >> 在間隔之內被喚醒： `Qt::CoarseTimer`為間隔的 `5%`, `Qt::VeryCoarseTimer`為 `500ms`

    | Qt::TimerType       | value  | description                                  |
    | :-                  | :-:    | :-                                           |
    | Qt::PreciseTimer    |  0     | 精確的 Timer, 儘量保持 msecond 精度             |
    | Qt::CoarseTimer     |  1     | 粗略的 Timer, 儘量保持精度在所需的時間間隔 5% 範圍內 |
    | Qt::VeryCoarseTimer |  2     | 很粗略的 Timer, 只保留完整的第二精度             |

## QObject Timer

```c++
/* at mytimer.h */
#define _MYTIMER_H

#include <QObject>

class MyTimer : public QObject
{
    Q_OBJECT

public:

    MyTimer(QObject* parent = NULL);
    ~MyTimer();

    void  handleTimeout();      // Timeout handler
    virtual void timerEvent(QTimerEvent *event);

private:
    int     m_nTimerID;
};

#endif //_MYTIMER_H
```

```c++
/* At mainwindow.cpp */

#include "mytimer.h"

#include<QDebug>
#include <QTimerEvent>

#define TIMER_TIMEOUT_MS   (5*1000)

MyTimer::MyTimer(QObject *parent)
    :QObject(parent)
{
    m_nTimerID = this->startTimer(TIMER_TIMEOUT_MS);
}

MyTimer::~MyTimer()
{

}

void MyTimer::timerEvent(QTimerEvent *event)
{
    if(event->timerId() == m_nTimerID)
    {
        handleTimeout();
    }
}

void MyTimer::handleTimeout()
{
    qDebug()<<"Enter timeout processing function\n";
    killTimer(m_nTimerID);
}
```

+ `int QObject::startTimer(int interval, Qt::TimerType timerType = Qt::CoarseTimer)`
    > 開啟一個 Timer, 其的參數 interval 是 msecond 級別.
    當開啟成功後會 return 這個 Timer 的 ID, 並且每隔 interval 時間後, 進入 `timerEvent()`

+ `void QObject::timerEvent(QTimerEvent *event)`
    > Timer timerout 後, 會進入該事件 timerEvent(), 需要 overriding timerEvent(),
    >> 在函式中通過判斷 `event->timerId()` 來確定 Timer, 然後再執行某個 timerout handler

+ `void QObject::killTimer(int id)`
    > 從 startTimer 返回的 ID 傳入 killTimer() 中, 來結束 timer 進入 timerout 處理。


## QTimer

QTimer 提供了重複和單次觸發訊號的 timer , 同時也提供了一個高級別的程式設計介面.
> 很容易使用:
> 1. 建立一個 QTimer
> 1. 連接 timeout() Signal 到適當的 Slot function
> 1. 並呼叫 start(), 然後在定義的時間間隔會發射 timeout() Signal.


```C++
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTimer>
#include <QDebug>
#include <QDateEdit>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

public slots:
    void handleTimeout();  //超時處理函式

private:
    Ui::MainWindow *ui;
    QTimer *timer;
};
#endif // MAINWINDOW_H
```

```C++
#include "mainwindow.h"
#include "ui_mainwindow.h"

#define TIMER_TIMEOUT_MS    (5*1000)

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    timer = new QTimer(this);

    connect(timer, SIGNAL(timeout()), this, SLOT(handleTimeout()));

    timer->start(TIMER_TIMEOUT_MS);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::handleTimeout()
{
    qDebug() << "Enter timeout processing function\n";

    if( timer->isActive() )
    {
        timer->stop();
    }

    qDebug() << ui->dateEdit->date();
}

```

### Methods

+ `void QTimer::setTimerType(Qt::TimerType atype)`
    > 設定 Timer 的精準度
    >> 預設值是`Qt::CoarseTimer`

+ `bool QTimer::isActive() const`
    > 如果 timer 正在執行, 返回 true, 否則返回 false


+ `int QTimer::remainingTime() const`
    > 返回 timer 的剩餘時間(msecond 為單位), 直到 timeout.
    > + 如果 timer 未執行, 返回值是 `-1`.
    > + 如果 timer 已經 timeout, 返回值為 `0`

+ `void QTimer::setInterval(int msec)`
    > 設定 timeout 間隔 (msecond 為單位)
    >> 預設值是 0, 一旦視窗系統事件佇列中的所有事件都已經被處理完, 一個時間間隔為 0 的 QTimer 就會觸發.

+ `void QTimer::setSingleShot(bool singleShot)`
    > 設定 timer 是否為單次觸發.
    >> 單次觸發 timer 只觸發一次, 非單次的話, 則每過一個時間間隔都會觸發.


+ `int QTimer::timerId() const`
    > 如果 timer 正在執行, 返回 timer 的ID, 否則返回 `-1`

+ `void QTimer::start(int timeout_msec)` or `void QTimer::start()`
    > 啟動或重新啟動一個timer <br>
    如果 timer 正在執行, 則 timer 將被停止並重新啟動.
    >> 如果 `singleShot` 為 true, timer 將只啟用一次.

+ `void QTimer::stop()`
    > 停止 timer

# Prograss Bar

```c++
/* at mainwindow.h */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTimer>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();


public slots:
    void updateProcessBar();  // timerout trigger of a timer. ps. it MUST be at 'slots' tag

private slots:
    void on_btnStart_clicked();
    void on_btnStop_clicked();

private:
    Ui::MainWindow *ui;
    QTimer  *m_timer;
    int     progress_value;
};
#endif // MAINWINDOW_H
```

```c++
/* at mainwindow.cpp */

#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QTimer>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->progressBar->setValue(0);

    m_timer = new QTimer(this);

    ui->progressBar->setRange(0, 999);
    ui->progressBar->setValue(0);

    connect(ui->btnStart, SIGNAL(clicked()), this, SLOT(on_btnStart_clicked()));
    connect(ui->btnStop, SIGNAL(clicked()), this, SLOT(on_btnStop_clicked()));

    connect(m_timer, SIGNAL(timeout()), this, SLOT(updateProcessBar()));

    progress_value = 0;
}

MainWindow::~MainWindow()
{
    delete m_timer;
    delete ui;
}

void MainWindow::updateProcessBar()
{
    if( progress_value == 1000 )
    {
        m_timer->stop();
        return;
    }

    ui->progressBar->setValue(progress_value++);
}


void MainWindow::on_btnStart_clicked()
{
    m_timer->start(10); // 100 ms
    progress_value = 0;
}

void MainWindow::on_btnStop_clicked()
{
    m_timer->stop();
}

```

# Reference

+ [Qt QTimer timer ](https://iter01.com/567622.html)
+ [Qt 之 QTimer](https://www.itread01.com/content/1547841453.html)
+ [Qt5.9進度條QProgressBar用法詳解](https://www.twblogs.net/a/5f04803f6acbc4367a2549ee)
+ [Qt進度條QProgressBar的使用](https://www.itread01.com/content/1547088980.html)
+ [Qt 彈出界面](http://www.morecpp.cn/qt-popup-widget)
+ [Qt Creator 新增UI文件](https://blog.51cto.com/u_15127616/3464217)
