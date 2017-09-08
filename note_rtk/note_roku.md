Merlin3 RoKu
---

## Enviornment

+ dependency libs
    ```
    sudo apt-get instal gettext autopoint automake libtool gtk-doc-tools autoconf glib-2.0
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
                $ autoreconf --install
                $ ./configure
            ```



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

## kernel
    Operation System

+ compile
    ```
    $ make PRJ=develop.rtd287x.tv001.emmc.optee.venus CLEAN_ALL=y FULL_SPEED=y
    ```


