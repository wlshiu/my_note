
Step 1. reset setting
    $ sh winmerge-git-setup.sh


Ex：比較某一檔案在任意2個commit之中的差異，1234與abcd是commit的SHA1
    git diff 1234 abcd project/dvr/ts_record.c

Ex：比較某一檔案目前版本跟前3版的差異
    git diff HEAD HEAD~3 project/dvr/ts_record.c
