Python
---

[Download](https://www.python.org/downloads/)


# MSYS2

+ Environment

```
$ vim ~/.bashrc
    ...
    Python27=/C/Python27
    PATH="$Python27:$PATH"
```

# libraries

+ numpy
    ```
    $ python -m pip install -U pip numpy
    ```

    - test

    ```
    $ vi ./test_numpy.sh
        #!/usr/bin/env python

        import numpy as np

        x = np.array([1, 2, 3])
        print(x)

        y = np.arange(10)
        print(y)

    $ ./test_numpy.sh
    ```

+ graph

    ```
    $ python -m pip install -U pip setuptools
    $ python -m pip install matplotlib

    # read image file, e.g jpeg, bmp, tiff
    $ python -m pip install pillow
    ```

+ networkx

    ```
    $ python -m pip install networkx
    ```

+ pandas

    ```
    $ python -m pip install pandas
    ```

+ virtualenv

    - install

        ```
        $ pip install virtualenv
            or
        $ sudo apt-get install python3-venv
        ```

    - create virtual environment

        ```
        $ python -m venv test-env
        (test-env) $
        ```

    - 建立虛擬環境並指定 Python 版本
        > 必須先安裝好不同版本的 python

        ```
        $ virtualenv test-env --python=python3.8
        ```

    - 啟動虛擬環境

        ```
        $ source  test-env/bin/activate
        ```

+ distutils

    ```
    $ sudo apt-get install pythonX.Y-distutils
    ```

# configure

+ Python 3.7

    ```
    # add the deadsnakes PPA to sources list
    $ sudo add-apt-repository ppa:deadsnakes/ppa
    $ sudo apt install python3.7

    ```

    1. swithc python3 version

        ```
        $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
        $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
        $ sudo update-alternatives --config python3
            There are 2 choices for the alternative python3 (providing /usr/bin/python3).

              Selection    Path                Priority   Status
            ------------------------------------------------------------
            * 0            /usr/bin/python3.6   2         auto mode
              1            /usr/bin/python3.6   1         manual mode
              2            /usr/bin/python3.7   2         manual mode

            Press <enter> to keep the current choice[*], or type selection number:

        $ sudo rm /usr/bin/python3
        $ sudo ln -s python3.7 /usr/bin/python3
        ```

+ 設置 Python 3 為默認 Python 版本

    ```
    $ sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && alias pip=pip3
    ```


