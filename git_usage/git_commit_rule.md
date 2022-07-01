# git commit 提交規範
```md
<type>(<scope>): <subject>

<body>

<footer>
```

大致分為三個部分(使用空行分割):

1. 標題行: 必填, 描述主要修改類型和內容
2. 主題內容: 描述為什麼修改, 做了什麼樣的修改, 以及開發的思路等等
3. 頁腳註釋: 放 Breaking Changes 或 Closed Issues


### type
commit 的類型:
+ feat: 新功能、新特性
+ fix: 修改 bug
+ perf: 更改代碼, 以提高性能(在不影響代碼內部行為的前提下, 對程序性能進行優化)
+ refactor: 代碼重構 (重構, 在不影響代碼內部行為、功能下的代碼修改)
+ docs: 文檔修改
+ style: 代碼格式修改 (例如分號修改)
+ test: 測試用例新增、修改
+ build: 影響項目構建或依賴項修改
+ revert: 恢復上一次提交
+ ci: 持續集成相關文件修改
+ chore: 其他修改(不在上述類型中的修改)
+ release: 發佈新版本

### scope
commit 影響的範圍, 比如: route, component, utils, build...

### subject
commit 的概述

### body
commit 具體修改內容, 可以分為多行.

### footer
一些備註, 通常是 BREAKING CHANGE 或修復的 bug 的鏈接.

## 約定式提交規範
以下內容來源於: https://www.conventionalcommits.org/zh-hans/v1.0.0-beta.4/
+ 每個提交都必須使用類型字段前綴, 它由一個名詞組成, 諸如 `feat` 或 `fix`, 其後接一個可選的作用域字段, 以及一個必要的冒號(英文半角)和空格.
+ 當一個提交為應用或類庫實現了新特性時, 必須使用 `feat` 類型.
+ 當一個提交為應用修復了 `bug` 時, 必須使用 `fix` 類型.
+ 作用域字段可以跟隨在類型字段後面. 作用域必須是一個描述某部分代碼的名詞, 並用圓括號包圍, 例如:  `fix(parser):`
+ 描述字段必須緊接在類型/作用域前綴的空格之後. 描述指的是對代碼變更的簡短總結, 例如:  `fix: array parsing issue when multiple spaces were contained in string.`
+ 在簡短描述之後, 可以編寫更長的提交正文, 為代碼變更提供額外的上下文信息. 正文必須起始於描述字段結束的一個空行後
+ 在正文結束的一個空行之後, 可以編寫一行或多行腳注. 腳注必須包含關於提交的元信息, 例如: 關聯的合併請求, Reviewer, 破壞性變更, 每條元信息一行.
+ 破壞性變更必須標示在正文區域最開始處, 或腳注區域中某一行的開始. 一個破壞性變更必須包含大寫的文本 `BREAKING CHANGE`, 後面緊跟冒號和空格.
+ 在 `BREAKING CHANGE: ` 之後必須提供描述, 以描述對 API 的變更. 例如:  `BREAKING CHANGE: environment variables now take precedence over config files.`
+ 在提交說明中, 可以使用 `feat` 和 `fix` 之外的類型.
+ 工具的實現必須不區分大小寫地解析構成約定式提交的信息單元, 只有 `BREAKING CHANGE` 必須是大寫的.
+ 可以在類型/作用域前綴之後, `:` 之前, 附加 `!` 字符, 以進一步提醒注意破壞性變更. 當有 `!` 前綴時, 正文或腳注內必須包含 `BREAKING CHANGE: description`

## 示例
### fix

如果修復的這個BUG只影響當前修改的文件, 可不加範圍. 如果影響的範圍比較大, 要加上範圍描述.

例如這次 BUG 修復影響到全局, 可以加個 global. 如果影響的是某個目錄或某個功能, 可以加上該目錄的路徑, 或者對應的功能名稱.
```js
// 示例1
fix(global): 修復checkbox不能復選的問題
// 示例2 下面圓括號裡的 common 為通用管理的名稱
fix(common): 修復字體過小的BUG, 將通用管理下所有頁面的默認字體大小修改為 14px
// 示例3
fix: value.length -> values.length
```

### feat
```js
feat: 添加網站主頁靜態頁面

這是一個示例, 假設對點檢任務靜態頁面進行了一些描述.

這裡是備註, 可以是放BUG鏈接或者一些重要性的東西.
```

### chore
chore 的中文翻譯為日常事務、例行工作, 顧名思義, 即不在其他 commit 類型中的修改, 都可以用 chore 表示.
```js
chore: 將表格中的查看詳情改為詳情
```

## 參考資料
+ [約定式提交](https://www.conventionalcommits.org/zh-hans/v1.0.0-beta.4/)
