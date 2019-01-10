NS-3 class
---

+ `Simulator` class
    - `Schedule(exec_time_stamp, event_handler, arguments...)`
        > configure the event trigger list with time-stamp

        1. the max of supporting arguments is **5**
            > It is instanced with template of C++

        1. the context (node ID) is the node of currently-executing event

    - `ScheduleNow()`
        > It allows you to schedule an event for the current simulation time
        >> they will execute _after_ the current event is finished executing
        but _before_ the simulation time is changed for the next event.

        1. the context (node ID) is the node of currently-executing event

    - `ScheduleWithContext(context, exec_time_stamp, event_handler, arguments...)`
        > It can configure the event trigger list for the context (node ID) with time-stamp
        >> To avoid this case, when simulating the transmission of a packet from a node to another,
        this behavior is undesirable since the expected context of the reception event is that of the receiving node, not the sending node.

        1. No context (global event)
            > `Simulator::NO_CONTEXT` == 0xFFFFFFFF

    - `Run()`
        > start to execute the event queue (time priority, oldest is most height)

    - `Destroy()`
        > cleanup simulation resources

    - `GetContext()`
        > The node id of the currently executing network node is in fact tracked by the Simulator class.
        So this method will return the the current context (node ID) with 32-bits integer.

+ `YansWifiPhy` class

    [ns3::YansWifiPhy Class Reference](https://www.nsnam.org/doxygen/classns3_1_1_yans_wifi_phy.html#details)

    - Attributes

        1. `EnergyDetectionThreshold`
            > The energy of a received signal should be higher than this threshold (dbm) to allow the PHY layer to detect the signal,
            or the packet will be dropped.

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: -101

            ```cpp
            wifiPhy.Set("EnergyDetectionThreshold", DoubleValue(eng_threshold));
            ```

        1. `TxPowerEnd`
            > Maximum available transmission level (dbm).

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: 16.0206

            ```cpp
            wifiPhy.Set("TxPowerEnd", DoubleValue(txp));
            ```

        1. `TxPowerStart`
            > Minimum available transmission level (dbm).

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: 16.0206

            ```cpp
            wifiPhy.Set("TxPowerStart", DoubleValue(txp));
            ```

        1. `TxGain`
            > Transmission gain (dB).

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: 0

            ```cpp
            wifiPhy.Set("TxGain", DoubleValue(gain));
            ```

        1. `RxGain`
            > Reception  gain (dB).

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: 0

            ```cpp
            wifiPhy.Set("RxGain", DoubleValue(gain));
            ```
        1. `RxNoiseFigure`
            > Loss (dB) in the Signal-to-Noise-Ratio due to non-idealities in the receiver.
            According to Wikipedia (http://en.wikipedia.org/wiki/Noise_figure),
            this is **the difference in decibels (dB)
            between the noise output of the actual receiver to the noise output of an ideal receiver with the same overall gain
            and bandwidth when the receivers are connected to sources at the standard noise temperature T0 (usually 290 K)**.

            >> + Underlying type: double -1.79769e+308:1.79769e+308
            >> + Initial value: 7

            ```cpp
            wifiPhy.Set("RxNoiseFigure", DoubleValue(7));
            ```

        1. `ChannelWidth`
            > Whether 5MHz, 10MHz, 20MHz, 22MHz, 40MHz, 80 MHz or 160 MHz.

            >> + Underlying type: uint16_t 5:160
            >> + Initial value: 20

            ```cpp
            wifiPhy.Set("ChannelWidth", UintegerValue(20));
            ```

    - Distance and Power

        use Friis free space equation

        ```
        # 'FriisPropagationLossModel' class

        where Pt, Gr, Gr and P are in Watt units
        L is in meter units.

        P     Gt * Gr * (lambda^2)
        --- = ---------------------
        Pt     (4 * pi * d)^2 * L

        Gt: tx gain (unit-less)
        Gr: rx gain (unit-less)
        Pt: tx power (W)
        d: distance (m)
        L: system loss
        lambda: wavelength (m)

        Here, we ignore tx and rx gain and the input and output values
        are in dB or dBm:

                                lambda^2
        rx = tx +  10 log10 (-------------------)
                              (4 * pi * d)^2 * L

        rx: rx power (dB)
        tx: tx power (dB)
        d: distance (m)
        L: system loss (unit-less)
        lambda: wavelength (m)
        ```

        1. Propagation Loss Model

        ```cpp
        double                      txPowerDbm = +20; // dBm
        double                      rxPowerDbm = 0.0f;
        FriisPropagationLossModel   model;

        Ptr<ConstantPositionMobilityModel>  pos_a = CreateObject<ConstantPositionMobilityModel>();
        Ptr<ConstantPositionMobilityModel>  pos_b = CreateObject<ConstantPositionMobilityModel>();

        pos_a->SetPosition(Vector(0.0, 0.0, 0.0));

        for( double distance = 0.0; distance < 2500.0; distance += 10.0)
        {
            pos_b->SetPosition(Vector(distance, 0.0, 0.0));

            rxPowerDbm = model->CalcRxPower(txPowerDbm, pos_a, pos_b);
        }
        ```














