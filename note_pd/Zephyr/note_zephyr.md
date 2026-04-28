Zephyr RTOS
----


# Setup environment

> `z_setup_zephyr.sh`
> ```bash
> #!/bin/bash
>
> ZEPHYR_ROOT_DIR=$HOME/zephyrproject
>
> # Create the new virtual environment
> python3 -m venv ${ZEPHYR_ROOT_DIR}/.venv
>
> # Activate the virtual environment
> # use 'deactivate' to level python-venv
> source ${ZEPHYR_ROOT_DIR}/.venv/bin/activate
>
> pip install west
>
> west init ${ZEPHYR_ROOT_DIR}
>
> cd ${ZEPHYR_ROOT_DIR}
>
> west update
> west packages pip --install
> west zephyr-export
>
> ```

+ Create a new virtual environment of python

    ```
    $ python3 -m venv ~/zephyrproject/.venv
    $ source ~/zephyrproject/.venv/bin/activate
    ```

+ Install `west`

    ```
    $ pip install west
    $ west init ~/zephyrproject
    $ cd ~/zephyrproject
    $ west update                   # Get the Zephyr source code
    $ west packages pip --install

    # Export a Zephyr CMake package, 讓 CMake 可以自動載入建置 Zephyr 所需的樣板程式
    $ west zephyr-export
    ```

+ Install the Zephyr SDK (involve toolchain)

    ```
    $ west sdk install
    ```

+ build a example of Zephyr-SDK

    ```
    $ west build -b mps2/an521/cpu0/ samples/hello_world
    ```

    - Configure with kconfig

        ```
        $ west build -t menuconfig
        ```

+ Run with QEMU

    - Use `west`

        ```
        $ cd <ZEPHYR_ROOT_DIR>
        $ west build -p -b mps2/an521/cpu0/ns samples/tfm_integration/psa_crypto -t run
        ```

    - Use cmake and make

        ```
        $ cd <ZEPHYR_ROOT_DIR>/samples/tfm_integration/psa_crypto/
        $ rm -rf build
        $ mkdir build && cd build
        $ cmake -DBOARD=mps2/an521/cpu0/ns ..
        $ make run
        ```

# Reference

+ [Getting Started Guide — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/getting_started/index.html#install-the-zephyr-sdk)

+ [Zephyr On QEMU](https://docs.zephyrproject.org/latest/samples/tfm_integration/psa_crypto/README.html#on-qemu)





