[Open AMP](https://github.com/OpenAMP/open-amp)
---

In AMP (Open Asymmetric Multi-Processing) systems,
it is typical for software running on **a master to bring up** software/firmware contexts on a remote on a demand-driven basis
and communicate with them using **IPC mechanisms** to offload work during run time.
The participating master and remote processors may be homogeneous or heterogeneous in nature.

+ Needs for multiple environments with different characteristics
    - Real-time (RTOS) and general purpose (i.e. Linux)
    - Safe/Secure environment and regular environment
    - GPL and non-GPL environments


AMP systems were first implemented in linux kernel by Texas Instruments.
However, there is no open-source API/software available that provides similar functionality and interfaces
for other possible software contexts, like RTOS or bare metal-based (Non-OS) applications.

The OpenAMP Framework fills these gaps and provides the required LCM (Life Cycle Management) and IPC infrastructure to
communicate with various software environments (RTOS, bare metal, or even Linux)


# OpenAMP Framework

+ The key components and capabilities
    - remoteproc
        1. This component allows for the LCM (Life Cycle Management) of remote processors
            from software running on a master processor.

        2. It is compliant with Linux 3.4.x kernel

    - RPMsg
        1. The RPMsg API enables IPC (Inter Processor Communications)
            between independent software contexts running on homogeneous
            or heterogenous cores present in an AMP system.

        2. The RPMsg bus is compliant with Linux 3.4.x kernel

    - Software environments support
        ```
                              remoteproc for LCM
                          +---------------------------+
                          |                           |
                          |                           |
          master/remote   v                           v   remote/master
        +------------------+                         +------------------+
        |       Linux      |                         |  RTOS/BareMetal  |
        |       -----      |   rpmsg communication   |    ----------    |
        | remoteproc/rpmsg |<----------------------->|      OpenAMP     |
        +------------------+                         +------------------+

        +------------------+                         +------------------+
        |   master/remote  |                         |   remote/master  |
        |       core       |                         |       core       |
        +------------------+                         +------------------+
        ```

        ```
                              remoteproc for LCM
                          +---------------------------+
                          |                           |
                          |                           |
          master/remote   v                           v   remote/master
        +------------------+                         +------------------+
        |  RTOS/BareMetal  |                         |  RTOS/BareMetal  |
        |    ----------    |   rpmsg communication   |    ----------    |
        |      OpenAMP     |<----------------------->|      OpenAMP     |
        +------------------+                         +------------------+

        +------------------+                         +------------------+
        |   master/remote  |                         |   remote/master  |
        |       core       |                         |       core       |
        +------------------+                         +------------------+
        ```

## Life Cycle Management (LCM)

+ Five essential functions.
    - Allow the master software applications to load the code and data sections of the remote firmware image
        to appropriate locations in memory for in-place execution.

    - Release the remote processor from reset to start execution of the remote firmware.

    - Establish RPMsg communication channels for run-time communications with the remote context.

    - Shut down the remote software context and processor when its services are not needed.

    - Provide an API for use in the remote application context that allows the remote applications
        to seamlessly initialize the remoteproc system on the remote side and
        establish communication channels with the master context

+ Behavior of `master`
    - call `remoteproc_init()`
        > Get the resource table (for configurating memory) and create communication with remote context.
        >> follow the below steps:
        >> 1. Causes remoteproc to fetch the firmware ELF image and decode it
        >> 2. Obtains the resource table and parses it to handle entries
        >> 3. Carves-out memory for remote firmware (.text and .data section)
            before creating virtIO (virtual I/O) devices for communications with remote context

    - call `remoteproc_boot()`
        > Load firmware image of remote and execute it
        >> follow the below steps:
        >> 1. Loads the code and data sections of the remote firmware image
        >> 2. Triggers the remote processor to start execution of the remote firmware.

+ Behavior of `remote`
    - Execute bootstrap flow of firmware image of remote
    - call `remoteproc_resource_init()`
        > Create virtIO devices for master context and announce rpmsg channels to master
        >> 1. Create memory mapping base on resource table
        >> 2. Create rpmsg virtIO devices and channels
        >> 3. Announce rpmsg channels to master

+ Flow chart
    ```
                  master      <<------ rpmsg communicattion ----->>    remote
    +---------------------------------------+                  +-------------------------+
    | call remoteproc_init()                |                  |                         |
    |                                       |      +----------->     boot sequence       |
    |   1. Decode elf file and obtain       |      |           |                         |
    |       resource table                  |      |           +-------------------------+
    |   2. Carves-out memroy                |      |                         |
    |       for text and data setion        |      |                         v
    |   3. Create rpmsg VirtIO device       |      |         +----------------------------------------+
    |       for communicating with remote   |      |         | call  remoteproc_resource_init()       |
    |                                       |      |         |                                        |
    +---------------------------------------+      |         |   1. Create memory mapping             |
                        |                          |         |       base on resource table           |
                        v                          |         |   2. Create rpmsg virtIO devices       |
    +------------------------------------------+   |         |       and channels                     |
    | call remoteproc_boot()                   |   |         |   3. Announce rpmsg channels to master |
    |                                          |   |         |                                        |
    |   1. Load text/data section              |   |         +----------------------------------------+
    |       of remote firmware image to memory |   |
    |   2. Start remote processor              ----+
    |                                          |
    +------------------------------------------+
    ```

+ Interaction sequences
    ```
                         master                            remote
                            |                                |
          remoteproc_init() |    start clock                 |
          remoteproc_boot() |------------------------------->| bootstap flow
                            |                                |
                            |   name service announcement    | remoteproc_resource_init()
                            |<-------------------------------|
           channel attach   |                                |
            callback func   |   name service acknowledgement |
                            |------------------------------->|
                            |                                | channel attach
                            |                                | callback func
                            |  ==(RPMsg channel is ready)==  |
                            |                                |
                            |       message                  |
               rpmsg_send() |------------------------------->|
                            |       message                  |
                            |<-------------------------------| rpmsg_send()
                            |                                |
                            |           ...                  |
                            |                                |
                            |      shutdown message          |
               rpmsg_send() |------------------------------->|
                            |      shutdown message          |
                            |<-------------------------------| rpmsg_send()
                            |                                | remoteproc_resource_deinit()
                            |    Assert reset                |
      remoteproc_shutdown() |------------------------------->|
        remoteproc_deinit() |                                |
                            |                                |
    ```

+ How to create ELF image of remote
    - Define the resource table structure in the Application.
        > It MUST minimally contain **memory carve-out** and **VirtIO device** information for IPC.
        >> reference: <open_amp>/apps/machine/zynq/rsc_table.c

        1. memory carve-out
            > firmware ELF image `start address` and `size`

        2. VirtIO device
            >+ VirtIO device features
            >+ vring (virtual ring or virtual queue) addresses and size
            >+ alignment info

    - Place resource table structure in the **resource table section** (user definition section) of remote firmware ELF
        > Reserve a memory region for resource table

    - Generate ELF image with compiler directly.

    - misc
        1. Linux FIT image
            > It encapsulates the `Linux kernel image`, `Device Tree Blob (DTB)`, and `init-ramfs`.
            >> `libfdt` is used to pack/unpack.

+ How to get resource table in master context
    - Read remote ELF image from file system or other storage device.
        > reference: <open_amp>/lib/common/firmware.c

    - Parse ELF image to get resource table section
        > reference: <open_amp>/lib/remoteproc/`remoteproc_loader.c` and `elf_loader.c`


## RPMsg

+ RPMsg Framework
    - VirtIO Device
        > A abstraction device for application layer

        1. rpmsg device inherits from VirtIO Device
        and it is also known as a rpmsg channel.

    - virtqueue (virtual queue)
        > Involve vring data structure and be used to manage nodes in a queue

    - vring (virtual ring buffer)
        > ring buffer management for payload

    - endpoint
        > Provide logical connections on top of RPMsg channel.
        >> It allows the user to bind multiple Rx callbacks on the same channel.

    - hierarchy
        ```
            callback
            +----------> endpoint
            |
        rpmsg device (channel)
            +-> tx_vq
                    +->
                    ...
            +-> rx_vq
                    +-> attributes of a node
                    +-> vring
                          +-> read pointer
                          +-> write pointer
        ```

# Reference
+ [OpenAMP Framework User Reference](https://github.com/OpenAMP/open-amp/blob/master/docs/openamp_ref.pdf)
+ [OpenAMP Framework for Zynq Devices](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2017_2/ug1186-zynq-openamp-gsg.pdf)
+ [RPMsg Messaging Protocol](https://github.com/OpenAMP/open-amp/wiki/RPMsg-Messaging-Protocol)
+ [RPMsg-lite](https://github.com/NXPmicro/rpmsg-lite)

