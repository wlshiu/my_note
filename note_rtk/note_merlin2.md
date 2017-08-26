sina_merlin2
---

+ Naming

    - IXxxx
        > I => interface

    - CXxxx
        > C => clase

    - GXxxx
        > G => GUI ??

    - MediaSample
        > frame data ??

    - DTV
        1. TS (Transport Stream)
            > PSI/SI + PESs stream

        1. PS (Program Stream)
            > PESs stream

        1. ES (Element Stream)
            > Audio or Video data stream

        1. SCR (System Clock Reference) or PCR (Program Clock Reference)
            > A resolution of `27MHz` which is suitable for synchronization of <br>
            > a decoder's overall clock with that of the usual remote encoder
            >> Sync Decoder and Encoder

        1. PTS (Presentation Timestamp)
            > A resolution of `90kHz`, suitable for the presentation synchronization task
            >> A/V sync

+ Environment
    ```
    $ sudo apt-get install build-essential make dos2unix automake libtool pkg-config
    ```

# Architecture
---

    ```
    # Filter & Pin relation
    # Backward direction <--  --> Forward direction

                               + <-> InputPin_1 <-> Filter_B
                               |
             + <-> OutputPin_1 + <-> InputPin_2 <-> +
    Filter_A |                                      | <-> Filter_C <-> OutputPin_3
             + <-> OutputPin_2 <--> InputPin_3  <-> +


    * A Filter maps to multi-Pins (e.g. Filter_C => InputPin + OutputPin)
    * A OutputPin maps to multi-InputPins (e.g. OutputPin_1)
    * A InputPin maps to a OutputPin (e.g. InputPin_2)

    ```

## Foundation

    folder `StreamClass`

+ IMemAllocator
    > `Buffer Handler`, and support 2 type
    > - IMemRingAllocator (Ring buffer behavior)
    >   > Support `1` writing index and `4` reading indexs in `RINGBUFFER_HEADER`
    > - IMemListAllocator (List behavior)

    > e.g. `Class CAudioRingAllocator`

+ CMemRingAllocator
    > + RingBuffer Header
    >   > If IPC type, it will be allocated at share memory (share with A/V Processor).
    >
    > + Only *Get/Set* R/W pointer info and handle *Mapping Memory Space* (NO Operate R/W Index)
    >   > `Read/Write pointer should be operated by user self`.

    ```cpp

    pAllocator = new CMemRingAllocator(STYLE_IPC);  // select type and  malloc buffer header

    pAllocator->SetBuffer(pBuf, RINGBUF_SIZE);
    pAllocator->Commit();
    pAllocator->Flush(0);
    ```

    - SetBuffer()
        > Assign buffer address and buffer size.
        >> You can malloc buffer by self or input NULL to auto assign buffer

    - Commit()
        > Fill the info (beginAddr) to *RingBuf Header* and setup `multi CReadPointerHandle`
        >   > `m_pBufferNonCachedLower` (IPC case) or `m_pBufferLower` is RingBuffer start pointer
        > - number of ReadPointer: default = `2`, max = `4`
        > - number of WritePointer: only `1`

    - Flush()
        > like memset()

    - GetWriteSize()
        > Get free space of ring buffer

    - GetReadSize()
        > Get readable size

+ CBasePin (CPin.cpp)
    - JoinFilter() (CBasePin method)
        > Record a pointer of mapping filter to CPin object

    - ReceiveConnection()
        > Only `CBaseInputPin` can use.
        >> Assign the pointer of mapping CBaseOutputPin to the member of InputPin Object.

    - Connect()
        > Only `CBaseOutputPin` can use.
        >> Assign the InputPin's pointer to the InputPin Pool, which a menber of OutputPin Object.

+ CBaseInputPin
    - Connect Filter (CBasePin)
        1. m_pOutputPin
            > Record `one` pointer of mapping OutputPin

        1. Disconnect()
            > Clear m_pOutputPin info

        1. ConnectedTo()
            > Copy out the (one) OutputPin pointer in the current `CBaseInputPin`

    - ConnectedTo()
        > Report the pointer of the connected OutputPin.

    - Receive Data/PrivateInfo from `CBaseOutputPin->Deliver()`
        1. Data Process Interface (IMemInputPin)
            > a. Pre-process Received data
            > a. Push data to queue.
            > a. other requestions

    - Assign Allocator (Ring Buffer handler) if necessary

+ CBaseOutputPin
    - Connect Filter (CBasePin)
        1. m_InputPinArr
            > Record `multi` pointers of mapping InputPin

        1. Disconnect()
            > Call `CBaseInputPin->Disconnect()` and Clear InputPin Pool

        1. ConnectedTo()
            > Copy out the InputPin pointers in the current `CBaseOutputPin`.

    - ConnectedTo()
        > Report the pointer list of the connected InputPin.

    - Deliver Data/PrivateInfo to all linked InputPins
        1. Data Process Interface (IMemOutputPin)
            > a. Change InputPin state to `Receiving`
            > a. Pass info with `CBaseInputPin->Receive()`
            > a. Change InputPin state to `Idle`

    - Assign Allocator (Ring Buffer handler) to *All linked InputPins* if necessary
        > The linked InputPins `MUST` use the same Allocator


+ CBaseFilter (CFilter.cpp)
    - AddPin() (CBaseFilter method)
        > Add a pin object to PinArray (Mix OutputPin and InputPin in PinArray)

    - JoinFlow()
        > Record a pointer of mapping FlowManager to Filter object

    - Pause()/Run()/Stop()
        > Change behavior/state of this Filter
        >> - Directly response state (m_State)
        >> - Push to cmdQ and polling state (m_StateNext, e.g. State_Transition -> State_Stopped)

    - RemoveFromFlow()
        > Clear the pointer of the FlowManager, which a member of CBaseFilter

+ CVideoFilter
    - CreateAgent()
        > Create RPC handler

+ CFlowManager
    - AddFilter()
        > Save a pointer of the Filter to FilterArray, which a member of CFlowManager.
        >> Call CFilter->JoinFlow()

    - ConnectDirect()
        > Call CBasePin->Connect() to link Input/Output Pin

    - Disconnect()
        > Call Disconnect() according to CBaseOutputPin-> or CBaseInputPin

    - RemoveFilter()
        > Delete the pointer of the target Filter in FilterArray, which a member of CFlowManager.

    - Run()/Stop()
        1. ReOrderFilter() if necessary

        1. Check states of Filters (m_State/m_StateNext)
            > Support 2 cases
            >> - Directly response state
            >> - Push to cmdQ and polling state with local thread.

        1. Trigger Filter->Pause()
            > order: FilterArray `tail -> head`
            >> - If Run() and state is `State_Stopped`, make state to `State_Paused_Running`
            >> - If Stop() and state is `State_Running`, make state to `State_Paused_Stopped`


        1. Trigger Filter->Run()/Filter->Stop()
            > order: FilterArray `tail -> head`

    - Pause()
        1. ReOrderFilter() if necessary
        1. Check states of Filters
        1. Trigger Filter->Pause()
            > order: FilterArray `tail -> head`

    - GetState()
        > Check filter's state are correct.
        >> Check 1st Filter's state for performance (Because trigger order: tail -> head)

    - CanSetRate()/SetRate()/GetRate()
        > About playing rate

    - ReOrderFilter()
        > Use qsort() to re-order Filters of the FilterArray, the condition is recorded at `m_pUserData`.
        >> The min level is `INT_MIN` and the order in FilterArray is small (head) to large (tail)

        > The filter with the max level will be acted firstly.

    - Leveling()
        > Make the level of the current Filter to `0`
        >> - Increase `1` on Foreward direction
        >>      > Trace forward *all* Filters
        >> - Decrease `1` on Backward direction
        >>      > Trace backward *only* the parent Filter.

	---

    - Thread()/StartDefaultHandlingThread()/StopDefaultHandlingThread()
        > Handle `Default Event` with local thread <br>

        > Default behavior: EnQueue `DefaultEvent` to `m_EventUserQueue`.
        >> You can override `HandleDefaultEvents()` to get your purpose.

    - Notify()
        1. `Push` event info to EventQueue.
            > Send event to the FlowManager.

        1. You can pass events to `m_EventUserQueue` or `m_EventDefQueue` by overriding `HasDefaultHandling()`

        1. `class CVariableSizeQueue` separates HeaderInfo (m_refQueue) and pure Data (m_dataPool[])
            > Copy data with `sizeof(long)` alignment

                ```c
                // If user not care the relation of dataSize and sizeof(long),
                // it just copy dummy data to m_dataPool[].
                memcpy(&m_dataPool[m_indexTail], pData, dataSize * sizeof(long));
                ```

    - HandleCriticalEvents()/HandleDefaultEvents()
        > Directly handle some events by overriding.

    - HasDefaultHandling()
        > You can decide what kinds of events are default by overriding.

    - GetEvent()
        > Peek a Event from queue, default is `m_EventUserQueue`
        >> It should call FreeEventParams() to release event.

    - FreeEventParams()
        > default: DeQueue Event

    ---

    - SendCommand()
        > Send text command to underlying filters.

+ CReferenceClock
    > Record infomation about PTS, A/V sync priorigy, ..., etc.
    >> Use share memory (H/W registers ???)

## Middle filter

    Set of filters for some feature, e.g. decoder filter

+ INavControl
    > A generic interface to *send commands* to navigation filter.

+ NavigationFilter (inherent from INavControl)
    > include `CNavAVSync.cpp`, `CNavigationFilter.cpp`, `NavPluginFactory.cpp`


    ```
    # Linking relation of NavigationFilter

    NavigationFilter      +----->  InputPin_1 -> VideoDecoder (CMPEG2Decoder)
        | (output pin)    |                          +-> OutputPin_1  --------> m_pInputPinb[0] -+
        +-> VIDEO_PIN ----+                          +-> OutputPin_2       +--> m_pInputPinb[1] -|-> CVideoOutFilter
        |                                                                  |    m_pTTOutputPin  -+
        +-> SPIC_PIN  --> m_pInPin -> SPUDecoder (CFilterSpu) -> m_pOutPin +
        |
        +-> AUDIO_PIN ----+
        |                 +----> m_pInPin -> AudioDecoder (CAudioDecFilter)
        |                                       +-> m_pOutPin (PCM_OUT) --> CAudioOutInputPin (PCM_IN)
        +-> TELETEXT_PIN                        +-> m_pExtInPin                |
        +-> ISDB_CC_PIN                                                        +-> AudioOut (CAudioOutFilter)
        +-> ISDB_CC_SUPERIMPOSE_PIN                                                     |
                                                                                        +-> m_pOutPin (PCM_OUT)
    ```

    - CNavigationFilter
        > Master API to integrate flow of Plugins

        > + OutputPin type
        >   > 1. VIDEO_PIN
        >   > 1. AUDIO_PIN
        >   > 1. SPIC_PIN
        >   > 1. TELETEXT_PIN
        >   > 1. ISDB_CC_PIN
        >   > 1. ISDB_CC_SUPERIMPOSE_PIN

        > + CNavigationPinInfo
        >   > Record the buffer usage.

        > + m_passThruPin/m_infoPin
        >   > Support pick stream data from InputPlugin for APP layer

        1. NAVBUF (only for NavigationFilter)
            > Like MsgBox, a set of arguments for deliver to Plugin

        1. LoadMedia()
            a. Select the target ioPlugin (protocol source, e.g. RTSP, UDP, File, ...etc)
            a. Select the target InputPlugin
            a. If necessary, Set callback `setAuthCallback` for getting authentication info from Application layer.
            a. Select the target DemuxPlugin
            a. Setup infomation

        1. ExecUserCmd()
            > Call m_inputPlugin.execUserCmd(), which pass the cmd to InputPlugin

        1. Run()
            > Send `NAV_COMMAND_RUN` with ExecUserCmd() and change state to `State_Running`
            >> Actually, FlowManager calls Pause() before Run().

        1. Pause()
            a. Send `NAV_COMMAND_PAUSE` with ExecUserCmd()
            a. Change state to `State_Paused`
            a. Call `StartStreaming()` to create a thread

        1. CheckPin()
            > Get the *Allocator* from `CBaseOutputPin->GetAllocator()`

        1. UpdatePlaybackPosition()
            > Record the current playing time and information depending on the target container.
            >> *Position* means the position of current playing time

        1. DeliverUserCmd()
            > EnQueue() user cmd to `m_navCmdQueue`
            >> App layer trigger API, e.g. PlayXXX(), to EnQueue cmd

        1. StartStreaming()
            a. Get A/V Buffer info through `CheckPin()`
            a. Send property `NAVPROP_INPUT_SET_RINGBUFFER_INFO` to the InputPlugin and call `UpdatePlaybackPosition()`
            a. Init reference clock
                > Setup A/V Sync infomation and Select which one (Audio/Video) is master for sync
            a. Create a demux thread `ThreadProcEntry()`

        1. ThreadProcEntry()/ThreadProc()
            a. `HandleUserCmd()` to Pass cmd to InputPlugin
                > DeQueue() cmd from `m_navCmdQueue`
                >> + `m_navCmdQueue` is `ulCircularQueue` type.
                >> + User call *PlayXXX()* and EnQueue cmd to `m_navCmdQueue`

            a. Re-deliver private info with `DeliverPrivateInfo()` <br>
                if the previous `DeliverPrivateInfo()` fail in `Read()`
                > handle some demux request ???

            a. Read()
                > Read data from InputPlugin and output DemuxOut info

                b. If buffer Empty
                    > + Call `m_inputPlugin.read()` to fill buffer and response info with `struct NAVBUF`
                    >   > - If `NAVBUF_DATA` or `NAVBUF_EXT`
                    >   >   > 1. Backup `struct NAVBUF` info to `DemuxIn`
                    >   >   > 1. Update `DemuxIn->pCurr` and `DemuxIn->pEnd` pointer
                    >   >   > 1. `DeliverPrivateInfo()` if feedback from InputPlugin
                    >   >   >   > Support re-try at `ThreadProc()` (Info be queued in `m_demuxInReserved[]`)
                    >   > - If other type, send to `DeliverNavBufCommands()` to handle cmd.

                b. If buffer NOT empty, Data send to Demux Plugin `m_demuxPlugin[channelIndex].parse()`
                    > Parsing result will record in DemuxOut

                    > + MPEGProgram case
                    >   > PES parser
                    > + Media File Container case
                    >   > Pass through to Ring Buffer in InputPins

            a. DeliverData()
                > Deliver data to RingBuffers, which linked CBaseInputPins <br>
                > Support re-try at `ThreadProc()` (Info be queued in `m_demuxOutReserved[]`)

                b. Prepare Payload Size which map to all connected PINs.
                    > Info is record in NAVBUF (like MsgBox)

                b. Check Free Space in Ring Buffer and get the current writing pointer,
                   `pAllocator->RequestWriteSpace()`
                    > `CMemRingAllocator` is just a database......@$%&

                    > + Free sapce in Ring Buffer MUST be more than `5%` or drop data
                    > + Keep PTS data MUST be less than 18 sec or drop data ???

                b. Handel NavBuf (like MsgBox)
                    > + DeliverPrivateInfo()
                    > + Copy payload to RingBuffer with `NAV_MEMCPY()`
                    >   > Need to calculate new writing pointer.
                    > + Update writing pointer to `CMemRingAllocator`

            a. CI handle

        1. GetBufferFullness()
            > Get remain size of valid data in Ring Buffer


    - NavPluginFactory
        > + Attach `Media I/O protocol` (in IOPlugins/*)
        > + Attach `Container Parser`
        >   1. Attach the operator of Source data
        >       > a. Operator involve `InputXXX/*.cpp`
        >       >   > MKV, AVI, MP4, Network, ...etc.
		>       >
        >       > a. `void *pInstance` of struct INPUTPLUGIN is the `private handle` in InputPlugin
        >       > a. Record in `INPUT_PLUGIN_MODULES[]`
        >
        >   1. Attach the operator of Demux
        >       > a. Operator involve `DemuxXXX/*.cpp`
        >       >   > MPEG PES, Transport Stream, MPEG Program, and MHEG5
        >       >   >> MHEG5 is a standard for interactive television services
        >       >
        >       > a. If MKV, AVI, ...etc, Use `CDemuxPassthrough` to bypass the A/V data
        >       > a. If Transport Stream, Use `CDemuxMPEGTransport` to split PSI/SI and A/V of PES
        >       > a. if MPEG file, Use `CDemuxMPEGProgram` to split A/V data of PES
		>       > a. Record in `DEMUX_PLUGIN_MODULES[]`

        1. SelectInputPlugin()
            > + Find the target `I/O` Plugin
            >   a. Sometimes, the plugin will be re-directed by `IdentifyIOPlugin()`.
            >   a. Assign callback `setAuthCallback` from Application if necessary.
            >
            > + Find the target `Input` Plugin
            >   a. choice condition
            >       > - Map with *file extensions*
            >       > - Fully chicking
            >       >   > `SPECIAL_INPUT_PLUGIN_MODULES[]` is recording the all insertion methods, which supported InputPlugin
            >
            >   a. Get targer by checking the *Tag Marker* of container simply.
            >       > use func `identify`
            >
            >   a. link I/O Plugin and Input Plugin
            >       > use func `registerIOPlugin`
            >
            >   a. Use `loadMedia` in InputPlugin
            >       > setup infomation

        1. IdentifyIOPlugin()
            > To verify IO Plugin is available or not (By checking URL ???). <br>
            > And maybe re-directe to the other IO Plugin depending on H/W
            >> `PFUNC_OPEN_IO_PLUGIN  openFunc` means insert plugin object.

+ Decoder/Encoder/In/Out
    > + Setup Deoder object
    >
    > + `Create Agent` (RPC)
    >   > Communicate with CODEC at linux kernel side
    >   >   > NAL parser is at linux side
    >
    > + InBand buffer
    >   > For performance (avoid system_call), use share memory to run-time update. ???
    >
    >   - Share buffer between System/Decoder CPU
    >   - Ring buffer
    >   - Store variety of packets, which involve cmd, payload address/size, ...etc.

    - CMPEG2Decoder (inherent from CVideoFilter)
        > `m_agentInstanceID` is *Decoding Handle* in Video Processor side. ???

        > + Create and Add Pins
        > + Pass command with RPC, e.g. Run()/Pause()/Stop()


    - CMPEG2InputPin
        > + Create payload ring buffer (m_pAllocator)
        > + Create inband ring buffer (m_pICQAllocator)

        1. InitRingBuf()

            a. Setup bit-stream buffer (m_pAllocator) and inband buffer (m_pICQRPHandle)
                > bit-staream buffer: audio/video payload <br>
                > inband buffer: some private info (e.g. meta data, specific control, ...etc.)
            a. Assign buffer type to *RingBuf Header*
                > m_pAllocator: RINGBUFFER_STREAM <br>
                > m_pICQBufferHeader: RINGBUFFER_COMMAND
            a. Send physical address of *RingBuf Header* to Video Processor with RPC.
                > `VP_RPC_TOAGENT_INITRINGBUFFER()`
                >> NavigationFilter and Video Processor update/get info to/from *RingBuf Header*

        1. PrivateInfo()
            > Receive info from NavigationFilter

            a. Prepare packet (inherent from struct INBAND_CMD_PKT_HEADER) based on *infoId*
            a. DeliverInBandCommand() enqueue packet to `m_pICQAllocator`

    - CVideoOutFilter
        > Send command to Video Processor with RPC

        1. ConnectVDec()

    - CVideoOutInputPin
        >

+ Misc
    > e.g. File access, Mux, ...etc.

+ RPC
    - Prepare client calling header, involve `options`, `program_id`, and `version_id`
    - Create Agent (Handle of Decoder) if necessary.
    - Decoding Processor is *Big-endian* (mips) and system is *little-endian* (arm).

## Platform

+ OSAL
    - pli_IPCWriteULONG()/pli_IPCReadULONG()/pli_IPCWriteULONGULONG()/pli_IPCReadULONGULONG()
        > Just do big/little Endian converting

## Application

    Interface for customer using

+ VideoPlayback
    > Handle playing flow (role: module)

+ PlayControl
    > Handle event trigger (role: control)

+ CommandManager
    > Message transportation (S/W MsgQ), which bases on `FIFO`, and it supports timestamp for dropping expired cmd.

    >   > Support multi-CmdQ, and priority High to Low
    >   > 1. m_pIMSCmdQue
    >   > 2. m_pCtrlCmdQue
    >   > 3. m_pCmdQue

    - Peek()
        > ONLY get the 1st Cmd Item

    - Pop()
        > *Get* the 1st Cmd Item and *remove* it from queuq.

    - IsValidControlCommand()
        > valid condition
        > 1. timestamp == -1 (forever)
        > 1. Cmd is NOT time out (VALID_DEFER_PERIOD)

#### RSS Client

    scriptFunctionList[] in ScriptFunctionList.cpp
        > SDK support methods with mapping to script API

+ CRegisterScriptFunctions
    > *Constructor* will register the script methods (FunctionTable) to `CSimpleScriptEngine`


+ CSimpleScriptEngine
    > Script render engines

    ```text
    # structure of Script method

    ~ FunctionTableItem
    |~ FunctionTable_0   => Method Type, e.g. menu, drow, ...etc.
    | |- my_print()      => Map to script's cmd (method)
    | \- getItemInfo()
    |
    |
    |
    |+ FunctionTable_1
    |+ FunctionTable_2
    |

    ```

    - scriptFunctionsInit()
        > Prepare Script Methods

    - callFunction()
        > Execture funciton, which map to Script Method, When *GNU Bison* parse RSS script.

+ SimpleScriptParser
    > Context parser (from GNU Bison parser)


+ CRSSApplication
    > The interface of RSS engine.

    - init()
        > `m_rssCore.start()` will load RSS file and split the elements. (XML element)

+ XML architecture

    ```
    Document (DOM)
    |- Declaration : <?xml version='1.0' ?>
    \- Root Element : <html>
       |- element <header>
       |   \- element <title>
       |        \- attribue : text = "My Title"
       |
       |- element <body>
       |   |- element <h1>
       |   \- element <h2>

    ```

## Customer project

    User UI/Flow by project

+ RtkBootUP in project/xxx/bootup/BootUP.cpp
    > Iniit/Setup module (almost about H/W, besides kernel)

    - pli_init()
    - board_init()
    - SetupClass::SetInstance()
        > Set target SetupClass, e.g. SetupClassSqliteEeprom, SetupClassSqlite, or SetupClassBinary

    - firmware_init()
        > Setup RPC, e.g. Audio, Video, and Reply Handler

    - Factory test
    - Panel setting
    - Scaler setting (~/system/src/Platform_Lib/TVScalerControl_DriverBase/scaler/)
        > Assign H/W registers

        1. Scaler_Init()
            > Select default source input

    - backlight control

+ AbstractAP (@#$%....... The architecture is a stupid jok)
    > `AP`: a object which has self message handler and rendered by RSS engine or Self Drawing <br>
    > `feature`: a set of multi-APs, e.g. `MediaPlayer =  VideoPlaybackAP + PopupMenuAP * n + VolumeCtrlAP + ...`
    >
    > - Statically methods declare (only one instance)
    > - Common inherent methods
    >   1. Activate()
    >       > Init APP
    >   1. Deactivate()
    >       > DeInit APP
    >   1. ProcessKey()
    >       > Message handle

    ```
    # classify APP

                AbstractAP
        + ----------+---------------+
        |                           |
    Category_2                  Category_1
    |- PopupMenuAP              |- RootAp
    |- VolumeCtrlAP             |- VideoPlaybackAP
    |- PhotoPlaybackAp          |- AudioPlaybackAP
    |- ...etc.

    ```

    - Category
        > Actually, this APP category is superfluous (It should be a attribue, overlayable)

        1. Category_1: Normal AP
        1. Category_2: Pop Up AP
            > It can *Alpha Brand* on Category_1

    1. ProcessKey()
        > Message handle

        ```
        Cmd (struct COMMAND_BUFFER)
            -> Cur_APP->ProcessKey() -> If cmd is defined, handle Cmd
                |
                +-> AbstractAP::ProcessKey -> If cmd is defined, by pass to target_APP
                    |
                    +-> CommandManager Queue
                        -> System Main_loop get cmd
                            -> by pass to target_APP or Cur_APP
        ```

    1. SwitchAPTo()
        > Change *forcus* APP (like switch window to top)
        >
        > + call `Deactivate()` to deinit current APP
        > + call `Activate()` to init new APP
        >   > use `struct MessagePack` to pass arguments
        >
        >   - Create `CRSSApplication` as Render, e.g. PopupMenuAP::Activate()
        >       > call `CRSSApplication::init()` to start
        >   - rss_path format: `rss_file://xxx/xxx.rss`
        >       > e.g. `rss_file://Resource/ui_script/DVBT_TV040/media_mainMenu.rss`


#### UI

+ IMS (for what ???)
    - handle key ???

+ Module

+ Control
    - AbstractAP
        > master controlling flow


+ View (Graphic middle ware)
    > IMS_new folder

    - CBasicView

        1. drawWidgets()
            > Follow the input CRSSElement to Draw surface
            >> `CRSSApplication` will load/parse the target RSS file and output a CRSSElement.









