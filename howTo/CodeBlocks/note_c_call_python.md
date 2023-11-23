C call Python
---

# Setup Environment

+ install python core
    > [Python Releases for Windows](https://www.python.org/downloads/windows/)

    - [Python FTP](https://www.python.org/ftp/python/)

+ Code::Blocks

    - [Environment] -> [Environment Variables]
        > Add new variables
        > + `PYTHONPATH`: `C:\Python38-32\DLLs;C:\Python38-32\Lib;C:\Python38-32\Lib\site-packages`
        > + `PYTHONHOME`: `.\`


    - [Linker Setting] -> [Link libraries]
        > Add `...\Python38-32\libs\python38.lib`

    - [Search directories]

        1. Compiler
            > Add `...\Python38-32\include`

        1. Linker
            > + Add `...\Python38-32\DLLs`
            > + Add `...\Python38-32\libs`

    - Put `python38.dll` to the directory of compiled exe file


# Reference

+ [C++呼叫Python（傻瓜式教學）\_c++呼叫python指令碼-CSDN部落格](https://blog.csdn.net/qq_37955704/article/details/126577950)



