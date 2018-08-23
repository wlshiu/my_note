Gerrit
---

+ user name/email
    ```
    git config --global user.name "username"
    git config --global user.email "username@gmail.com"
    ```


+ ssh key
    ```
    $ssh-keygen -t rsa
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/someone/.ssh/id_rsa):   <- 注意會不會蓋掉你原來的檔案
    Created directory '/home/someone/.ssh'.
    Enter passphrase (empty for no passphrase):                        <- 直接按Enter不要設密碼
    Enter same passphrase again:
    Your identification has been saved in /home/someone/.ssh/id_rsa.
    Your public key has been saved in /home/someone/.ssh/id_rsa.pub.
    The key fingerprint is:
    d2:c4:23:d4:1e:a1:0c:e6:17:2a:5d:09:0c:bc:15:0e someone@david-ubuntu
    The key's randomart image is:
    +--[ RSA 2048]----+
    | .Eo=o+o..       |
    |  .*o*.+o        |
    |  .o= =.+.       |
    |  .. . +..       |
    |      . S        |
    |       .         |
    |                 |
    |                 |
    |                 |
    +-----------------+
    ```

+ Gerrit server
    > 請上 Gerrit server 用自己帳號的帳戶登入，然後按右上角的settings選左邊的SSH Public Keys，增加一組你的key設定。 </br>
    > ps. 把你的~/.ssh/id_rsa.pub裡面的東西拷過去，注意，最後不可以有換行!


+
    ```
    Host [Gerrit_server_URI]
    User [your name]                    (改成你在Profile看到的username)
    IdentityFile ~/.ssh/id_rsa          (指到你的private key)
    ```

+ connection

    ```
    $ ssh -p 1088 Gerrit.com
    ****    Welcome to Gerrit Code Review    ****
    Hi Guan XXX, you have successfully connected over SSH.
    Unfortunately, interactive shells are disabled.
    To clone a hosted Git repository, use:
    git clone ssh://username@Gerrit.com:1088/REPOSITORY_NAME.git
    Connection to Gerrit.com closed.
    ```





