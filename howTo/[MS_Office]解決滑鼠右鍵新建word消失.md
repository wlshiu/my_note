MS_Office
---

+ 解決滑鼠右鍵新建word消失

    > 想要滑鼠右鍵新建一個excel, word或者ppt, 發現無法找到這些程序, 這該怎麼辦呢?
    > + 首先按下 `Windows +R`, 輸入 regedit 進入註冊表
    > + 在註冊表編輯器左側找到`HKEY_CLASSES_ROOT`(切記一定是從這裡找), 可以按下 ctrl+f 進行尋找
    > + 分別尋找 `.docx`, `.xlsx`, `.pptx`, 將`默認(Default)`中的數值, 分別修改為`Word.Document.12`, `Excel.Sheet.12`, `PowerPoint.Show.12`
    > + 回到桌面, 多次刷新後即可看到右鍵新建中的 `Word`, `Excel`, `PPT`

