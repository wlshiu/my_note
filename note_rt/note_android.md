Android development
---

+ download source code

+ ubuntu > 16.04

    - Java

        1. Android 4.x
            > Need Oracle JDK-6 (This version may not be iinstalled with net......)
            ```
            # for get cmd "add-apt-repository"
            $ sudo apt-get install python-software-properties
            $ sudo apt-get install software-properties-common

            # add Oracle java server
            $ sudo add-apt-repository ppa:webupd8team/java
            $ sudo apt-get update
            $ sudo apt-get install oracle-java6-installer
            $ sudo apt-get install oracle-java6-set-default
            ```

            >   > a. download [jdk1.6.0_45.bin] (http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase6-419409.html)
                ```
                $ sudo cp jdk-6u45-linux-x64.bin /usr/local     // copy to local/
                $ sudo chmod 777 jdk-6u45-linux-x64.bin         // change attribute
                $ sudo ./jdk-6u45-linux-x64.bin                 // decompress to jdk1.6.0_45/
                ```



















