tmux
---

# Concept

```
    # a putty ui
    +----------------------------------------------+
    |         pane 0                               |
    |                                              |
    +-----------------------+----------------------|
    |                       |                      |
    |                       |                      |
    |                       |                      |
    |       pane 1          |    pane 2            |
    |                       |                      |
    |                       |                      |
    |                       |                      |
    +-----------------------+----------------------|
    | [0] 0:bash* 1:vim                            | <--- tmux status line
    +----------------------------------------------+

    [0]         => session 0
    0:bash*     => window 0 (name= bash), '*'= active
    1: vim      => window 1 (name= vim), inactive

```


+ `session`
    > the set of windows

+ `window`
    > the set of panes

+ `pane`
    > a area in a window

# Config

```shell
$ vim ~/.tmux.conf

    ### rebind hotkey

    # prefix setting (screen-like)
    # set -g prefix C-a
    # unbind C-b
    # bind C-a send-prefix

    # reload config without killing server
    bind R source-file ~/.tmux.conf \; display-message "Config reloaded..."

    # "|" splits the current window vertically, and "-" splits it horizontally
    unbind %
    bind | split-window -h
    bind - split-window -v

    # Pane navigation (vim-like)
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Pane resizing
    bind -r Left  resize-pane -L 4
    bind -r Down  resize-pane -D 4
    bind -r Up    resize-pane -U 4
    bind -r Right resize-pane -R 4


    ### other optimization

    # set the shell you like (zsh, "which zsh" to find the path)
    # set -g default-command /bin/zsh
    # set -g default-shell /bin/zsh

    # use UTF8
    # set -g utf8
    # set-window-option -g utf8 on

    # display things in 256 colors
    set -g default-terminal "screen-256color"

    # mouse is great!
    set-option -g mouse on

    # history size
    set -g history-limit 10000

    # fix delay
    set -g escape-time 0

    # 0 is too far
    set -g base-index 1
    setw -g pane-base-index 1

    # stop auto renaming
    setw -g automatic-rename off
    set-option -g allow-rename off

    # renumber windows sequentially after closing
    set -g renumber-windows on

    # window notifications; display activity on other window
    setw -g monitor-activity on
    set -g visual-activity on
```

+ Hot key
    > the default prefix key is C+b

    - 系統操作

        1. `<C+b> d`
            > 將目前的 session 放到背景執行 (detach)
        1. `<C+b> s`
            > 切換 session
        1. `<C+b> [`
            > 進入複製模式
            > + select range in vim
            > + copy
            >> `ctrl + b + [`
            > + paste
            >> `ctrl + b + ]`

        1. `<C+b> :`
            > 進入命令模式
        1. `<C+b> ?`
            > 查詢快捷鍵

    - pane(區塊) 指令

        1. `<C+b> "` or `<C+b> |`
            > 水平分割視窗
        1. `<C+b> %` or `<C+b> -`
            > 垂直分割視窗
        1. `<C+b> 方向鍵`
            > 分割視窗大小調整
        1. `<C+b> h,j,k,l` (vim 方向鍵)
            > 切換游標所在區塊
        1. `<C+b> space`
            > 重新佈局分割視窗, 內建多種佈局.
        1. `<C+b> x`
            > 關閉當前面板
        1. `<C+b> q`
            > 顯示面板編號
        1. `<C+b> {`
            > 交換面板位置(向前)
        1. `<C+b> }`
            > 交換面板位置(向後)

    - window(視窗) 指令

        1. `<C+b> c`
            > 開新視窗
        1. `<C+b> &`
            > 關閉視窗
        1. `<C+b> 0~9`
            > 切換至指定視窗
        1. `<C+b> n`
            > 切換到下一個視窗 (next)
        1. `<C+b> p`
            > 切換到上一個視窗 (previous)
        1. `<C+b> f`
            > 找尋指定 pattern 並跳到該視窗
        1. `<C+b> ,`
            > 命名視窗



