linux kernel make tag variables
---

# Variables you should use

Next variables can be passed to `tags.sh`
(actually you should pass them to `make tags cscope` command, and Makefile will pass them to `tags.sh` for you).

+ `ARCH`
    > which architecture to index.
    You can see all architectures list just by doing `ls -l` `arch/` in your kernel source tree.

+ `SUBARCH`
    > the meaning of this variable depends on your architecture

    - if `ARCH=arm`, `SUBARCH` will be used to determine `arch/arm/mach-*` and `arch/arm/plat-*` directories,
        and these directories will be indexed

    - if `ARCH=um`, use `SUBARCH` to specify which architecture you actually want to
        use in your User-Mode Linux (like `SUBARCH=arm` or `SUBARCH=x86`)

    - for the rest of architectures, you can omit this variable

+ `ALLSOURCE_ARCHS`
    > use this to index more than one architecture.
    Like `ALLSOURCE_ARCHS="x86 mips arm"` or `ALLSOURCE_ARCHS="all"`.
    If you only want to index one architecture, omit this variable and use `ARCH` instead.

+ `COMPILED_SOURCE`
    > set this variable to 1 if you want to index only actually compiled source files.
    If you want to index all source files, omit setting this variable.

+ `O=` (this is actually Makefile parameter)
    > use absolute paths (useful if you want to load created cscope/ctags index files outside of kernel directory,
    e.g. for development of out-of-tree kernel modules).
    If you want to use relative paths (i.e. you're gonna do development only in kernel dir), just omit that parameter.

## Variables you don't need to touch

+ `SRCARCH`
    > being set from ARCH variable in Makefile and then passed to script.
    You probably don't need to mess with it, just set ARCH variable correctly

+ `srctree`
    > kernel source tree path. This variable will be passed from Makefile automatically
    if you're using this script via make cscope tags.

+ `src` and `obj` variables
    > those are not used by `scripts/tags.sh` anymore.
    It was replaced by utilizing `KBUILD_SRC` variable,
    which is provided from Makefile automatically, when you provide `O=...` parameter to it.

## Usage

Basically, I'd recommend to only use `scripts/tags.sh` via `make` invocation. Example:

```
$ make O=. ARCH=arm SUBARCH=omap2 COMPILED_SOURCE=1 cscope tags
```

or

```
$ make ARCH=x86 cscope tags
```