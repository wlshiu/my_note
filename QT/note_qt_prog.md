# QT program [[Back](note_qt.md)]

## Qt Framework

![QT-Framework](Qt_Framework.jpg)

## Basic Application

```
#include <QApplication>     // 所有 Qt GUI 應用程序,都需要使用 <QApplication>
#include <QPushButton>      // 使用 push button

int main(int argc, char *argv[])
{
    QApplication    app(argc,argv);                             /* Create a app object */
    QPushButton     pushButton( QObject::tr("Hello Qt !") );    /* Create a button component of widget */

    pushButton.show();  /* display button (default: hide) */

    /* Connect icon (GUI component), event (signal), and method (slot) */
    QObject::connect(&pushButton, SIGNAL(clicked()), &app.SLOT(quit()));

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

## Reference

+ [零基礎學 qt4 編程](https://wizardforcel.gitbooks.io/wudi-qt4/content/index.html)
+ [Qt參考文檔](https://documentation.help/Qt-3.0.5/index.html)
+ [QT All Classes (official)](https://doc.qt.io/qt-5.15/classes.html)
+ [QT All Modules (official)](https://doc.qt.io/qt-5/qtmodules.html)
