autotool
---

# how to use autotool

+ generate `configure.ac`

    ```shell
    # in root dir of project
    $ autoscan && mv configure.scan configure.ac

    # modify
    $ vi configure.ac
        #                                               -*- Autoconf -*-
        # Process this file with autoconf to produce a configure script.

        AC_PREREQ([2.69])
        AC_INIT("Program_name", 1.0)  # modify to your program name
        AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
        AM_PROG_AR
        # AC_CONFIG_SRCDIR([main.c cmd_util.c])
        AC_CONFIG_HEADERS([config.h])
        # AC_CONFIG_MACRO_DIR([m4])
        LT_INIT

        # Checks for programs.
        AC_PROG_CC  # default is gcc
        # AC_PROG_CC(arm-linux-gnueabihf-gcc)
        # AC_PROG_CXX(arm-linux-gnueabihf-g++)


        # Checks for libraries.

        # Checks for header files.
        AC_CHECK_HEADERS([stdint.h stdlib.h string.h sys/time.h unistd.h])

        # Checks for typedefs, structures, and compiler characteristics.
        AC_TYPE_UINT16_T
        AC_TYPE_UINT32_T
        AC_TYPE_UINT8_T

        # Checks for library functions.
        AC_FUNC_MALLOC
        AC_CHECK_FUNCS([gettimeofday memset strtoul])

        AC_CONFIG_FILES([Makefile] libisp_cmd/Makefile) # add Makefile files dependent on directory architecture
        AC_OUTPUT
    ```

+ generate `configure`

    ```shell
    $ aclocal && autoconf && autoheader
    ```

+ add `Makefile.am` to *ALL* folder

    - at root of project

        ```Makefile
        UTOMAKE_OPTIONS = foreign
        SUBDIRS = src
        bin_PROGRAMS = Hollow
        Hollow_SOURCES =\
            main.c

        Hollow_CPPFLAGS=\
            -I./inc

        Hollow_LDADD=\
            lib/libx.la

        #ACLOCAL_AMFLAGS=\
        #	-I m4
        ```

    - at sub-folder

        ```Makefile
        lib_LTLIBRARIES = libx.la
        libx_la_SOURCES=\
            inc/log.h \
            inc/sys_arch.h \
            src/sys_arch.c

        libx_la_CPPFLAGS=\
            -I./inc -lc
        ```

+ generate `Makefile.in`

    ```shell
    $ automake --add-missing
    ```

+ loss `ltmain.sh`

    ```
    # if error: required file './ltmain.sh' not found
    $ libtoolize
    ```



# reference
+ [GNU Build System: Autotools 初探](http://wen00072.github.io/blog/2014/05/13/study-on-gnu-build-system-autotools/)
+ [在Autotools使用Libtool編譯函式庫](http://wen00072.github.io/blog/2014/05/20/autotools-to-use-libtool-compile-function-library/)
+ [automake 和 autoconf 使用簡明教程](https://thebigdoc.readthedocs.io/en/latest/auto-make-conf.html)
