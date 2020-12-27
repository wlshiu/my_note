Ubuntu dpkg
---

+ list install
    ```
    $ dpkg -l | grep [name]
    ```

+ remove lib
    ```
    $ sudo apt-get autoremove --purge [lib name]
    ```

+ zip

    ```
    $ zip -re filename.zip filename
    ```

+ 解壓 deb file

    ```
    $ dpkg -x xxx.deb <target dir>
    ```

