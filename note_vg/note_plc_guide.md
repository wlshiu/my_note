PLC (power line communication) guide
---

# Definition

+ PLC: Power Line Carrier
+ DCU: Data Concentrator unit
+ UIU: User Interface Unit

+ AFE: Analog Front End
+ GPRS: General Packet Radio Service
+ AMR: Automatic Meter Reading System
+ AMI: Advanced Metering Infrastructure
+ HPA: HomePlug Powerline Alliance

+ BBP: BaseBand Processor
+ LBD: LoWPAN BootStrapping Device
    > spec: G3_Specifications_ low_ layers
+ LBS: LoWPAN BootStrapping Server
    > spec: G3_Specifications_ low_ layers

+ Line Driver
    > A line driver is an electronic amplifier circuit designed
    for driving a load such as a transmission line.

```
     protocol              module

                        PLC router
                            |  GPRS/CDMA/Ethernet
    Q/GDW1376.2     --------+---------------------------+           ^
                            |                           |           | hight
                           DCU                          DCU        ----
                            |                           |           | low voltage
     Proprietary    --------+-------------+             |           |
                            |             |             |           v
                        Acquisition    Acquisition      |
                            |                           |
      DL/T645         ------+--------+                  |
       (RS485)              |        |                  |
                          meter    meter            PLC meter
                          (UIU)                       1. Carrier Module
                                                      2. Metering MCU

```



