Trace kernel
---

+ ctags/gtags/cscope

    reference:
    [linux-kernel-make-tag-variable](https://stackoverflow.com/questions/50791012/linux-kernel-make-tag-variable)

    ```
    $ make O=. ARCH=arm SUBARCH=omap2 COMPILED_SOURCE=1 gtags tags cscope
    ```

    - `ARCH`
        > which architecture to index. You can see all architectures list just by doing `ls -l arch/` in your kernel source tree.

    - SUBARCH
        > the meaning of this variable depends on your architecture
        >> if `ARCH=arm`, SUBARCH will be used to determine `arch/arm/mach-*` and `arch/arm/plat-*` directories,
        and these directories will be indexed

    - ALLSOURCE_ARCHS
        > use this to index more than one architecture.

        ```
        ALLSOURCE_ARCHS="x86 mips arm"
            or
        ALLSOURCE_ARCHS="all"
        ```

    - COMPILED_SOURCE
        >+ `1`: index only actually compiled source files
        >+ `0`: index all source files

    - `O=`
        > paths of cscope/ctags index files
        >> useful if you want to load created cscope/ctags index files outside of kernel directory

