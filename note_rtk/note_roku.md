Merlin3 RoKu
---
## misc
+ git
    - `git clean -xdf`

+ debug
    - gdb

        ```
        $ ./configure CFLAGS="-g -O0" --prefix=${path of you want to install}

        $ gdb --args executablename arg1 arg2 arg3
        ```

    - c++filt
        > recover the megic number of function name
        ```
        $ c++filt _ZTIN5boost11regex_errorE
        ```

    - strace
        ```
        $ strace -e TARGET_FUNC_NAME -f PROGRAM

          # get open so info
        $ strace -e open -f PROGRAM | grep '\.so'
        ```

+ re-mount rootfs to r/w
    ```
    $ mount -o rw,remount /
    ```


## project

+ DB264_Merlin3_FW_TV001_Venus_Native
    > Common Version

+ DB274_Merlin3_FW_TV043_Venus_Roku_Native
    > roku customer

    - jira (https://jira.portal.roku.com:8443/projects/REALTEK/issues/REALTEK-49?filter=allopenissues)
        > item: Task REALTEK-1 </br>
        ```
        https://cs.wang:resetm33!!@jira.portal.roku.com:8443/projects/REALTEK/issues/REALTEK-49?filter=allopenissues
        ```


## Enviornment

+ dependency libs
    ```
    sudo apt-get install gettext autopoint automake libtool gtk-doc-tools autoconf \
        libglib2.0-0 libglib2.0-bin libglib2.0-data libglib2.0-dev cmake intltool ccache

      # maybe don't need below setting
    export PATH="/usr/lib/ccache/bin/:$PATH"
    ```

    - manually  install
        > loss some file if you use `apt-get install`   ........WTF

        1. pkg-config
            ```
            wget https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
            $ tar -zxf pkg-config-0.29.2.tar.gz
            $ cd pkg-config-0.29.2/

              # default --prefix=/usr/
            $ ./configure --prefix=${path of you want to install}
            $ make && make install
            ```
        1. automake
            ```
            $ wget http://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz
            $ tar -zxf automake-1.14.1.tar.gz
            $ cd automake-1.14.1/

              # default --prefix=/usr/
            $ ./configure --prefix=${path of you want to install}
            $ make && make install
            ```
    - re-direct self libs
        ```
        $ export PKG_CONFIG_PATH=${mylibs}/lib/pkgconfig/
        ```

+ directory
    ```
    ~merlin3_roku/
    |+common_merlin3/
    |+image_file_creator/
    |+kernel/
    |+system/
    |+venus/

    ```

## GStreamer (GST)
    Applicatoin Program

+ Architecture
    ```
    +----------------------------------------------------------------+
    | application                                                    |
    +----------------------^----------------+---------------+--------+
                           |                | event         | queries
    +----------------------|----------------|---------------|--------+
    | bus                  | message        |               |        |
    |                      ^                |               |        |
    +----------------------|----------------|---------------|--------+
                           |                |               |
    +----------------------|----------------|---------------|--------+
    | pipeline             |                |               |        |
    | +----------+   +-----+-----+   +------V-----+   +-----V-----+  |
    | | file-src |   | ogg-demux |   | vorbis-dec |   | alsa-sink |  |
    | |         src-sink        src-sink         src-sink         |  |
    | +----------+   +-----------+   +------------+   +-----------+  |
    |                            buffer                              |
    +----------------------------------------------------------------+
    ```

    - Definition
        1. GstElement
            > master handler
            >> It is equivalent to *Filter* in DriectShow

            ```
            +-------------+   +-------------+   +-----------+
            | source elem |   | filter elem |   | sink elem |
            |            src-sink          src-sink         |
            +-------------+   +-------------+   +-----------+

            ```

            a. source element
                > only output
            a. filter element
                > both receive and output
            a. sink element
                > only receive

        1. GstPad
            > Connect 2 elements
            >> Data streams from one element's source pad to another element's sink pad.

            a. source pads
                > It is equivalent to *OutputPin* in DriectShow
            a. sink pads
                > It is equivalent to *InputPin* in DriectShow

            a. ghost pad
                > Connect to GstBin

        1. GstCaps
            > Capability (attribute) of a element

        1. GstBin
            > - It is an element subclass and acts as a *Container* for other elements </br>
            >   so that multiple elements can be combined into one element.
            > - A bin can have its own source/sink pads by *ghost pad* one or more of its member's pads to itself.
            > - It is like *FlowManager* in DriectShow

            ```
                +---------------------------+
                | bin                       |
                |    +--------+   +-------+ |
                |    |        |   |       | |
                | ~~sink     src-sink     | |
             sink/   +--------+   +-------+ |
                +---------------------------+
            ```

        1. GstPipeline
            > It is a special sub-set of Bin and usually a toplevel bin and provides all of its members with a clock, </br>
            > it also provides a toplevel GstBus

            >   - member: elements, bins, pads
            >   - privide operator: buffering, event, query, message handle

            ```
            +---------------------------------------------------------------+
            |    ----------> downstream ------------------->                |
            |                                                               |
            | pipeline                                                      |
            | +----------+   +-----------+   +------------+   +-----------+ |
            | | file-src |   | ogg-demux |   | vorbis-dec |   | alsa-sink | |
            | |         src-sink        src-sink         src-sink         | |
            | +----------+   +-----------+   +------------+   +-----------+ |
            |                                                               |
            |    <---------< upstream <-------------------                  |
            +---------------------------------------------------------------+
            ```

    - Inheritance
        ```
                      GObject                                    GstObject
                        |                                            |
            +-----------+--------+---------+----------+       GstPluginFeature
            |           |        |         |          |              |
        GstElement   GstPad    GstBus   GstState   GstClock   GstElementFactory
            |
        GstBin
            |
        GstPipeline

        ```


+ Compile
    ```
    $ cd kernel/native_app/build/
    $ ./build_all.sh
    ```

    - Compile  fail

        1. gst-plugins-cool and omx-il-rtk

            ```
            error: possibly undefined macro: AM_GNU_GETTEXT_VERSION
                If this token and others are legitimate, please use m4_pattern_allow.
                See the autoconf documentation

            or
            error: possibly undefined macro: AC_MSG_ERROR

            or
            error: possibly undefined macro: AC_SUBST

            or
            error: configure: cannot find install-sh, install.sh or shtool ...
            ...


              # cd to kernel/native_app/modulesgst-plugins-cool
              #    or kernel/native_app/omx-il-rtk
            $ autoreconf -if
            $ ./configure
            ```

+ flow
    - glib
        1. dynamic link support
            > `g_module_open()`, `g_module_symbol`

    - plugin register
        > Use *Dynamic link* `*.so` file to get the *Plugin_Description* symbols </br>
        > gstreamer seems to support *static plugin*, but it need to survey

        ```
        gst_init()
            -> gst_init_check()
                -> init_post()
                    -> gst_update_registry()
                        -> ensure_current_registry()
                            -> scan_and_update_registry()
                                -> gst_registry_scan_path_internal()
                                    -> gst_registry_scan_path_level()
                                        -> gst_registry_scan_plugin_file()
                                            -> gst_plugin_load_file()
        ```
        1. init_post()
            > This function may be callback or directly call

        1. scan_and_update_registry()
            > search path priority
            >
            > + `GST_REGISTRY`/`GST_REGISTRY_UPDATE`
            >   > For reducing setup time, gstreamer will record the plugins info at `${HOME}/.cache/gstreamer-1.0/`.
            > + `GST_PLUGIN_PATH`
            >   > your gstreamer path of installed

        1. gst_registry_scan_path_level()
            > Recursively search `*.so` files

        1. gst_registry_scan_plugin_file()/gst_plugin_load_file()
            > Duplicate and register *Plugin_Description* to list
            >> It will record full path of plugin


    - self plugin
        > offical support template

        ```
        $ git clone git://anongit.freedesktop.org/gstreamer/gst-template.git
        $ cd gst-template/gst-plugin/src
        $ ../tools/make_element [your plugin name]

        $ vi gst-template/gst-plugin/src/Makefile.am
        # replace "gstplugin" to "gstXXX"
        ```
        1. instance `plugin_init()`
        1. use c-tamplate `GST_PLUGIN_DEFINE` to declare and extern your *Plugin_Description*
        1. implement features of self plugin

+ gst-rtk-test
    > rtk self player

    ```
    playbin3 +-> dvovidoesink
             +-> rtkalsasink

    ```
    - playbin3 (gst-plugins-base/gst/playback/gstplayback.c)
        > demux and decoder

    - dvovidoesink (gst-plugins-rtk/ext/directvo/gstdvoplugin.c)
        > vframe scheduler, control video frame display/repeat/drop

    - rtkalsasink (gst-plugins-rtk/ext/alsa/gstrtkalsaplugin.c)
        >

+ debug

    - debug message (offical support)
        ```
        $ gst_my_play --gst-debug-level=3
        ```

        1. `--gst-debug-level=LEVEL`
            > LEVEL: 0 ~ 5 (0: no message, 5: all message)

        1. `--gst-debug=LIST`
            > special elements output message with debug level.

            ```
            $ gst_my_play --gst-debug=audiodec:5,avidemux:3
            ```
        1. `--gst-plugin-spew`
            > output error message of loading plugin




## venus
    middleware (HAL layer)

+ compile
    ```
    $ cd venus

    # android build system
    $ source build/envsetup.sh

    # build RealtekTV and use bionic
    $ lunch RealtekTV-userdebug
       Next step... pick a toolchain:
          1. bionic
          2. asdk
       Which would you like? [bionic] 1

    $ make

    # build RealtekSDK and use asdk
    $ lunch RealtekSDK-userdebug
       Next step... pick a toolchain:
          1. bionic
          2. asdk
       Which would you like? [bionic] 2

    $ make
    ```

    - boost
        > + g++ option `-frtti` (Run Time Type Information)
        >   > if you use `-frtti`, all project should enable `-frtti`
        >   > or it will happen run-time error `undefined symbol:` (can't find type info)

+ add executable file
    > use android build system

    - add your LOCAL_MODULE's name for installed
        > `venus/device/realtek/RealtekSDK/device.mk`

    - install prebuild lib
        > every *so* file MUST be declared

        ```
        # Android.mk,
        include $(CLEAR_VARS)                                   # reset env variables
        LOCAL_MODULE := libboost_thread                         # target name (LOCAL_SRC_FILES will be renamed to LOCAL_MODULE after insalled)
        LOCAL_MODULE_TAGS := optional
        LOCAL_MODULE_CLASS := SHARED_LIBRARIES                  # put to out_path/obj/SHARED_LIBRARIES/
        LOCAL_MODULE_SUFFIX := $(TARGET_SHLIB_SUFFIX)           # the suffix of LOCAL_MODULE
        LOCAL_MODULE_PATH := $(PRODUCT_OUT)/system/lib/         # install path
        LOCAL_SRC_FILES := bin/lib/libboost_thread.so.1.57.0    # source path (relative to LOCAL_PATH)
        LOCAL_MULTILIB := 32
        LOCAL_EXPORT_C_INCLUDES := bin/include
        include $(BUILD_PREBUILT)                               # the kind of handling you want

        include $(CLEAR_VARS)
        LOCAL_MODULE := libboost_graph
        LOCAL_MODULE_TAGS := optional
        LOCAL_MODULE_CLASS := SHARED_LIBRARIES
        LOCAL_MODULE_SUFFIX := $(TARGET_SHLIB_SUFFIX)
        LOCAL_MODULE_PATH := $(PRODUCT_OUT)/system/lib/
        LOCAL_SRC_FILES := bin/lib/libboost_graph.so.1.57.0
        LOCAL_MULTILIB := 32
        LOCAL_EXPORT_C_INCLUDES := bin/include
        include $(BUILD_PREBUILT)
        ```

## kernel
    Operation System

+ compile
    ```
    $ make PRJ=develop.rtd287x.tv001.emmc.optee.venus CLEAN_ALL=y FULL_SPEED=y
    ```


