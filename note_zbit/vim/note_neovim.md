Neo Vim
---

## [vim-plug](https://github.com/junegunn/vim-plug) install

+ windows path

    ```
    C:\Users\<user-name>\AppData\Local\nvim-data\site\autoload\plug.vim
    ```

+ linux path

    ```
    ~/.config/nvim/plugin.vim
    ```

## Neo Vim configuration

+ `init.vim`

    - windows
        > `C:\Users\<user-name>\AppData\Local\nvim\init.vim`

        ```vim
        ; init.vim

        call plug#begin('C:\Users\<user-name>\AppData\Local\nvim\plugged')

        Plug 'neoclide/coc.nvim', {'branch': 'release'}

        call plug#end()
        ```

    - linux
        > `~/.local/nvim/init.vim`

        ```
        call plug#begin('~/.local/nvim/plugged')

        Plug 'neoclide/coc.nvim', {'branch': 'release'}

        call plug#end()
        ```

## Instarll plug-in

In vim

```
:PlugInstall
```

## Reference

+ [Windows系統下neovim的安裝和簡易組態](https://zhuanlan.zhihu.com/p/432823659)
+ [Day 16：自動補全！coc.nvim](https://ithelp.ithome.com.tw/articles/10274461)


