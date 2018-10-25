Hypervisor
---

The hypervisor (or virtual machine monitor, VMM) drives the concept of virtualization by
allowing **the physical host machine** to operate **multiple virtual machines as guests**
to help maximize the effective use of computing resources such as memory, network bandwidth and CPU cycles.


# Definition

```
    +---------------+   +---------------+       |
    |     APPs      |   |     APPs      |       |
    +---------------+   +---------------+       |
    |      OS       |   |      OS       |       | Applications
    +---------------+   +---------------+       |
    |  VM 1 (guest) |   |  VM 2 (guest) |       |
    --------------------------------------------|
                    Hypervisor                  |
--------------------------------------------------------------
                        Operating System
                            H/w
                        physical machine (Host)
```

+ host machine
    > The physical machine that a virtual machine is running on.

+ guest machine
    > The virtual machine, running on the host machine.


# Classification
+ Type-1, native or bare-metal hypervisors
    > Run directly on the host's hardware to control the hardware and manage the guest VMs.

    ```
        +---------------+   +---------------+
        |     APPs      |   |     APPs      |
        +---------------+   +---------------+
        |      OS       |   |      OS       |
        +---------------+   +---------------+
        |  VM 1 (guest) |   |  VM 2 (guest) |
        -----------------------------------------
                    Hypervisor
    -----------------------------------------------
                        Hardware
                    physical machine (Host)
    ```

+ Type-2 or hosted hypervisors
    > Run on a conventional OS, just like other applications on the system.
    In this case, a guest OS runs **as a process** on the host,
    while the hypervisors separate the guest OS from the host OS.

    ```
        +---------------+   +---------------+
        |     APPs      |   |     APPs      |
        +---------------+   +---------------+
        |      OS       |   |      OS       |
        +---------------+   +---------------+
        |  VM 1 (guest) |   |  VM 2 (guest) |
        -----------------------------------------
                    Hypervisor
    -----------------------------------------------
                    Operating System
                        H/w
                    physical machine (Host)
    ```

# ATF (Arm-Trusted-Firmware)
ATF provides a reference implementation of secure world software for Armv8-A and Armv8-M.

[Trusted Firmware TF-A](https://github.com/ARM-software/arm-trusted-firmware) for Armv8-A <br>
[Trusted Firmware TF-M](https://git.trustedfirmware.org/trusted-firmware-m.git) for Armv8-M

Arm Cortex processors with TrustZone run a secure operating system (OS) and a normal OS simultaneously from a single/mutil cores.

## Exception Levels
+ Glossary
    > `BL` - Boot Loader <br>
    > `EDK2` - EFI Development Kit 2 <br>
    > `EL` - Exception Level <br>
    > `NV` - Non-Volatile <br>
    > `PSCI` - Power State Control Interface <br>
    > `SMC` - Secure Monitor Call <br>

```
                    Normal (non-Secure) world                      Secure World
EL0                                                     |                               Secure EL0
        +------------------+      +------------------+  |  +------------------+
        | APP 2 Guest OS 1 |      | APP 2 Guest OS 2 |  |  | APP 2 Trusted OS |
        +------------------+      +------------------+  |  +------------------+
        +------------------+      +------------------+  |  +------------------+
        | APP 1 Guest OS 1 |      | APP 1 Guest OS 2 |  |  | APP 1 Trusted OS |
        +------------------+      +------------------+  |  +------------------+
                                                        |
EL1                                                     |                               Secure EL1
            +------------+          +------------+      |  +------------+       +--------------+
            | Guest OS 1 |          | Guest OS 2 |      |  | Trusted OS |       | BL2 Boot F/W |
            +------------+          +------------+      |  +------------+       +--------------+
                                                        |
EL2                                                     |
        +---------------------------------------------+ |
        |                  Hypervisor                 | |
        +---------------------------------------------+ |
    ----------------------------------------------------+
===================================================== SMC ======================================
EL3                                                                             +--------------+
                Runtime EL3 Firmware (Secure Monitor)                           | BL1 Boot F/W |
                                                                                +--------------+
```




# Reference
+ [Hypervisor wiki](https://en.wikipedia.org/wiki/Hypervisor)
+ [成大資工的 wiki- xvisor](http://wiki.csie.ncku.edu.tw/embedded/xvisor)
+ [嵌入式虛擬機管理器Xvisor對比分析](https://www.jianshu.com/p/329635e8107b)
+ [Arm-Trusted-Firmware](https://github.com/ARM-software/arm-trusted-firmware)



