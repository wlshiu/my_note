[amazon-freertos](https://github.com/aws/amazon-freertos)
---

# ubuntu

```
$ sudo apt-get install git wget libncurses-dev flex bison gperf python python-pip python-setuptools python-serial python-cryptography python-future python-pyparsing cmake ninja-build ccache
```

+ **CMake 3.13 or higher is required**

    ```
    $ sudo apt purge --auto-remove cmake
    $ wget https://github.com/Kitware/CMake/releases/download/v3.15.2/cmake-3.15.2.tar.gz
    $ tar -zxvf cmake-3.15.2.tar.gz
    $ cd cmake-3.15.2
    $ ./bootstrap
    $ make
    $ sudo make install
    $ cmake --version
    ```

## setup

**重開新的 teminal, 避免跟 Espressif offical esp-idf 環境設定衝突***

+ toolchain
    > [xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0](https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz)

    ```
    $ echo 'export -n IDF_PATH' > setup_asw_freertos.env
    $ echo 'xtensa_toolchain=$HOME/.espressif/tools/xtensa-esp32-elf/esp-2020r3-8.4.0/xtensa-esp32-elf/bin/' >> setup_asw_freertos.env
    $ echo 'export PATH=${xtensa_toolchain}:$HOME/bin:$HOME/.local/bin:$HOME/.local/usr/bin:$HOME/.vim/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/        bin:/sbin:/bin:/snap/bin' >> setup_asw_freertos.env
    $ echo 'export AFR_TOOLCHAIN_PATH=${xtensa_toolchain}' >> setup_asw_freertos.env
    $ echo 'export IDF_PYTHON_ENV_PATH=~/.espressif/python_env/' >> setup_asw_freertos.env
    $ source setup_asw_freertos.env
    $ xtensa-esp32-elf-gcc --version
    ```

+ serial port

    - [CP210x USB](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers)
    - [FTDI virtual COM](https://www.ftdichip.com/Drivers/VCP.htm)

    - reference
        1. [建立與 ESP32 的序列連線](https://docs.espressif.com/projects/esp-idf/en/latest/get-started/establish-serial-connection.html)


+ AWS CLI
    > AWS Command Line Interface (AWS CLI) 是開放原始碼工具, 可讓您在命令列 shell 中使用命令來與 AWS 服務互動.
    只需最少的組態, AWS CLI 您就可以從終端機程式的命令提示字元, 開始執行可實作相當於瀏覽器型 AWS 管理主控台所提供功能的命令

    ```
    $ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        or
    $ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"

    $ unzip awscliv2.zip
    $ sudo ./aws/install
    $ aws --version
        aws-cli/2.1.1 Python/3.7.4 Linux/4.14.133-113.105.amzn2.x86_64 botocore/2.0.0
    ```

    - Configure AWS CLI
        > + `Access Key pair` is the key pair when create `IAM` user
        > + `Region` AWS server 區域, `us-west-2` 使用美國西部 (奧勒岡)

        ```
        $ aws configure
            AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
            AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
            Default region name [None]: us-west-2
            Default output format [None]: json
        ```

    - reference
        1. [安裝、更新和卸載 AWS CLI 第 2 版 在Linux上](https://docs.aws.amazon.com/zh_tw/cli/latest/userguide/install-cliv2-linux.html)

+ AWS 開發套件 (python)

    ```
    $ pip install tornado nose --user
    $ pip install boto3 --user
    ```

+ source code

    ```
    $ mkdir -p $HOME/AWS && cd $HOME/AWS
    $ git clone https://github.com/aws/amazon-freertos.git --recurse-submodules
    $ $HOME/AWS/amazon-freertos/vendors/espressif/esp-idf/install.sh
    ```

    - Configure FreeRTOS for AWS IoT

        ```
        $ cd amazon-freertos/tools/aws_config_quick_start
        $ vi amazon-freertos/tools/aws_config_quick_start/configure.json
            "afr_source_dir":"/home/<username>/AWS/amazon-freertos",  # '$HOME' 不認得
            "thing_name":"my_esp32_thing",
            "wifi_ssid":"my_ssid_name",
            "wifi_password":"my_ssid_password",
            "wifi_security":"one_of_valid_values"

        $ python SetupAWS.py setup
            Creating a Thing in AWS IoT Core.
            Acquiring a certificate and private key from AWS IoT Core.
            Writing certificate ID to: demo_aws_freertos_cert_id_file
            Writing certificate PEM to: demo_aws_freertos_cert_pem_file
            Writing private key PEM to: demo_aws_freertos_private_key_pem_file
            Creating a policy on AWS IoT Core.
            Completed prereq operation!
            Updated aws_clientcredential.h
            Updated aws_clientcredential_keys.h
            Completed update operation!
        ```

    - build

        ```
        $ cd $HOME/AWS/amazon-freertos
        $ source ./vendors/espressif/esp-idf/export.sh  # configure esp-idf environment 
        $ cmake -DVENDOR=espressif -DBOARD=esp32_devkitc -DCOMPILER=xtensa-esp32 -S . -B ./build
        $ cd build && make

        # burn to esp32-devkitc
        $ idf.py erase_flash flash monitor -p /dev/ttyUSB0 -B build
        ```

    - reference
        1. [Getting Started with Amazon FreeRTOS and the Espressif ESP32-DevKitC](https://blog.alikhalil.tech/2019/06/getting-started-with-amazon-freertos-and-the-espressif-esp32-devkitc/)

# Reference
+ [Espressif ESP32-DevKitC 和 ESP-WROVER-KIT 入門](https://docs.aws.amazon.com/zh_tw/freertos/latest/userguide/getting_started_espressif.html)

