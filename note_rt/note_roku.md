Merlin3 RoKu
---
## misc
+ git
    - Remove untracked
        ```
        $ git clean -xdf
        ```

    - `fatal: Unable to find remote helper for 'https' android`
        > lose git-remote-https

        1. openssl
            ```
            $ wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz
            $ tar -zxf openssl-1.0.2l.tar.gz
            $ cd openssl-1.0.2l
            $ ./config enable-shared --prefix=$HOME/.local/usr
            $ make && make install
            ```

        1. libssh2
            ```
            $ wget https://www.libssh2.org/download/libssh2-1.8.0.tar.gz
            $ tar -zxf libssh2-1.8.0.tar.gz
            $ cd libssh2-1.8.0
            $ ./configure --enable-shared --prefix=$HOME/.local/usr
            $ make && make install
            ```

        1. Expat
            ```
            $ curl -o expat-2.2.4.tar.bz2 https://sourceforge.net/projects/expat/files/expat/2.2.4/expat-2.2.4.tar.bz2/download
            $ tar -jxf expat-2.2.4.tar.bz2
            $ cd expat-2.2.4
            $ ./configure --enable-shared --prefix=$HOME/.local/usr
            $ make && make install
            ```

        1. curl
            ```
            $ wget https://curl.haxx.se/download/curl-7.41.0.tar.gz
            $ tar -zxf curl-7.41.0.tar.gz
            $ cd curl-7.41.0
            $ ./configure --enable-shared --prefix=$HOME/.local/usr
            ```

        1. git
            ```
            $ wget https://www.kernel.org/pub/software/scm/git/git-2.9.5.tar.xz
            $ tar -xJf git-2.9.5.tar.xz
            $ cd git-2.9.5
            $ ./configure --prefix=$HOME/.local/usr --with-curl=$HOME/.local/usr
            $ make && make insall

            # check below libs exist in git-core/
            #   git-remote-http
            #   git-remote-https
            #   git-remote-ftp
            #   git-remote-ftps

              # need to exort private git-core
            export PATH="$PATH:$HOME/.local/usr/libexec/git-core/"
            ```
+ mount
    - re-mount rootfs to r/w
        ```
        $ mount -o rw,remount /
        ```

    - mount usb
        ```
        $ mkdir mnt/usb
        $ mount -v -t auto /dev/sda1 /mnt/usb
        ```

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

+ gcc-5 and gcc-4

    - `libstdc++`
        > A *Dual ABI* is provided by the library in gcc-5.
        >   >  gcc-5 Full support C++11 and the old ABI (gcc-4) still be supported with some tips.

        1. Is it possible for `GCC 5.x` to link with the library compiled by `GCC 4.x`?
            > Yes, the old ABI can be used by defining the macro `_GLIBCXX_USE_CXX11_ABI` to `0`
                before including any C++ standard library headers.


+ cmd line key
    - PCBA
        1. setup env
            ```
            Realtek> env set ethaddr 00:11:22:02:18:93  # MAC address
            ```
        1. enable eth0
            ```
            / # ifconfig eth0 hw ether 00:11:22:02:18:93  # if bootload set MAC address not work

            / # ifconfig eth0 up ; udhcpc -i eth0 -s /etc/udhcpc.script
            ```
    - PC
        1. connect to PCBA
            ```
            telnet board_ip  port:8080

            [message]
            13A14C999999 (Roku player - 13A14C999999 - 9.0.0.99999)
            >
            ```
        1. cmd `press`
            > virtual key

            ```
            option:
            >press
            h          Home
            u          Up
            d          Down
            r          Right
            l          Left
            s          Select
            f,>        Fwd
            b,<        Rev
            p          Play
            y          InstantReplay
            i          Info
            k          Back
            =          Backspace
            o          PlayOnly
            t          Stop
            e          Enter
            a          A
            c          B
            n          Closed Caption
            g          Game
            j          Sleep
            ?          Search
            [          Volume Down
            ]          Volume Up
            \          Volume Mute
            ~          Input Source
            *1234vt    Input HDMI1-4, AV, Tuner
            ^          Guide
            x1-x60     Partner1 - Partner60
            !          Power
            @          PowerOn
            #          PowerOff
            .ibmfwrec  change source type: i=IR,b=BT,m=MHL,f=FP,
                                           w=WD(Wifi),r=IR_RF(T3),
                                           e=ECP,c=CEC,
                                           u=IR_RF_UNPAIRED
                                           The default is IR

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

    ```
    # x86 dependency libs
    $ sudo apt-get install libogg-dev libopus-dev libtheora-dev liborc-dev
    ```

+ definition
    - system time clock (STC)
        > usually 90KHz

    - base time
        > start time of playing

    - stream time
        > media file contect duration (fix)

    - running time (float)
        > playing duration, Forward/Backward/Play/Pause will impact it

        ```
        running time = STC - base_time
        ```
    - preroll
        > pre-decode bit stream to raw data

    - buffering
        > queue the bit stream

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
            +-------------+ ^ +-------------+   +-----------+
                            |
                     view-point of pad (src/sink)

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
            > Base class and element that can contain other elements (Container)

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
            > Top-level bin with *clocking* and *bus management* functionality.

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

        1. GstBus
            > Asynchronous message bus subsystem
            >> Message Manager between elements

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
        1. Parent Object -> take care interface
        1. Child Object  -> take care private attributes/methods

        1. [Object Hierarchy] (https://gstreamer.freedesktop.org/data/doc/gstreamer/head/gstreamer/html/index.html)
            ```
            GObject
            ╰── GInitiallyUnowned
                ╰── GstObject
                    ├── GstAllocator
                    ├── GstPad
                    │   ╰── GstProxyPad
                    │       ╰── GstGhostPad
                    ├── GstPadTemplate
                    ├── GstPluginFeature
                    │   ├── GstElementFactory
                    │   ├── GstTracerFactory
                    │   ├── GstTypeFindFactory
                    │   ├── GstDeviceProviderFactory
                    │   ╰── GstDynamicTypeFactory
                    ├── GstElement
                    │   ╰── GstBin
                    │       ╰── GstPipeline
                    ├── GstBus
                    ├── GstTask
                    ├── GstTaskPool
                    ├── GstClock
                    │   ╰── GstSystemClock
                    ├── GstControlBinding
                    ├── GstControlSource
                    ├── GstPlugin
                    ├── GstRegistry
                    ├── GstBufferPool
                    ├── GstTracer
                    ╰── GstTracerRecord


            GInterface
            ├── GstChildProxy
            ├── GstURIHandler
            ├── GstPreset
            ╰── GstTagSetter


            GBoxed
            ├── GstMemory
            ├── GstQuery
            ├── GstStructure
            ├── GstCaps
            ├── GstCapsFeatures
            ├── GstMessage
            ├── GstEvent
            ├── GstBuffer
            ├── GstBufferList
            ├── GstSample
            ├── GstContext
            ├── GstDateTime
            ├── GstTagList
            ├── GstSegment
            ├── GstAllocationParams
            ├── GstToc
            ├── GstTocEntry
            ╰── GstParseContext

            ```

    - concept
        1. A element has many handles and a handle may have sub-handles.
            > e.g. GstPad srcpads/sinkpads, GstBus bus, GstClock clock, ...etc.
        1. Every handle maps to spacial interface
            > e.g. GstPad => gst_pad_xxx(), GstBus => gst_bus_xxx()
        1. Every interface link to target method
            ```
                                        gst_base_src_query()
            interfacd gst_pad_query() --------------------------> gst_video_test_src_query()
            ```

        1. Create object
            a. first, create parent object and fill attributes/methods
            a. Then, create child object and override attributes/methods or not

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
    - glib-2
        1. dynamic link support
            > `g_module_open()`, `g_module_symbol`

        1. create a object
            a. `static void gst_XXX_class_init()`
                > Declare members of this object

            a. `static void gst_XXX_init()`
                > the constructor of this object
        1. signal
            a. g_signal_new(signal_name, ...)
                > Create a signal with *signal_name* and return *signal id*
            a. g_signal_connect(target_handle, signal_name, callback_routing, usrdata)
                > Link the *callback_routing* to the *signal_name* in the *target_handle*
            a. g_signal_emit(target_handle, signal_id, args...)
                > Emit the *signal_id* to *target_handle* with *args*


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


    - plugin concept
        ```
        GObject
        ╰── GInitiallyUnowned
            ╰── GstObject
                ╰── GstPluginFeature
                    ╰── GstElementFactory
        ```

        1. A plugin (*so* file) owns a `gst_plugin_dest` as a enter pointer.
        1. Use `gst_plugin_dest->plugin_init()` to check multi-elements in this plugin.
        1. Every element use `gst_element_register()` to register element *Name* and *descriptor*

        1. definition
            a. *GstRegistry*
                > Abstract base class for management of GstPlugin objects </br>
                > It records registered plugins by GstPlugin and GstPluginFeature.

            a. *GstPlugin*
                > Container for features loaded from a shared object module (.so)

            a. *GstPluginFeature*
                > Base class for contents of a GstPlugin

            a. *GstElementFactory*
                > A factory which create special GstElements

            a. *GstElement*
                > Abstract base class for all pipeline elements

        1. flow
            ```
            gst_plugin_load_file()
                -> gst_plugin_register_func()
                    -> plugin_init()
            ```

            a. gst_plugin_load_file()
                > + Search plugin description from *so* file
                > + Create a plugin object (handle: hPlugin)
                > + Assine attributes of hPlugin (follow plugin description)
                > + call `gst_plugin_register_func()`

            a. gst_plugin_register_func()
                > + Authenticate the attributes of hPlugin
                > + call `plugin_init()` to initial this plugin (*so* file)

            a. plugin_init()
                > Common interface in each plugin (*so* file).
                >   > Actually, it call `gst_element_register()` to assine descriptors of elements/bins to hPlugin.

            a. gst_element_register()
                > Every inherits from `GstElement` can use this function

                ```
                GObject
                ╰── GInitiallyUnowned
                    ╰── GstObject
                        ╰── GstElement
                            ╰── GstBin
                                ╰── GstPipeline
                ```

    - pad
        > Pre-process the data stream, e.g. buffering, alignment, re-order byte, ..., etc.
        > + static or always pad `GST_PAD_AWAYS`
        >   > appended when construction (always exist)
        >
        > + Dynamic or sometimes pads
        >   > run-time append, e.g. demux
        >
        > + Request pads
        >   > manually add (feature enable/disable), e.g. streaming and capturing (element_tee)

        1. GstPadTemplate
            > Describe the media base type of a pad.
            > + When create a element, </br>
            >   we declare this members of element object in `static void gst_XXX_class_init()`, </br>
            >   which will register pads base on GstPadTemplate
            >
            >   > - `gst_element_class_add_static_pad_template()`
            >   >   > 1. create a `GstPadTemplate`
            >   >   > 1. assine attributes following `struct GstStaticPadTemplate`
            >   >   > 1. append `GstPadTemplate` to *pad list* of this element
            >
            > + You can define the self capabilities (struct GstStaticPadTemplate) and assine to GstPadTemplate
            >

        1. Caps Negotiation
            > When link 2 elements, need to negotiate the capabilities of pads between elements.

            a. up-stream trigger down-stream
            a. elem_1 query elem_2 and elem_2 report the caps
            a. elem_1 accepta cap (fixed_caps) and post to elem_2
            a. elem_2 notify yes
            a. elem_1 push event (ready to receive) to elem_2
            a. elem_1 start trasmision


            ```
                            up -----> down stream

                element_1                                                        element_2
                    |   gst_pad_peer_query_caps(srcpad, filter)                     |
                    +--------------------------------------------->                 |
                    |                                                caps           |
                    |            <------------------------------------------------- +
                    |   gst_pad_peer_accept_caps(srcpad, fixed_caps)                |
            srcpad  +----------------------------------------->                     | sinkpad
                    |                                                 yes           |
                    |              <------------------------------------------------+
                    |   gst_pad_push_event(srcpad, gst_event_new_caps(fixed_caps))  |
                    +----------------------------------------->                     |
                    |   transmit data                                               |
                    +----------------------------------------->                     |
            ```

        1. Re-configure
            > `GST_EVENT_RECONFIGURE` event is used to re-negotiate from down-stream

            a. down-stream trigger up-stream re-negotiation
            a. elem_2 push event `GST_EVENT_RECONFIGURE` to elem_1
            a. elem_1 re-query capabilities
            a. elem_2 only repot fixed_caps
            a. elem_1 push event (ready to receive) to elem_2 and start transmition

            ```
                            up -----> down stream

                element_1                                                        element_2
                    |              gst_pad_peer_accept_caps(sinkpad, fixed_caps)    |
                    |          <----------------------------------------------------+
                    |   yes                                                         |
                    +--------------------------------------------->                 |
                    |    gst_pad_push_event(srcpad, gst_event_new_reconfigure())    |
            srcpad  |          <----------------------------------------------------+ sinkpad
                    |                                                               |
                    |   gst_pad_peer_query_caps(srcpad, filter)                     |
                    +--------------------------------------------->                 |
                    |                                                fixed_caps     |
                    |            <------------------------------------------------- +
                    |                                                               |
                    |   gst_pad_push_event(srcpad, gst_event_new_caps(fixed_caps))  |
                    +----------------------------------------->                     |
                    |   transmit data                                               |
                    +----------------------------------------->                     |
            ```

        1. chain and queue
            > push mode: gst_XXX_chain </br>
            > pull mode: gst_XXX_loop

            a. PUSH mode
                ```
                gst_pad_push()      # src pad of the element at up-stream
                    -> (*chainfunc)()   # element (down-stream) support chain fucnion and attach to sink pad
                        -> element handle data, e.g. dumuxing, parsing, ...etc.
                ```

                i. gst_pad_push()
                    > src pad of element at up-stream push data (GstBuffer format) with gst_pad_push()
                    >> gst_pad_push() will call `chainfunc()`, which support from element of down-stream and attach to sink pad

                i. chainfunc()
                    > pre-process data (GstBuffer), e.g. parsing GstBuffer format, buffering, ...etc.

                    ```
                    file src pad gst_pad_push()
                        -> gst_xxx_demux_chain()    # chainfunc
                            -> gst_xxx_parse()
                                -> dumux src pad gst_pad_push()
                                    -> gst_xxx_dec_handle_frame()   # element_decoder
                                        or
                                    -> gst_xxx_decoder_chain()


                    gst_xxx_decoder_chain()
                        -> gst_xxx_decoder_sink_setcaps()
                            -> (*set_format)()      # notify the H/W module (subclass) data format
                            -> (*handle_frame)()    # notify the H/W module (subclass) to work

                    ```

            a. PULL mode

                i. gst_pad_pull_range()

                ```
                demux chang state
                    -> gst_pad_start_task()
                        -> gst_xxx_loop()
                            -> gst_pad_pull_range()  # get GstBuffer from file src pad at up-stream
                                -> gst_xxx_parse()
                                    -> demux src pad gst_pad_push()
                                        -> gst_xxx_dec_handle_frame()   # element_decoder

                gst_xxx_loop()
                    -> gst_xxx_get_range()
                        -> (create)()


                ```
    - events
        1. gst_xxx_sink_event()
            > sink receive events from up-stream

        1. gst_xxx_src_event()
            > src receive events from down-stream

    - decoder (gstaudiodecoder.c/gstvideodecoder.c )
        > Interface of decoder for gstreamer core system

        ```
                            +--------------------+
                            | gstaudiodecoder    |              OutSink
            +---------+     | gstvideodecoder    |           +-----------+
            | demuxer | --> |                    |           | videosink |
            +---------+     | +----------------+ | --------> | audiosink |
                            | | CODEC          | |           +-----------+
                            | | - H/W module   | |
                            | | - ffmpeg       | |
                            | +----------------+ |
                            +--------------------+

        ```
        1. general case
            a. demuxer      : src pad gst_pad_push()
            a. gst decoder  : gst_audio_decoder_chain() receive GstBuffer from *demuxer*
            a. gst decoder  : gst_audio_decoder_sink_setcaps()
            a. gst decoder  : (*set_format)() to *CODEC*
            a. CODEC        : setup codec format
            a. gst decoder  : (*handle_frame)() to *CODEC*
            a. CODEC        : gst_audio_decoder_set_output_format() to *gst decoder*
            a. CODEC        : gst_audio_decoder_negotiate() to *gst decoder*
            a. gst decoder  : gst_pad_set_caps()/ GST_EVENT_CAPS to *OutSink*
            a. gst decoder  : gst_query_new_allocation() to *OutSink*
            a. OutSink      : report allocator to *gst decoder*
            a. CODEC        : gst_audio_decoder_allocate_output_buffer() to *gst decoder*
            a. gst decoder  : report GstBuffer to *CODEC*
            a. CODEC        : decode bit stream and put decoded data into GstBuffer
            a. CODEC        : gst_audio_decoder_finish_frame() to *gst decoder*
            a. gst decoder  : src pad gst_pad_push() to *OutSink*

        1. omx case
            > omx define self component state
            >> H/W module will link to libomx_core.so (venus/hardware/realtek/omx-il-rtk/). </br>
            >> Actually, libomx_core.so implement rpc between Host and CODEC processor


            ```
            +---------------------------------------+
            | gstaudiodecoder/ gstvideodecoder      |
            |                                       |
            | +-----------------------------------+ |
            | | CODEC gstomx                      | |
            | |  - GstOMXAudioDec                 | |
            | |  - GstOMXVideoDec                 | |
            | |                                   | |
            | |  +----------------------------+   | |
            | |  | Audio/ Video container     |   | |
            | |  |                            |   | |
            | |  | - GstOMXAACDec             |   | |
            | |  | - GstOMXMP3Dec             |   | |
            | |  | - GstOMXH264Dec            |   | |
            | |  | - GstOMXH265Dec            |   | |
            | |  |                            |   | |
            | |  | +-----------------+        |   | |
            | |  | | OMX components  |        |   | |
            | |  | | real H/W module |        |   | |
            | |  | +-----------------+        |   | |
            | |  +----------------------------+   | |
            | +-----------------------------------+ |
            +---------------------------------------+

            ```

            a. gst decoder  : (*set_format)() to *CODEC (gstomx)*
            a. CODEC        : setup codec format
                > e. gstmox           : pass to *GstOMXAudioDec*
                > e. GstOMXAudioDec   : gst_omx_acc_dec_set_format() to *GstOMXAACDec*
                > e. GstOMXAACDec     : OMX_IndexParamAudioAac() to *H/W module*
                > e. GstOMXAudioDec   : change OMX state OMX_StateLoaded to OMX_StateIdle
                > e. GstOMXAudioDec   : gst_omx_port_allocate_buffers() to *H/W module*
                > e. H/W module       : report OMX_CommandStateSet is OMX_StateIdle
                > e. GstOMXAudioDec   : change OMX state OMX_StateIdle to OMX_StateExecuting
                > e. H/W module       : report OMX_CommandStateSet is OMX_StateExecuting


            a. gst decoder  : (*handle_frame)() to *CODEC (gstomx)*
                > e. gstmox                 : pass to *GstOMXAudioDec*
                > a. GstOMXAudioDec         : gst_pad_start_task() with `gst_omx_audio_dec_loop()`
                > a. gst_omx_audio_dec_loop : send an empty buffer to an output port of *H/W module* with `OMX_FillThisBuffer()`
                > a. GstOMXAudioDec         : launch H/W module with `OMX_EmptyThisBuffer()`
                > a. gst_omx_audio_dec_loop : wait for `OMX_FillThisBufferDone`


+ source codes
    > basic request gstreamer/gst-plugins-base/gst-plugins-good
        ```
          # look up plugins
        $ gst-ispect-1.0

          # simple test tone
        $ gst-launch-1.0 -vm audiotestsrc ! autoaudiosink

          # work but can't see anything ....(Need to install gst-libav)
        $ gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink

        $ gst-launch-1.0 filesrc location="test.mp3" ! decodebin ! autoaudiosink

        $ gst-launch-1.0.exe -v playbin3 uri=file:///home/xxx/splitvideo01.ogg
        ```

    - gstreamer-1.12.3

        ```
        ├── gst             # master core, and instance element factory
        ├── libs            # parent class of elements
        ├── plugins         # plugin architecture and support basic plugins
        ├── po              # multi-language
        ├── tests           # unit test
        ├── tools           # application program
        ```


    - gst-plugins-base-1.12.3
        ```
        ├── ext             # elements depend on thire-party libs
        ├── gst             # API suppored by plugin base
        ├── gst-libs        # parent class of elements
        ├── po              # multi-language
        ├── sys             # elements depend on system
        ├── tests           # unit test
        ├── tools           # application program
        ```

        - playback
            1. Inheritance
                ```
                bin (parent)
                -> pipeline
                    -> playbasebin
                        -> playbin
                ```

            1. *playbin *
                > stable
                >> `gstplaybin.c`
                >> `gstplaybasebin.c`
                >> `gstdecodebin.c`
                >> `gststreaminfo.c`
                >> `gststreamselector.c`
                >> `gstplaymarshal.c`

            1. *playbin2*
                > stable
                >> `gstplaybin2.c`
                >> `gstplaysink.c`
                >> `gstdecodebin2.c`

            1. *playbin3*
                >
                >> `gstplaybin3.c`
                >> `gstplaysink.c`
                >> `gstdecodebin3.c`
                >> `gstdecodebin3-parse.c`

    - gst-plugins-good-1.12.3
        ```
        ├── ext
        ├── gst
        ├── gst-libs
        ├── sys
        └── tests
        ```
+ proprietary directory
    ```
    gst-omx-rtk (codec interface for gstreamer) ---------> gst-plugins-rtk (Sink elements, e.g. DirectVO)
            |                                                     |
            +------+                         +--------------------+
                   |                         |
                   v                         v
                omx_il_rtk (communicate with VideoFirmware, RPC)
                                    |
                                    v
                                Video Processor (H/W)
    ```

+ DirectVO
    > include
    > + gstdvovideosink.c
    >       > link with gstreamer
    > + gstdvocontext.c
    >       > support DirectVO API for user
    > + gstdvobufferpool.c
    >       > GstBuffer pool handle
    > + gstdvobuffermeta.c
    >       > record physical address of buffer and be included in GstBuffer

    -
        ```
        gst_omx_video_dec_set_format() in gstomxvideodec.c
            -> gst_omx_video_dec_reconfigure_output_port()
                -> gst_omx_video_dec_allocate_output_buffers()
                    -> gst_buffer_pool_acquire_buffer()
                        -> dvo_buffer_pool_acquire_buffer()  in gstdvobufferpool.c
        ```

    - play flow

        ```
        gst_omx_video_dec_loop() in gstomxvideodec.c
            -> gst_omx_video_dec_reconfigure_output_port()
                -> -> gst_omx_video_dec_allocate_output_buffers()
        ```


+ gst-rtk-test
    > rtk self player

    ```
    playbin3 +-> dvovidoesink
             +-> rtkalsasink

      shell
    $ gst-rtk-test-1.0 -p -f [file]

    ```
    - playbin3 (gst-plugins-base/gst/playback/gstplayback3.c)

        1. There are 3 units, GstUriSourceBin, GstDecodeBin3, GstPlaySink.
        1. GstPlaySink
            > Process audio/video *frame data* and output to device

            ```
            gst_play_bin3_init()
                -> g_object_new(playsink)
                -> gst_bin_add(playbin, playsink)
            ```

        1. GstDecodeBin3
            > Decode bit streams of audio/video

            ```
            gst_play_bin3_change_state()
                -> setup_next_source()
                    -> activate_decodebin()     # create decodebin3
                        -> make_or_reuse_element()
                            -> gst_element_factory_make(decodebin3)
            ```

        1. GstUriSourceBin
            > Process input module, it uses URI to detect input protocol, e.g. `file://`, `rtsp://`

            ```
            gst_play_bin3_change_state()
                -> setup_next_source()
                    -> activate_group()
                        -> make_or_reuse_element()
                            -> gst_element_factory_make(urisourcebin)
            ```
        1. flow
            a. *playbin3*   : constructor create and add *PlaySink*
                > + connnect signal callback from *PlaySink* to *playbin3*
                >   - notify::volume
                >   - notify::mute
                >   - value-changed

            a. *PlaySink*   : create and add *StreamSynchronizer*

            a. *playbin3*   : change state
                > + Create *DecodeBin3*
                > + Create *UriSourceBin*

                g. *DecodeBin3* :
                    > + constructor create and add *MultiQueue*
                    > + connnect signal callback from *DecodeBin3* to *playbin3*
                    >   - pad-added: Be triggered when a pad add to decodebin3
                    >   - pad-removed
                    >   - no-more-pads
                    >   - select-stream
                    > + set state of elements in *DecodeBin3*
                    >
                    >
                    >
                    > + `gst_decodebin3_input_pad_link()`: link function of sinkpad of *DecodeBin3*
                    >   - `ensure_input_parsebin()`: create *Parsebin*
                    > + create *Parsebin*: `ensure_input_parsebin()` in gstdecodebin3.c
                    >   - constructor create and add *Typefind*
                    >       1. create a *ghost sink pad* with sinkpad of *Typefind*
                    >       1. add *ghost sink pad* to *Parsebin*
                    >   - connnect signal callback from *Parsebin* to *DecodeBin3*
                    >       1. pad-added: Be triggered when a pad add to urisourcebin
                    >       1. pad-removed
                    >       1. autoplug-continue
                    >   - add *Parsebin* to *DecodeBin3*
                    >   - change state of elements in *Parsebin*
                    >       1. `gst_element_sync_state_with_parent()`
                    >       1. `gst_parse_bin_change_state()`
                    >           a. connnect signal callback from *Typefind* to *Parsebin*
                    >               > have-type: `type_found()` in gsturisourcebin.c
                    >       1. `parent_class->change_state()`: `gst_bin_change_state_func()` iterate change element state in *Parsebin*
                    >       1. `gst_type_find_element_change_state()`
                    >       1. `gst_element_pads_activate()`
                    >       1. `gst_type_find_element_activate_sink`: create task `gst_type_find_element_loop()`
                    >   - `gst_type_find_element_loop()`
                    >       1. search element with *file extension*
                    >       1. `gst_type_find_element_emit_have_type()`: signal trigger *have-type* to `type_found()` in *Parsebin*
                    >   - `type_found()` in gstparsebin.c
                    >       1. `analyze_new_pad()`
                    >       1. `connect_pad()`
                    >           a. create demuxer_element_factory, e.g. oggdemux
                    >           a. add demuxer_element_factory to *Parsebin*
                    >           a. set element *oggdemux* state to *GST_STATE_READY*
                    >           a. `connect_element()`: check srcpads of demuxer element
                    >           a. set element *oggdemux* state to *GST_STATE_PAUSED*
                    >               > + `gst_ogg_demux_change_state()`
                    >               > + `gst_pad_set_active()`
                    >               > + `gst_ogg_demux_sink_activate()`
                    >               > + `gst_ogg_demux_sink_activate_mode()`: create task `gst_ogg_demux_loop()`
                    >       1. `connect_element()`
                    >           a. find the *src pads* in demuxer
                    >           a. check the type of *src pads* (Always/Dynamic pad)
                    >           a. if dynamic pad, connnect signal callback from *oggdemux* to *Parsebin*
                    >               > + pad-added: Be triggered when a pad add to *oggdemux*
                    >               > + pad-removed
                    >               > + no-more-pads
                    >

                g. *UriSourceBin*
                    > + connnect signal callback from *UriSourceBin* to *playbin3*
                    >   - pad-added: Be triggered when a pad add to urisourcebin
                    >   - pad-removed
                    >   - notify::source
                    >   - autoplug-factories
                    >   - autoplug-select
                    >   - autoplug-continue
                    >   - autoplug-query
                    > + set state of elements in *UriSourceBin*
                    >   - parse uri: `gen_source_element()` in gsturisourcebin.c
                    >   - create element_source, e.g. GstFileSre (with uri=file://)
                    >   - create *TypeFind* (GstTypeFindElement): `setup_typefind()` in gsturisourcebin.c
                    >       1. connnect signal callback from *TypeFind* to *UriSourceBin*
                    >           a. have-type: `type_found()` in gsturisourcebin.c
                    >       1. change *TypeFind* state
                    >           a. `gst_element_sync_state_with_parent()`
                    >           a. `gst_type_find_element_change_state()`
                    >           a. `gst_element_pads_activate()`
                    >           a. `gst_type_find_element_activate_sink`: create task `gst_type_find_element_loop()`
                    >   - `gst_type_find_element_loop()`
                    >       1. search element with *file extension*
                    >       1. `gst_type_find_element_emit_have_type()`: signal trigger *have-type* to `type_found()` in *UriSourceBin*
                    >   - `type_found()` in gsturisourcebin.c
                    >       1. `create_output_pad()`: create a ghost src pad of *UriSourceBin*
                    >       1. `expose_output_pad()`: Add ghost src pad to *UriSourceBin*
                    >                                 and signal trigger *pad-added* to `urisrc_pad_added()`in *playbin3*
                    >   - `urisrc_pad_added()` in *playbin3*
                    >       1. `gst_pad_link()`: link decodebin3->sinkpad to urisourcebin->ghost_src_pad
                    >                            and callback to *link func* `gst_decodebin3_input_pad_link()`
                    >                            of sinkpad (decodebin3->sinkpad)



        1. uriourcebin -> typefind -> gst_type_find_element_loop()
            > search support *srcpad* with input *file extension* </br>
            > and signal (trigger) to urisourcebin `type_found()`

        1. urisourcebin -> `type_found()` handle srcpad
            and signal to decodebin3 `gst_decodebin3_input_pad_link()`

        1. decodebin3 -> `gst_decodebin3_input_pad_link()`  create parsebin

        1. when change state, parsebin -> typefind -> gst_type_find_element_loop()
            > search supporting *sinkpad* with *srcpad* and
            > signal (trigger) to parsebin `type_found()`
        1. parsebin `type_found()` create *demuxer* and
            change *demuxer* state

        1. *demuxer* `gst_ogg_demux_loop` push data to `gst_multi_queue_chain()`
        1. *multiqueue* `gst_multi_queue_loop()` push data to *videodecoder* `gst_video_decoder_chain()`
        1. `gst_video_decoder_chain()` -> `gst_video_decoder_decode_frame()` ->  `decoder_class->handle_frame()`


        ```
                   bin ----+
                    ^      |
                    |      |
                pipeline   |
                    ^      |
                    |      |
        app -> playbin3    |
                           |
        +------------------+
        |   +------------------------------------------------------------------------------------------------------------------------+
        |   |  +-----------------------------------------+                                                                           |
        |   |  | GstUriSourceBin                         |                                                                           |
        |   |  |                                         |                                                                           |
        |   |  |      bin -------+                       |                                                                           |
        |   |  |      ^          |                       |               +--------------------------------------------------------+  |
        |   |  |      |          |    (follow file ext)  |               | GstPlaySink                                            |  |
        +---+---->  uriourcebin  +--> typefind           |               |                                                        |  |
        |   |  |     ^                   +-> srcpad----->\-              |    element (record the bin state after iterate)        |  |
        |   |  |     | add                               |               |      ^                                                 |  |
        |   |  |   filesrc (follow uri prefix)           |               |      |                                                 |  |
        |   |  |     |                                   |               |      |   Iteratively contrel                           |  |
        |   |  |     v                                   |               |     bin ----------------------+     element            |  |
        |   |  |   basesrc                               |               |      ^                        |        ^               |  |
        |   |  +-----------------------------------------+               |      |                        |        |               |  |
        +---+---------------------------------------------------------------> playsink                    +--> streamsynchronizer -->|
        |   |  +-----------------------------------------------------+   |                                             ^          |  |
        |   |  | GstDecodeBin3                                       |   +---------------------------------------------\----------+  |
        |   |  |                                                     |                                                 |             |
        |   |  |   +----------------------------------------------+  |                                                 |             |
        |   |  |   |     bin -----+                               |  |                                                 |             |
        |   |  |   |      ^       |                               |  |                                                 |             |
        |   |  |   |      |       |                               |  |                                                 |             |
        |   |  |   |   parsebin   +--> typefind --> oggdemux      |  |                                                 |             |
        |   |  |   /<----------- sinkpad +            + srcpad -->\  |                                                 |             |
        |   |  |   |                                              |  |                                                 |             |
        |   |  |   +----|-----------------------------------------+  |                                                 |             |
        |   |  |        |                                            |                                                 |             |
        |   |  |        v                    +                       |                                                 |             |
        |   |  |                             +--------> theoradec --->/------------------------------------------------+             |
        +---+-----> decodebin3   +--> multi-queue          |         |                                                               |
            |  |        |        |                         v         |                                                               |
            |  |        v        |                    videodeocder   |                                                               |
            |  |       bin ------+                                   |                                                               |
            |  |                                                     |                                                               |
            |  +-----------------------------------------------------+                                                               |
            |                                                                                                                        |
            +------------------------------------------------------------------------------------------------------------------------+


        setup_next_source()
            -> activate_decodebin()     # create decodebin3
                -> make_or_reuse_element()
                    -> gst_element_factory_make(decodebin3)

            -> activate_group()         # create a/v/text sink
                -> make_or_reuse_element()
                    -> gst_element_factory_make(urisourcebin)

                -> gst_element_set_state(urisourcebin)
                    -> setup_source()
                        -> setup_typefind()
                            -> gst_element_factory_make(typefind)  # create element typefind
                                # gst_type_find_element_activate_sink() will create a task 'gst_type_find_element_loop()'

        ```

        > demux and decoder

        > + *decodebin3*
        >   > Process bit stream, e.g. demuxing, CODEC parsing/decoding
        >   >   > Add element multiqueue when construct.

        > + *playsink*
        >   > Process frame data of A/V/Text, e.g. A/V sync, image/tone tuning
        >   >    > Add element streamsynchronizer when construct.

        > + *urisourcebin*
        >   > A bin element for accessing URIs in a uniform manner.
        >
        >   - element *typefind*
        >       > Determines the media-type of a stream and set it's src pad caps to this media-type
        >
        >       1. when activate_pads `gst_type_find_element_activate_sink()`, it will create a task `gst_type_find_element_loop()`
        >           > `gst_type_find_element_loop()` will compare the *file extension* and the supported caps of pads </br>
        >           > and emit signal `have-type` to notify *urisourcebin*
        >
        >       1. If get the mapping caps of pad, `gst_type_find_element_loop()` will pull data from file `gst_pad_pull_range()`.



        1. gst_bin_change_state_func()
            > *Instance* of bin change state

            ```
            gst_bin_change_state_func()
                -> gst_bin_element_set_state()
            ```

        1. gst_bin_element_set_state()
            > *Interface* of method of a bin element </br>
            > Iteratively, Set state to all elements in a Bin.

            ```
            gst_bin_element_set_state()
                -> gst_element_set_state()
                -> (*change_state)()
                    # gst_element_change_state_func()
            ```

        1. gst_element_set_state()
            > *Interface* of method of an element

            ```
            gst_element_set_state()
                -> (*set_state)()
                    # gst_element_set_state_func()
                        -> gst_element_change_state()
            ```

        1. gst_element_set_state_func()
            > *Instance* of set state.

        1. gst_element_change_state()
            > *Interface* of method of an element and check state finish or not
            > + if state finish => return
            > + if state continue => `gst_element_continue_state()`

            ```
            gst_element_change_state()
                -> (*change_state)()
                    # gst_element_change_state_func() or
                    # gst_bin_change_state_func()
            ```

        1. gst_element_change_state_func()
            > *Instance* of change state
            > + control state machine
            > + activate pads `gst_element_pads_activate()`



    - dvovidoesink (gst-plugins-rtk/ext/directvo/gstdvoplugin.c)
        > vframe scheduler, control video frame display/repeat/drop

    - rtkalsasink (gst-plugins-rtk/ext/alsa/gstrtkalsaplugin.c)
        >

+ debug

    - [environment variables] (https://gstreamer.freedesktop.org/data/doc/gstreamer/head/gstreamer/html/gst-running.html)
        1. `GST_PLUGIN_PATH`, `GST_PLUGIN_PATH_1_0`
            > search path for plugins, `GST_PLUGIN_PATH_1_0` will override `GST_PLUGIN_PATH` if `GST_PLUGIN_PATH_1_0` is set

        1. `GST_DEBUG`
            > show log by level

            ```
            $ export GST_DEBUG=[element name 1]:[level],[element name 2]:[level]...
            ```

        1. `GST_DEBUG_COLOR_MODE`
            > set log message with color or not

            ```
            $ export GST_DEBUG_COLOR_MODE=on
            $ export GST_DEBUG_COLOR_MODE=off
            ```
        1. `GST_DEBUG_DUMP_DOT_DIR`
            > enable output dot files for graphviz

        1. `GST_REGISTRY', 'GST_REGISTRY_1_0`
            > search cache file of plugins

        1. `GST_REGISTRY_UPDATE`
            > force update cache of plugins

            ```
            export GST_REGISTRY_UPDATE=no
            export GST_REGISTRY_UPDATE=yes
            ```

        1. `GST_DEBUG_FILE`
            > re-direct debug message to file

        1. `GST_TRACE`
            > Enable memory allocation tracing

            ```
            export GST_TRACE=all
            export GST_TRACE=live       # Counts all live objects and dumps an overview of the number of unfreed objects
            export GST_TRACE=mem-live   # Keep track of the unfreed memory pointers and dump an overview of all unfreed memory
            ```

    - debug message (offical support)
        ```
        $ gst_my_play --gst-debug-level=4
        ```

        1. `--gst-debug-level=LEVEL`
            > LEVEL: 0 ~ 7 (0: no message, 7: all message)

            a. ERROR= 1
                > Logs all fatal errors. These are errors that do not allow the core or elements to perform the requested action.
                > The application can still recover if programmed to handle the conditions that triggered the error.
            a. WARNING= 2
                > Logs all warnings. Typically these are non-fatal, but user-visible problems are expected to happen.
            a. FIXME= 3
                > Logs all fixme messages.
                > Fixme messages are messages that indicate that something in the executed code path
                > is not fully implemented or handled yet.
                > The purpose of this message is to make it easier to spot incomplete/unfinished pieces of code when reading the debug log.
            a. INFO= 4
                > Logs all informational messages.
                > These are typically used for events in the system that only happen once,
                > or are important and rare enough to be logged at this level.
            a. DEBUG= 5
                > Logs all debug messages.
                > These are general debug messages for events that happen only a limited number of times
                > during an object's lifetime; these include setup, teardown, change of parameters, ...
            a. LOG= 6
                > Logs all log messages.
                > These are messages for events that happen repeatedly during an object's lifetime;
                > these include streaming and steady-state conditions.
            a. TRACE= 7
                > Logs all trace messages.
                > These messages for events that happen repeatedly during an object's lifetime such as the ref/unref cycles.
            a. MEMDUMP= 9
                > Log all memory dump messages.
                > Memory dump messages are used to log (small) chunks of data as memory dumps in the log.
                > They will be displayed as hexdump with ASCII characters.

        1. `--gst-debug=[element name]:[level]`
            > special elements output message with debug level.

            ```
            $ gst_my_play --gst-debug=audiodec:5,avidemux:3
            ```
        1. `--gst-plugin-spew`
            > output error message of loading plugin

    - graphviz
        1. need lib
            ```
            $ sudo apt-get install graphviz
            ```
        1. enable dot dump
            ```
            $ export GST_DEBUG_DUMP_DOT_DIR=~/dot_path/
            ```

        1. run program
            ```
            $ gst-launch audiotestsrc num-buffers=1000 ! fakesink sync=false
            ```

        1. conve to png

            ```
            #!/bin/bash

            set -e

            DOT_FILES_DIR="~/dot_path/"
            PNG_FILES_DIR=$DOT_FILES_DIR

            DOT_FILES=$(ls $DOT_FILES_DIR | grep dot)

            for dot_file in $DOT_FILES
            do
              png_file=$(echo $dot_file | sed s/.dot/.png/)
              dot -Tpng $DOT_FILES_DIR/$dot_file > $PNG_FILES_DIR/$png_file
            done

            ```

    - memory leak check
        1. enable debug message about *GST_BUFFER*
            ```
            export GST_DEBUG=GST_BUFFER:5
            ```

        1. find create buffer function *gst_buffer_init()* and save to file 1
            ```
            $ grep gst_buffer_init logfile | cut -d'x' -f 3 | sort | uniq -c > 1
            $ cat 1
            # allocate/release times    address
                1823                    143f518
                1824                    143f570
                 682                    143f780
                 682                    145e808
                   2                    145e980
            ```

        1. find destroy buffer function *gst_buffer_finalize()* and save to file 2
            ```
            $ grep gst_buffer_finalize logfile | cut -d'x' -f 3 | sort | uniq -c > 2
            $ cat 2
            # allocate/release times    address
                1823                    143f518
                1824                    143f570
                 682                    143f780
                 681                    145e808
                   1                    145e980
            ```

        1. diff allocate/release times between *file 1* and *file 2*
            > search the target address info in logfile

## venus
    middleware (HAL layer)

+ directory
    ```
    venus
        ├── bionic          # android vresion libc/libstdc++/libm/libdl (lite version from gnu)
        ├── build           # core of android build system
        ├── device          # vender code
        ├── external        # exteranl lib
        ├── frameworks      # the implementation of key services such as the System Server
        ├── hardware
        ├── prebuilts       # toolchain
        ├── roku-root       # customer's rootfs
        ├── rtk-bionic      # extract from bionic for tvservice when use glibc
        ├── system          # source code files for the core Android system (for tvservice)
    ```

    - bionic
        > The standard C library (libc) developed by Google for its Android OS.
        > + Lite glibc and not fully support POSIX
        > + more faster and smaller

    - rtk-bionic
        > extract some funcions from lib-bionic
        >> Because lib-bionic will conflict with glibc, but tvserver will use some special API in lib-bionic.

        ```
                     fire                           fire
        system/init ------> system/servicemanager -------> tvservice
        ```



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

