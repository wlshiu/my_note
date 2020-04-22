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
