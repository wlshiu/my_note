# Reduce repository size
---

隨著時間的推移, Git 倉庫變得更大. 將大文件添加到 Git 倉庫時:

+ 獲取倉庫變得更慢, 因為每個人都必須下載文件.
+ 它們佔用了服務器上的大量存儲空間.
+ 達到 Git 倉庫存儲限制.

重寫倉庫可以刪除不需要的歷史記錄以縮小倉庫.
我們推薦 [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/README.md) 而不是
[`git filter-branch`](https://docs.gitlab.cn/jh/user/project/repository/https%20://git-scm.com/docs/git-filter-branch) 和
[BFG](https://rtyley.github.io/bfg-repo-cleaner/).
> 重寫倉庫歷史是一種破壞性操作. 在開始之前, 請確保備份您的倉庫. 備份倉庫的最佳方法是導出項目.

## 從倉庫歷史記錄中清除文件
要減少極狐GitLab 中存儲庫的大小, 您必須首先從由極狐GitLab 自動創建的分支、標簽和其他內部引用 (refs) 中刪除對大文件的引用. 這些 refs 包括:

+ `refs/merge-requests/*`: 合並請求.
+ `refs/pipelines/*`: 流水線.
+ `refs/environments/*`: 環境.
+ `refs/keep-around/*` 被創建為隱藏的 refs, 以防止數據庫中引用的提交被刪除.

這些 ref 不會自動下載, 也不會公佈隱藏的 ref, 但我們可以使用項目導出刪除這些 ref.
> 此過程不適合從倉庫中刪除敏感數據, 例如密碼或密鑰. 有關提交的信息(包括文件內容)緩存在數據庫中, 即使從倉庫中刪除後仍然可見.

### 從極狐GitLab 倉庫中清除文件

+ 使用支持的包管理器或從源代碼安裝 [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md) 或
[`git-sizer`](https://github.com/github/git-sizer#getting-started).

+ 生成一個新的項目導出並下載它. 此項目導出包含您的存儲庫和 *refs* 的備份副本, 我們可用於從您的倉庫中清除文件.

+ 使用 `tar` 解壓備份

    ```
    $ shell tar xzf project-backup.tar.gz
    ```

    > 包含一個由 [`git bundle`](https://git-scm.com/docs/git-bundle) 創建的 `project.bundle` 文件.

+ 使用 `--bare` 和 `--mirror` 選項從包中 clone 一個新的倉庫副本

    ```
    $ git clone --bare --mirror /path/to/project.bundle
    ```

+ 導航到 `project.git` 目錄

    ```
    $ cd project.git
    ```

+ 使用 `git filter-repo` 或 `git-sizer`, 分析您的倉庫並查看結果, 確定您要清除哪些項目

    ```
    # Using git filter-repo
    $ git filter-repo --analyze head .git/filter-repo/analysis/*-{all,deleted}-sizes.txt

    # Using git-sizer
    $ git-sizer
    ```

+ 繼續清除倉庫歷史記錄中的所有文件. 因為我們試圖刪除內部 *refs*, 所以我們依靠每次運行產生的 `commit-map` 來告訴我們要刪除哪些內部 *refs*.
    > `git filter-repo` 每次運行都會創建一個新的 `commit-map` 文件, 並覆蓋上一次運行中的 `commit-map`.
    每次運行都需要此文件. 每次運行 `git filter-repo` 時都執行下一步.

    > 要清除特定文件, 可以組合使用 `--path` 和 `--invert-paths` 選項

    ```
    $ git filter-repo --path path/to/file.ext --invert-paths
    ```

    > 通常要清除所有大於 10M 的文件, 可以使用 `--strip-blobs-bigger-than` 選項

    ```
    $ git filter-repo --strip-blobs-bigger-than 10M
    ```

    > 請參閱 [`git filter-repo`](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
    文檔獲取更多示例和完整文檔.

+ 因為從包文件 clone, 會將 `origin` 遠端設置為本地包文件, 刪除這個 `origin` 遠端, 並將其設置為您的 repository 的 URL

    ```
    $ git remote remove origin
    $ git remote add origin https://gitlab.example.com/<namespace>/<project_name>.git
    ```

+ 強制推送您的更改, 以覆蓋 GitLab 上的所有分支

    ```
    $ git push origin --force 'refs/heads/*'
    ```

    > `protected_branches` 會導致失敗. 要繼續, 您必須移除分支保護, 推送, ...等, 然後重新啟用 `protected_branches` .

+ 要從標簽版本中刪除大文件, 請強制將您的更改推送到 GitLab 上的所有標簽

    ```
    $ git push origin --force 'refs/tags/*'
    ```

    > `protected_tags` 會導致失敗. 要繼續, 您必須移除標簽保護, 推送, ...等, 然後重新啟用 `protected_tags`.

+ 為了防止不再存在的提交的 dead links, 推送由 `git filter-repo` 創建的 `refs/replace`.

    ```
    $ git push origin --force 'refs/replace/*'
    ```

有關其工作原理的信息, 請參閱 Git replace 文檔.
> + 等待至少 30 分鐘, 因為倉庫清理流程只處理超過 30 分鐘的對象.
> + 運行倉庫清理.

## 倉庫清理 (Repository cleanup)

倉庫清理允許您上傳 text objects, GitLab 刪除對這些 objects 的內部 Git references.
您可以使用 [`git filter-repo`](https://github.com/newren/git-filter-repo) 生成可與倉庫清理一起使用的對象列表(在 `commit-map` 文件中).

引入於 13.6 版本, 安全清理倉庫需要在操作期間將其設為只讀.
這會自動發生, 但如果任何寫入正在進行, 則提交**清理請求**將失敗, 因此在繼續之前取消任何未完成的 `git push` 操作.

### 清理倉庫步驟
+ 轉到倉庫的項目.
+ 導航到 `Settings` -> `Repository`.
+ 上傳對象列表. 例如, 由`it filter-repo` 創建的 `commit-map` 文件位於 `filter-repo` 目錄中.
如果您的 `commit-map` 文件大於 250KB 或 3000 行, 則可以將文件拆分並逐個上傳：

    ```
    $ split -l 3000 filter-repo/commit-map filter-repo/commit-map-
    ```

+ 點擊開始清理.


這樣:

+ 刪除對舊提交的任何內部 Git references.
+ 對倉庫運行 `git gc --prune=30.minutes.ago`, 刪除未引用的對象.
臨時重新打包倉庫會導致倉庫的大小顯著增加, 因為在創建新的打包文件之前不會刪除舊的打包文件.

+ 取消連接到項目的任何未使用的 LFS 對象, 釋放存儲空間.
+ 重新計算磁盤上倉庫的大小.

清理完成後, GitLab 會發送一封電子郵件通知, 其中包含重新計算的倉庫大小.

如果存儲庫大小沒有減少, 這可能是由於鬆散對象被保留, 因為它們在過去 30 分鐘內發生的 Git 操作中被引用.
在倉庫休眠至少 30 分鐘後, 嘗試重新運行這些步驟.

使用倉庫清理時, 請注意：

+ 緩存項目統計信息. 您可能需要等待 5-10 分鐘才能看到存儲利用率的降低.
+ 清理超過 30 分鐘的鬆散對象. 這意味著不會立即刪除過去 30 分鐘內添加或引用的對象.
如果您有權訪問 Gitaly 服務器, 您可以避開延遲並立即地運行 `git gc --prune=now` 來清理所有鬆散的對象.

+ 這個過程從 GitLab 緩存和數據庫中刪除了重寫提交的一些副本, 但覆蓋范圍仍然存在許多差距, 並且一些副本可能會無限期地持續存在.
清除實例緩存可能有助於刪除其中一些, 但出於安全目的不應依賴它！


# Reference

+ [Reduce repository size](https://docs.gitlab.com/ee/user/project/repository/reducing_the_repo_size_using_git.html)
+ [減少倉庫大小](https://docs.gitlab.cn/jh/user/project/repository/reducing_the_repo_size_using_git.html)

