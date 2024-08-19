RISC-V GDB
---

[GitHub - XUANTIE-RV/binutils-gdb](https://github.com/XUANTIE-RV/binutils-gdb)
> official 無法正常使用...


## Re-Build


```
$ cd binutils-gdb
$ mkdir out && cd out
$ ../configure --with-python # --prefix=
```

+ compile fail: ` unistd.h:663:3: error: #error “Please include config.h first.`

    ```
    In file included from /usr/include/bits/sigstksz.h:24,
                     from /usr/include/signal.h:315,
                     from ../gnulib/import/signal.h:52,
                     from /ironwood1/sourceware-git/rawhide-gnulib/bld/../../worktree-gnulib/gdbserver/../gdb/nat/amd64-linux-siginfo.c:20:
    ../gnulib/import/unistd.h:663:3: error: #error "Please include config.h first."
      663 |  #error "Please include config.h first."
          |   ^~~~~

    ...
    error: ‘_GL_INLINE_HEADER_BEGIN’ does not name a type _GL_INLINE_HEADER_BEGIN

    ```

    - fix include order

        ```
        $ vi /gdb/nat/amd64-linux-siginfo.c
            // #include <signal.h>
            #include "gdbsupport/common-defs.h"
            #include <signal.h>
            #include "amd64-linux-siginfo.h"
        ```

## check python working in GDB

```
$ arm-none-eabi-gdb-py3 --batch -ex 'python import sys; print(sys.version)'
3.10.4 (main, Aug 27 2022, 18:48:21) [GCC 11.2.0]
```





