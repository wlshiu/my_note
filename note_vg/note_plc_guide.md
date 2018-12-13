PLC (power line communication) guide
---

# Definition

+ PLC: Power Line Carrier
+ DCU: Data Concentrator unit
+ UIU: User Interface Unit

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

+ CSMA: Carrier Sense Multiple Access
    > MAC protocol

+ CSMA-CD: Carrier Sense Multiple Access with Collision Detection
    > Ethernet MAC (IEEE 802.3)

+ CSMA-CA: Carrier Sense Multiple Access with Collision Avoidance
    > WLAN (IEEE 802.11)

+ WSN: Wireless Sensor Network
+ POS: Personal Operating Space
+ PAN: Personal Area Network
+ 6LoWPAN: IPv6 over Low-Power Wireless Personal Area Networks
+ WPAN: Wireless Personal Area Network

+ LR-WPAN: Low-Rate Wireless Personal Area Network
    > spec: [IEEE 802.15.4](https://en.wikipedia.org/wiki/IEEE_802.15.4)

    - support CSMA-CA
    - transmission rate
        1. 20kbps
        1. 40kbps
        1. 250kbps

    - function classification
        1. FFD (Full Function Device)
        1. RFD (Reduced Function Device)
            > These are meant to be extremely simple devices with very modest resource and communication requirements.
            Due to this, they can *ONLY* communicate with FFDs and can never act as coordinators.

        ```
        RFD <---> FFD
        RFD <-x-> RFD (Not communicate directly)

        RFD_1 ---> FFD_1 ----> RFD_2
        ps. FFD_1 is the coordinator of RFD_1 and RFD_2
        ```

    - support topology
        1. Star
            > only one FFD (call PAN Coordinator)

        1. Point-to-point
            > - the structure is as cluster tree.
            > - RFDs are exclusively leaves of a tree, and most of the nodes are FFDs

            ```
            cluster tree

                               RFD                           RFD
                                |                             |
                    +----- PAN coordinator (FFD) ----------- PAN coordinator (FFD)
                    |           |
                    |          FFD (non-coordinator)
                    |
                    |
            Network Coordinator (FFD) --+--- RFD
                    |                    |
                    |                    +---- FFD (non-coordinator)
                    |
                    |
                    |
                    |           FFD (non-coordinator)
                    |            |
                    +---- PAN coordinator (FFD) ----------- PAN coordinator (FFD)
                                 |
                                RFD

            ps. first, Network Coordinator set self as cluster header (CLH) and set cluster identifier (CID) to 0
            ```

