CppCheck
---

```
$ cppcheck --enable=all --force ./printf.c
```

+ script

    ```
    $ vi z_check_result.sh
        #!/bin/bash

        help()
        {
            echo -e "usage: $0 <check path>"
            exit -1;
        }

        if [ $# != 1 ];then
            help
        fi

        src_path=$1
        file_list=check.files

        find . -type f -name '*.c' > ${file_list}


        out_xml="z_check_result.xml"

        #===========================
        # --addon=misra.py
        # --addon=misra.json
        cppcheck --file-list=$file_list --xml --enable=all --force  2> "$out_xml"
    ```

## MISCRA-C detection

Install 時, 需 enable `python addons`

+ Example
    > [noisymime/speeduino/misra](https://github.com/noisymime/speeduino/tree/master/misra)


# Reference

+ [Cppcheck - A tool for static C/C++ code analysis](https://cppcheck.sourceforge.io/)
+ [CppCheck (CLI為主) - HackMD](https://hackmd.io/@Tim-WTChien/H1gHcanEa)
+ [通過指令碼使用Cppcheck做靜態測試並生成報告(Windows)](https://blog.csdn.net/buyicn/article/details/132394233)
+ [炒雞實用的程式碼缺陷靜態檢查工具：cppcheck 程式碼缺陷檢測-CSDN部落格](https://blog.csdn.net/weixin_43944012/article/details/131218258?spm=1001.2101.3001.6650.5&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-5-131218258-blog-134971585.235%5Ev43%5Epc_blog_bottom_relevance_base1&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-5-131218258-blog-134971585.235%5Ev43%5Epc_blog_bottom_relevance_base1&utm_relevant_index=10)