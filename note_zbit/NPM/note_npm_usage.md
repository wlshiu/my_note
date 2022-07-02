note_npm_usage [[Back](../note_git_gen_change_log.md)]
---

`NPM` 全名是 **Node Package Manager**, 它是 `node.js` 預設的 node 套件管理平台, 運用 `NPM` 我們可以更方便的進行套件管理(安裝、升級與刪除).

# 使用 **NPM** 管理專案

## 初始化專案

初始化專案時, 需要專案訊息, 如下操作:
```
$ cd my_project
$ npm init
    This utility will walk you through creating a package.json file.
    It only covers the most common items, and tries to guess sensible defaults.

    See `npm help json` for definitive documentation on these fields
    and exactly what they do.

    Use `npm install <pkg>` afterwards to install a package and
    save it as a dependency in the package.json file.

    Press ^C at any time to quit.
    package name: (log)
```


+ 初始化-需要寫入專案資訊 (會建立`Package.json`)
    > 如果不知道要打什麼沒關係, 基本上只要一直 **enter** 就好.
    完成後就會在目錄看到`Package.json`檔案, 點進去就會看到剛剛填寫的專案資料.

    - package name: 專案名稱, 預設就是該目錄名 (只能是小寫英文)
    - version: 專案版本 (預設會是 1.0.0)
    - description: 專案描述
    - entry point: 專案進入點
    - test command: 專案測試指令
    - git repository: 專案原始碼的版本控管位置
    - keyword: 專案關鍵字
    - author: 專案作者, 以 `author-name <author@email.com>` 寫之
    - License: 專案版權

## `Package.json`

`Package.json` 用來管理專案中所使用的所有 dependencies, version, ...等, 當多方開發時只要下載 `Package.json` 並執行 `npm install`，就可以直接將 `Package.json`內的所有專案中使用的套件一起載入.
> `package-lock.json` 用途和 `Package.json` 一樣, 只差在`Package.json` 會自動下載套件最新的版本; 而 `package-lock.json` 會下載特定套件版本

+ example

    ```json
    {
       "name": "mypackage",
       "version": "0.7.0",
       "description": "Sample package for CommonJS. This package demonstrates the required elements of a CommonJS package.",
       "keywords": [
           "package",
           "example"
       ],
       "maintainers": [
           {
               "name": "Bill Smith",
               "email": "bills@example.com",
               "web": "http://www.example.com"
           }
       ],
       "contributors": [
           {
               "name": "Mary Brown",
               "email": "maryb@embedthis.com",
               "web": "http://www.embedthis.com"
           }
       ],
       "bugs": {
           "mail": "dev@example.com",
           "web": "http://www.example.com/bugs"
       },
       "licenses": [
           {
               "type": "GPLv2",
               "url": "http://www.example.org/licenses/gpl.html"
           }
       ],
       "repositories": [
           {
               "type": "git",
               "url": "http://hg.example.com/mypackage.git"
           }
       ],
       "dependencies": {
           "webkit": "1.2",
           "ssl": {
               "gnutls": ["1.0", "2.0"],
               "openssl": "0.9.8"
           }
       },
       "implements": ["cjs-module-0.3", "cjs-jsgi-0.1"],
       "os": ["linux", "macos", "win"],
       "cpu": ["x86", "ppc", "x86_64"],
       "engines": ["v8", "ejs", "node", "rhino"],
       "scripts": {
           "install": "install.js",
           "uninstall": "uninstall.js",
           "build": "build.js",
           "test": "test.js"
       },
       "directories": {
           "lib": "src/lib",
           "bin": "local/binaries",
           "jars": "java"
       }
    }
    ```

## 下載套件

```
$ npm install <套件名稱>;               # node_modules 安裝在目前專案內
$ npm install <套件名稱> -g;            # node_modules 安裝在系統中(global, C:/[user-name]/AppData/...)
$ npm install <套件名稱> --save;        # 安裝並將資訊加入 dependencies of Package.json, 同時也會一併記錄此套件的 dependencies 資訊
$ npm install <套件名稱> --save-dev;    # 安裝並將資訊加入 devDependencies of Package.json (?)

# 'npm install' 可以簡化為 'npm i'

```

+ 列出所有套件資訊

    ```
    $ npm list
    ```

+ 更新套件

    ```
    $ npm update
    ```

    - `Package.json`中, 版本訊息出現 `^` 符號
        > 只更新相同 `Major version` 的版本
        >> e.g. `^4.0.2` => 更新到 `4.x.x` 最新本

        ```
        {
            ...

            "dependencies" : {
                "gulp": "^4.0.2"
            }
        }
        ```

    - 更新到最新本
        > `npm install 套件@lastest`

        ```
        $ npm install glup@lastest
        ```

    - 更新到特定版本
        > `npm install 套件@版本數字`

        ```
        $ npm install glup@5.0.1
        $ npm install glup@5        # 更新到 major = 5 的最新版本
        $ npm install glup@4.2      # 更新到 major = 4 且 minor = 2 的最新版本
        ```

+ 當出現 Warning message 時, 可能的原因

    - 目前資料夾內沒有 `Package.json`

    - `Package.json` 內的資訊可能不完整

## 刪除套件

```
$ npm prune                        # 清理 node_modules 中不需要的檔案
$ npm uninstall <套件名稱>          # 只刪除套件, 但不會更新到 package.json
$ npm uninstall <套件名稱> --save   # 只刪除套件並更新到 package.json

# 'npm uninstall' 可簡化為 'npm un'
```


# Reference

+ [從零開始: 使用NPM套件](https://medium.com/html-test/%E5%BE%9E%E9%9B%B6%E9%96%8B%E5%A7%8B-%E4%BD%BF%E7%94%A8npm%E5%A5%97%E4%BB%B6-317beefdf182)
+ [npm 入門到進階 常用指令與版本規則教學](https://linyencheng.github.io/2020/03/22/tool-npm/)
