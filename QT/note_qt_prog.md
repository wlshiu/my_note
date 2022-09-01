# QT program [[Back](note_qt.md)]

Support **`c++ 11`**

## Qt Framework

![QT-Framework](Qt_Framework.jpg)

## Basic Console Application

```c++
// main.cpp
#include <QtCore>

class Task : public QObject
{
    Q_OBJECT
public:
    Task(QObject *parent = 0) : QObject(parent) {}

public slots:
    void run()
    {
        // Do processing here

        emit finished();
    }

signals:
    void finished();
};

/**
 *  '#include "main.moc"' is necessary
 *  if you define QObject subclasses with the Q_OBJECT macro in a .cpp file.
 */
#include "main.moc"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    /**
     *  Task parented to the application so that it
     *  will be deleted by the application.
     */
    Task *task = new Task(&a);

    /**
     *  This will cause the application to exit when
     *  the task signals finished.
     */
    QObject::connect(task, SIGNAL(finished()), &a, SLOT(quit()));

    /* This will run the task from the application event loop. */
    QTimer::singleShot(0, task, SLOT(run()));

    return a.exec();
}
```

## Basic GUI Application

```c++
#include <QApplication>     // 所有 Qt GUI 應用程序,都需要使用 <QApplication>
#include <QPushButton>      // 使用 push button

int main(int argc, char *argv[])
{
    QApplication    app(argc,argv);                             /* Create a app object */
    QPushButton     pushButton( QObject::tr("Hello Qt !") );    /* Create a button component of widget */

    pushButton.show();  /* display button (default: hide) */

    /* Connect icon (GUI component), event (signal), and method (slot) */
    QObject::connect(&pushButton, SIGNAL(clicked()), &app, SLOT(quit()));

    return app.exec();  /* enter app routine */
}
```

+ Widget module
    > Scenario of graphic components

    - Inheritance(繼承)

        ```
        QPushButton
            -> QButton
               -> QWidget
        ```

+ GUI module
    > Support all kinds of graphic components

+ Core module
    > Support system control API
    > + multi-thread
    > + event/message handshock
    > + state machine
    > + signal and slot
    > + I/O control
    > + Object Inheritance relation


## C++

### Syntax

+ `implicit` (隱性轉換)  and `explicit` (顯性轉換)
    > 出現在 constructor 前面

    - `implicit` conversion
        > compiler 自動轉換成某個 constructor interface

        ```c++
        class MyInteger
        {
        public:
            MyInteger(int n);
        }

        void main()
        {
            MyInteger   n1 = 5; // compiler 自動轉換成 n1(5)
        }
        ```

    - `explicit` conversion
        > 強制必須符合宣告的 interface
        >> 一般用在**避免 user 混淆而使用錯誤**, 甚至有強調的意味

        ```c++
        class MyInteger
        {
        public:
            explicit MyInteger(int n);
        }

        void main()
        {
            MyInteger   n2(5); // 強制語法必須符合
        }
        ```

### `MainWindow` class

Creaded from `QT Designer`

+ Call a component in MainWindow

    ```c++
    MainWindow::MainWindow(QWidget *parent)
      : QMainWindow(parent)
      , ui(new Ui::MainWindow)
    {
        ui->setupUi(this);    // ui is a instance
    }

    MainWindow::~MainWindow()
    {
        delete ui;
    }

    /**
     * objectName is from QT Designer
     * method definition: on_[objectName]_[slot name]()
     */
    void MainWindow::on_open_clicked()
    {
        QString     filePath = QFileDialog::getOpenFileName(this, tr("Open"),
                                                            QDir::homePath(),
                                                            tr("*.bin"));
        if( filePath.isEmpty() )
        return;

        /**
         * call the method of this 'lineEdit' object
         *    'lineEdit' is the objectName of a QLineEdit component
         */
        ui->lineEdit->setText(filePath);
    }
    ```

+ 移除 Widget
    - `delete [pointer_of_a_widget]` 會自動通知 **parent**, 並更新 list
        > 立及執行 delete, 有可能造成 crash

    - `deleteLater()`
        > 是 **QObject** 的一個 method, 並依賴於 QEvent loop 機制

        > + 如果在 EventLoop 啟用前被呼叫, 那麼 EventLoop 啟用後 Object 才會被銷毀
        > + 如果在 EventLoop 結束後被呼叫, 那麼 Object 不會被銷毀
        > + 如果在沒有 EventLoop 使用, 那麼 thread 結束後銷毀 Object.

        1. 可以多次呼叫此 method
        1. This method is thread-safe.


+ 抽離出 Widget
    > `setParent()` 會將此 widget object 從 parent object 剝離出來


+ Reference

    - [Qt Tutorials For Beginners - YouTube](https://www.youtube.com/watch?v=EkjaiDsiM-Q&list=PLS1QulWo1RIZiBcTr5urECberTITj7gjA)


### Multi-thread

+ [QThread](note_qthread.md)

+ [Synchronous](note_qt_thread_sync.md)

### Event

[Signals & Slots](note_qt_signals_slots.md)

### Timer

[Timer](note_qt_timer.md)

## QML

QML(Qt Meta-Object Language,Qt 元對象語言),是用於描述應用程序用戶界面的聲明式可編程語言, 高可讀性, 容易實現復用和自定義.

QML提供了類似JSON的聲明式語法, 提供了必要的**JavaScript**語句和動態屬性綁定的支持.

+ `QtQML` module
    > 定義並實現了QML Language 以及其引擎框架, 允許開發者以自定義類型和集成 `JavaScript` 與`C++`代碼的方式來擴展 QML 語言.

    - 將`QML code`, `JavaScript`和`C++`集成在一起, 既提供了 QML interface, 又提供了 C++ interface.
        > 可以很方便的使用 C++ 擴展 QML, e.g, C++數據模型, C++自定義功能類等,
        >> 其使用 C++ 以一定規則實現後, 並將 C++ class 註冊到 QML 引擎中, 便可以在 QML 中使用 C++ class 中的數據成員, 成員函數, 信號以及槽.

## Qt Linguist (多國語)

+ New language data

    - 在 QT project file `*.pro`, 最後加上

        ```makefile
        # demo.pro
        QT       += core gui

        greaterThan(QT_MAJOR_VERSION, 4): QT += widgets gui serialport

        CONFIG += c++11
        CONFIG(debug, debug|release) {
            CONFIG += console
        }

        ....

        TRANSLATIONS = lang_zh_tw.ts \
                       lang_cn_us.ts
        ```

    - Generate Translation Files (`*.ts`)
        > [Qt Creator] -> [Tools] -> [External] -> [Linguist] -> [Update Translations]

        1. Qt Creator log message

            ```log
            Starting external tool "C:\Qt\QT_5.14.2_static\bin\lupdate.exe C:\demo\demo.pro"
            Info: creating stash file C:\demo\.qmake.stash

            Updating 'lang_zh_tw.ts'...
                Found 115 source text(s) (0 new and 115 already existing)

            "C:\Qt\QT_5.14.2_static\bin\lupdate.exe" finished
            ```

+  `*.ts` Convert to `*.qm` file

    - Open tool `Linguist 5.14.2 (MinGW 7.3.0 32-bit)`
        > 編輯對應的名詞

        1. 程式中需要翻譯的字串需用 `tr()` 包裝
        1. 每個 item 編輯完, 需要點選 `Mark Item as done` (綠色勾勾), 來確定完成

    - Generate `*.qm`
        1. In `Linguist` tool
            > [File] -> [Release As]

        1. In Qt Creator
            > [Qt Creator] -> [Tools] -> [External] -> [Linguist] -> [Release Translations (lrelease)]

+ Load language dato in program

    - load `*.qm` in `main()`

        ```
        #include "mainwindow.h"

        #include <QApplication>

        #include <QTranslator>  // translator header

        int main(int argc, char *argv[])
        {
            QApplication a(argc, argv);

            //====================
            QTranslator translator;
            translator.load("lang_cn.qm");
            a.installTranslator(&translator);
            //====================

            MainWindow w;
            w.show();
            return a.exec();
        }
        ```
    - 如果載入不成功, 可能是路徑錯了
        > QtCreator 產生的 `.qm` 是在 `.pro` 目錄下, 需要移至 debug 目錄下, 才能正確讀取 `.qm`檔案


+ Reference
    - [Qt Linguist 介紹](https://blog.csdn.net/liang19890820/article/details/50274409)
    - [Qt附加工具--多語言國際化](https://cloud.tencent.com/developer/article/1655610)
        1. [Qt_Demo - github](https://github.com/ADeRoy/Qt_Demo.git)
    - [QT的多語言國際化](https://www.jianshu.com/p/71f738364410)
    - [Qt 國際化之二：多國語介面動態切換的實現](https://www.cnblogs.com/lvdongjie/p/4053008.html)
    - [QT開發（九）—— Qt實現應用內動態切換語言，使用Qt語言家編譯字體包](https://www.twblogs.net/a/5b7c57df2b71770a43da8906)


## Reference

+ [零基礎學 qt4 編程](https://wizardforcel.gitbooks.io/wudi-qt4/content/index.html)
+ [Qt參考文檔](https://documentation.help/Qt-3.0.5/index.html)
+ [QT All Classes (official)](https://doc.qt.io/qt-5.15/classes.html)
+ [QT All Modules (official)](https://doc.qt.io/qt-5/qtmodules.html)
