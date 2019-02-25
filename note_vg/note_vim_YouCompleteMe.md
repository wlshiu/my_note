Vim YouCompleteMe
---

# Dependency

```
# Ubuntu 14.04
$ sudo apt-get -y install build-essential cmake3 python3-dev llvm-3.9 clang-3.9 libclang-3.9-dev libboost-all-dev

# Ubuntu 16.04 and later:
$ sudo apt-get -y install build-essential cmake python3-dev llvm-3.9 clang-3.9 libclang-3.9-dev libboost-all-dev
```

+ Vim versio 7.4.143 or later

    - support python 2/3

        ```shell
        $ vim --version | grep -i python
        ```

        ```shell
        $ sudo add-apt-repository ppa:jonathonf/vim
        $ sudo apt-get update # && sudo apt-get upgrade
        $ sudo apt install vim
        ```

    - Vundle

        ```shell
        $ git clone --recursive https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

            or
        $ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
        $ git submodule update --init --recursive
        ```

        1. edit `~/.vimrc`

        ```vim
        set nocompatible              " be iMproved, required
        filetype off                  " required

        " set the runtime path to include Vundle and initialize
        set rtp+=~/.vim/bundle/Vundle.vim
        call vundle#begin()
        " alternatively, pass a path where Vundle should install plugins
        "call vundle#begin('~/some/path/here')

        " let Vundle manage Vundle, required
        Plugin 'VundleVim/Vundle.vim'

        "=================== private plugins =======================
        Plugin 'Valloric/YouCompleteMe'
        let g:ycm_use_clangd = "Never"

        " add the header searching path
        let g:ycm_global_ycm_extra_conf='~/.vim/bundle/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'

        set completeopt=menu,menuone
        let g:ycm_add_preview_to_completeopt = 0
        let g:ycm_min_num_identifier_candidate_chars = 2
        let g:ycm_key_invoke_completion = '<c-space>'

        " auto trigger completer with 2 letter
        let g:ycm_semantic_triggers =  {
			\ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
			\ 'cs,lua,javascript': ['re!\w{2}'],
			\ }

        " set white-list
        let g:ycm_filetype_whitelist = {
                    \ "c":1,
                    \ "cpp":1,
                    \ "objc":1,
                    \ "sh":1,
                    \ "zsh":1,
                    \ "zimbu":1,
                    \ }
        "==========================================

        " All of your Plugins must be added before the following line
        call vundle#end()            " required
        filetype plugin indent on    " required
        ```

        1. run Vundle in vim

            ```
            :PluginInstall
            ```

# Build ycm_core

+ official

    ```shell
    $ cd ~/.vim/bundle/YouCompleteMe
    $ ./install.py --clang-completer
    ```

+ manual
    - [libclang](https://www.projectiwear.org/home/svn/iwear/src/trunk/vim/_vim/bundle/YouCompleteMe/third_party/ycmd/clang_archives/libclang-7.0.0-x86_64-unknown-linux-gnu.tar.bz2)

    ```shell
    $ cp ~/Downloads/libclang-7.0.0-x86_64-unknown-linux-gnu.tar.bz2 ~/.vim/bundle/YouCompleteMe/third_party/ycmd/clang_archives
    $ cd ~/.vim/bundle/YouCompleteMe
    $ ./install.py --clang-completer    
    ```
