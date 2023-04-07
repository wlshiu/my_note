[GDB Dashboard](https://github.com/cyrus-and/gdb-dashboard)
---

## Setup gdb-dashboard

+ download gdb-dashboard

    ```
    $ wget -P ~ https://git.io/.gdbinit
    ```

+ manually setup

    - Put `.gdbinit` and `.gdbinit.d` to `$HOME`
        > `.gdbinit` is the core of gdb-dashboard and it will pre-load `.gdbinit.d/*`



## Running

+ Execute GDB
    > the promp will be changed from `(gdb)` to `>>>`
    >>  `gdb-dashboard` will automatically launch after **set breakpoint and run program**

+ use `GDB commnads` to start debug

## Tips

+ reflash screen

    ```
    >>> dashboard
    ```

+ change layout
    > the customer commands are defined in `~/.gdbinit.d/init`

    ```
    >>> win- (press tab to list customer commands)
    ```

