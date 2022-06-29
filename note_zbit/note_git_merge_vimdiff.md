note_git_merge_vimdiff
---

用 vimdiff 解 git 衝突

# 設定 mergetool

首先要將 git 的 mergetool 設定為 vimdiff, 可以下指令:

```
$ git config --global merge.tool vimdiff
```

或者直接修改 gitconfig, 在最後面加上:

```
[merge]
    tool = vimdiff
```

這樣設定就算完成了.

# 使用方式

當 git merge 出現衝突時, 直接在 terminal 輸入:

```
git mergetool
```

就會開啟 vimdiff 的 mergetool, 介面示意如下:

```
+--------------------------------+
| LOCAL  |     BASE     | REMOTE |
+--------------------------------+
|             MERGED             |
+--------------------------------+

- LOCAL : 本機檔案(也就是現在所在的 branch)
- BASE  : local 以及 remote 兩個分支的 base 內容
- REMOTE: 遠端檔案(要 merge 進來的 branch)
- MERGED: merge 之後的結果, 在這裡解衝突
```

解衝突就沒什麼特別的, 和平常一樣, 會有許多衝突用 `<<<<<<<` 和 `>>>>>>>` 標示, 解完存檔後記得 commit 就完成 merge 了.
比較特別的是使用 vimdiff 當作 mergetool 時, 有一些比較方便的指令可以使用:

```vim
" 跳到下一個衝突點
[c

" 跳到上一個衝突點
]c

" 取得 buffer 編號
:buffers

" 從 buffspec / keyword 視窗取得內容
:diffget [buffspec|keyword]

" 將內容丟至 buffspec / keyword 視窗
:diffput [buffspec|keyword]

" 刷新 diff 顯示
:diffupdate
```

假設我們有一段程式碼衝突, 希望使用 remote 的內容, 可以使用 `diffget` 取得 REMOTE 視窗的內容, 取得內容有兩種方式:

1. 使用視窗關鍵字:

```
:diffget REMOTE
```

2. 使用視窗編號:

```
" 先利用 :buffers 取得視窗編號, 假設想使用的視窗編號為 3
:buffers
:diffget 3
```

兩種方式結果都一樣, 但下完指令最好還是確認一下結果是否是自己預期的 XD
如果修改了之後發現 highlight 什麼的有點亂, 可以使用 `:diffupdate` 來手動刷新一下 diff 顯示

# 參考資料
+ [Vim Tips Wiki: A better Vimdiff Git mergetool](http://vim.wikia.com/wiki/A_better_Vimdiff_Git_mergetool)
+ [使用 vimdiff 來解決 git merge conflict](https://yodalee.blogspot.com/2013/03/vimdiffgit-merge-conflict_28.html)
+ [技巧:Vimdiff 使用](https://www.ibm.com/developerworks/cn/linux/l-vimdiff/index.html)
