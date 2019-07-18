packet generate
---

# [socat](http://www.dest-unreach.org/socat/ )

+ install

    ```
    $ sudo apt-get install socat
    ```

+ basic express

    - `TCP:<host>:<port>` remote IP and port
    - `TCP-LISTEN:<port>` local port

    - `UDP:<host>:<port>` remote IP and port
    - `UDP-LISTEN:<port>` local port

    - `OPENSSL:<host>:<port>` remote IP and port
    - `OPENSSL-LISTEN:<port>` local port

+ send to remote

    ```
    # 產生廣播封包並送到 port: 9999
    $ echo "hello" | socat - UDP4-DATAGRAM:255.255.255.255:9999,broadcast
    ```

+ port mapping
    > 從外部連接到內部的一個 port

    ```
    外部:  socat tcp-listen:1234 tcp-listen:3389
    內部:  socat tcp:outerhost:1234 tcp:192.168.12.34:3389
    ```

+ transfer file

    ```
    # on host 1:
    $ socat -u open:myfile.exe,binary tcp-listen:999

    #on host 2:
    $ socat -u tcp:host1:999 open:myfile.exe,create,binary
    ```

    - 把文件myfile.exe用二進制的方式，從host 1 傳到host 2。

        1. `-u` 表示數據單向流動，從第一個參數到第二個參數
        1. `-U` 表示從第二個到第一個。文件傳完了，自動退出。

+ redirect

    - case 1

    ```
    $ socat TCP4-LISTEN:80,reuseaddr,fork TCP4:192.168.123.12:8080
    ```

        1. `TCP4-LISTEN`
            > 在本地建立的是一個TCP ipv4協議的監聽 port

        1. `reuseaddr`
            > 綁定本地一個 port；

        1. `fork`
            > 設定多鏈接模式，即當一個鏈接被建立後，自動複製一個同樣的 port 再進行監聽

    - socat 啟動監聽模式會在前端佔用一個shell，因此需使其在後台執行。

        ```
        $ socat -d -d tcp4-listen:8900,reuseaddr,fork tcp4:10.5.5.10:3389
            or
        $ socat -d -d -lf /var/log/socat.log TCP4-LISTEN:15000,reuseaddr,fork,su=nobody TCP4:static.5iops.com:15000
        ```

        1. `-d -d -lf /var/log/socat.log`
            > 前面兩個連續的 `-d -d` 代表調試信息的輸出級別，`-lf` 則指定輸出信息的保存文件。

            > `TCP4-LISTEN:15000,reuseaddr,fork,su=nobody` 是一號地址，代表在 15000 port 上進行 TCPv4 的監聽，復用綁定的IP，
            每次有連接到來就 fork 複製一個進程進行處理，同時將執行用戶設置為 nobody 用戶。

            > `TCP4:static.5iops.com:15000` 是二號地址，代表將 socat 監聽到的任何請求，轉發到 static.5iops.com:15000 上去。
