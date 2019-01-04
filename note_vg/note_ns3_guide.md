NS-3 guide
---

# Setup environment
```
$ ./ns3_env_setup.sh
$ wget https://www.nsnam.org/releases/ns-allinone-3.29.tar.bz2 ~/NS-3
$ cd ~/NS-3 && tar -jxf ns-allinone-3.29.tar.bz2
$ ./ns3_pre_build.sh ns-allinone-3.29

    or

$ ./ns3_install-ns3.28.sh
```

# Software architecture
```
~ build
    +-- bindings
    +-- c4che
    +-- examples    (obj files of examples)
    +-- lib         (ns-3 lib of .so of modules)
    +-- ns3         (header files)
    +-- scratch     (compiler working space)
    +-- src         (obj files of ns-3 modules)
    \-- utils       (obj files of utils)

~ src (modules source code)
    +-- antenna
    ~ aodv                    (Ad Hoc On-Demand Distance Vector)
        +-- bindings        (bind with python)
        +-- doc
        +-- examples
        +-- helper          (user interface of module)
        +-- model           (implementation of module)
        +-- test            (unit test of module)
            wscript         (waf script)
    +-- applications
    +-- bridge
    +-- brite
    +-- buildings
    +-- click
    +-- config-store
    +-- core                    (core of NS-3)
    +-- csma                    (IEEE802.3 ethernet)
    +-- csma-layout
    +-- dsdv                    (for MANET, Destination-Sequenced Distance Vector routing protocol)
    +-- dsr                     (for MANET, Dynamic Source Routing routing protocol)
    +-- energy                  (power consumption of wireless)
    +-- fd-net-device
    +-- flow-monitor
    +-- internet                (TCP/IPv4/IPv6 modules)
    +-- internet-apps
    +-- lr-wpan                 (IEEE 802.15.4 Low-rate wireless personal area network)
    +-- lte                     (Long Term Evolution)
    +-- mesh
    +-- mobility                (mobility models, handle object's position/coordinate, speed, ...etc)
    +-- mpi
    +-- netanim                 (Animation)
    +-- network                 (packet module)
    +-- nix-vector-routing
    +-- olsr                    (for MANET, Optimized Link State Routing protocol)
    +-- openflow
    +-- point-to-point
    +-- point-to-point-layout
    +-- propagation
    +-- sixlowpan               (6LoWPAN)
    +-- spectrum
    +-- stats
    +-- tap-bridge
    +-- test
    +-- topology-read
    +-- traffic-control
    +-- uan                     (under-water acoustic network)
    +-- virtual-net-device
    +-- visualizer
    +-- wave                    (for VANET, IEEE  802.11p/1609.1~4)
    +-- wifi                    (IEEE 802.11 a/b/g)
    +-- wimax                   (IEEE 802.16)
```

+ `ns3::Vector`
    > The base class for a coordinate (x,y,z).

# Concept

+ Node
    > The basic computing device abstraction is called the node.

    - It was represented in C++ by the `class Node`.
        > A Node as a computer to which you will add functionality.
        One adds things like applications, protocol stacks and peripheral cards
        with their associated drivers to enable the computer to do useful work.

+ Application
    > The basic abstraction for a user program that generates some activity to be simulated is the application.

    >> In NS-3, Application Class is working at user space, it does not handle kernel space.

    - It was represented in C++ by the `class Application`.
        > Your APP should inherit class Application, e.g. UdpEchoClientApplication, UdpEchoServerApplication

+ Channel
    > In NS-3, the connection a Node connects to another is represented as a communication channel.

    - It was represented in C++ by the `class Channel`.
        > There are several specialized versions of the Channel
        called `CsmaChannel`, `PointToPointChannel` and `WifiChannel` in the tutorial.

        >> `class CsmaChannel` implements the instance of a carrier sense multiple access communication medium


+ Net Device
    > A Node may be connected to more than one Channel via multiple NetDevices, e.g. Network Interface Cards

    - The net device abstraction is represented in C++ by the `class NetDevice`.

+ Topology Helpers
    > In a large simulated network you will need to arrange many connections between Nodes, NetDevices and Channels.
    Topology helper objects support to combine those many distinct operations into an easy to use model for your convenience.

    - `class NodeContainer`
        > The NodeContainer topology helper provides a convenient way to create,
        manage and access any Node objects that we create in order to run a simulation.

        >> NodeContainer is a nodes management, it can help to configure the attributes of every node,
        e.g. IP stack type, IP address, link type (P2P), ...etc.

    - `class PointToPointHelper`
        > This topology helper encapsulates NetDevice and Channel.
        For example, `PointToPointHelper` configures and connect ns-3
        `PointToPointNetDevice` and `PointToPointChannel` objects.


+ Example code

```cc
/* tutorial/first.cc */

int main (int argc, char *argv[])
{
    CommandLine cmd;
    cmd.Parse (argc, argv);

    /**
     * Set the time resolution to one nanosecond
     */
    Time::SetResolution (Time::NS);
    LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
    LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);

    /**
     * Create node mgr
     */
    NodeContainer   nodes;
    nodes.Create (2);

    /**
     * Configure the link model (NetDevice and Channel)
     */
    PointToPointHelper      pointToPoint;
    pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
    pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));

    /**
     * Install P2P Device/Channel to Nodes and
     * Create NetDevice mgr to handle NetDevices of nodes
     */
    NetDeviceContainer      devices;
    devices = pointToPoint.Install (nodes);

    /**
     * Install IP stack interfaces to nodes
     */
    InternetStackHelper     stack;
    stack.Install (nodes);

    /**
     * configure IP stack paramaters
     */
    Ipv4AddressHelper   address;
    address.SetBase ("10.1.1.0", "255.255.255.0");

    /**
     * Assign address (auto-accumulate ip) to devices and
     * Create IP Stack mgr from NetDevice mgr
     */
    Ipv4InterfaceContainer  interfaces = address.Assign (devices);

    /**
     * Application
     */
    UdpEchoServerHelper     echoServer (9); // create a UdpEchoServer with port 9

    /**
     * Install UdpEchoServer to node 1 and
     * Return a APP handler
     */
    ApplicationContainer    serverApps = echoServer.Install (nodes.Get (1));
    serverApps.Start (Seconds (1.0)); // app start at the 1-st second
    serverApps.Stop (Seconds (10.0)); // app stop at the 10-th second

    /**
     * Create UdpEchoClient with remote address and remote port
     */
    UdpEchoClientHelper     echoClient (interfaces.GetAddress (1), 9);
    echoClient.SetAttribute ("MaxPackets", UintegerValue (1));        // set client attributes
    echoClient.SetAttribute ("Interval", TimeValue (Seconds (1.0)));  // set client attributes
    echoClient.SetAttribute ("PacketSize", UintegerValue (1024));     // set client attributes

    /**
     * Install UdpEchoClient to node 0 and
     * Return a APP handler
     */
    ApplicationContainer    clientApps = echoClient.Install (nodes.Get (0));
    clientApps.Start (Seconds (2.0)); // app start at the 2-ed second
    clientApps.Stop (Seconds (10.0)); // app stop at the 10-th second

    // output myfirst.pcap
    pointToPoint.EnablePcapAll ("myfirst", false);

    /**
     * Start simulation
     */
    Simulator::Run ();
    Simulator::Destroy ();
    return 0;
}

```

+ Python lib

```
# install pip
$ sudo apt-get -y install python3-pip python-pip

# upgrade pip
$ python -m pip install --upgrade pip

# upgrade python lib
$ sudo pip install pip-review
$ sudo pip-review --local --interactive
```

+ Compiler and Run
    - compiler lib

    ```shell
    $ ./waf clean

    # profile: debug or optimized
    $ ./waf configure --enable-sudo --build-profile=debug --enable-examples --enable-test
    ```

    - compiler user code

    ```shell
    $ cd ns-allinone-3.29/ns-3.29
    $ cp ./examples/tutorial/first.cc ./scratch/myfirst.cc

    # compiler the source in scratch folder
    $ ./waf

    # run target (without file extension '.cc')
    $ ./waf --run scratch/myfirst
    ```

+ GDB

    [official reference](https://www.nsnam.org/wiki/HOWTO_use_gdb_to_debug_program_errors)

```shell
# manual
$ ./waf shell
$ cd build/examples/tutorial
$ gdb <program-name>

    or

# from waf
# option: --vis to figure
$ ./waf --command-template="gdb -tui %s" --run <program-name>
    or
$ ./waf --command-template="cgdb %s" --run <program-name>
```

+ NetAnim

    - build

    ```
    $ cd ns-allinone-3.28/netanim-3.108

    $ sudo apt-get install qt4-dev-tools
    $ make clean
    $ qmake NetAnim.pro
    $ make
    ```

    - Generate input XML file

    ```
    #include "ns3/netanim-module.h"
    ...
    int main()
    {
      ...
      AnimationInterface anim("xxx.xml");
      Simulator::Run ();
    }
    ```

    - run

    ```
    $ ./NetAnim

    # opne xxx.xml by GUI
    ```

+ [Eclipse-cdt](https://www.eclipse.org/cdt/downloads.php)

    - install

    ```
    $ sudo apt-get install eclipse-cdt
    ```

    - configure environment

        1. create new project
            > File  -> New -> project
        2. select project type
            > C/C++ -> C++ project
        3. configure project basic setting
            > - Project Name: ns328
            > - Project Type: empty project
            > - toolchain: linux gcc

        4. configure project detail
            > project explorer -> ns328 (project name) -> right key -> properties

        5. C/C++ build -> tab **Build Settings**
            > - disable `Use default build command` and `Generate makefiles automatically`
            > - Build command: /home/[username]/working/ns3/ns-allinone-3.28/ns-3.28/waf
            > - Build Directory: /home/[username]/working/ns3/ns-allinone-3.28/ns-3.28/build

        6. C/C++ build -> tab **Behavior**
            > - Build: build
            > - Clean: clean

        7. configure Debugger
            project explorer -> ns328 (project name) -> right key -> debug as -> debug Configuration
            > double click **C/C++ Application**
            > + tab **Environment**
            >> - Name: LD_LIBRARY_PATH
            >> - Value: /home/[username]/working/ns3/ns-allinone-3.28/ns-3.28/build
            > + tab **Main**
            >> - C/C++ Application: build/scratch/fifth
            > + Peess **Debug**

        8. configure external tool (waf)
            > + Run -> External Tools -> External Tools Configurations
            > + Program -> new
            >> - Name: ns_waf
            >> - Location: select waf file with **Browse Workspace**
            >> - Working Directory: select scratch folder with **Browse Workspace**
            >> - Argument: --run ${string_prompt}
            >> - Run
            >> - pop-up window: name of `*.cc` file in scratch without .cc

        9. error fix
            > - message: `The project was not configured: run "waf configure" first!`

            ```shell
            $ cd /home/[username]/working/ns3/ns-allinone-3.28/ns-3.28
            $ ./waf configure
            ```
        10. press `run ns_waf` on the menu bar

+ Log

    `NS_LOG=[moudle name]=[level masks]:[moudle name]=[level masks]`

    ps. no white space

    e.g. **export 'NS_LOG=UdpEchoClientApplication=level_all|prefix_func'**

    e.g. **export 'NS_LOG=UdpEchoClientApplication=level_all|prefix_func:UdpEchoServerApplication=level_all|prefix_func'**

    - module name
        > The module name is defined in source code.

        ```c
        NS_LOG_COMPONENT_DEFINE("xxx")
        ```

    - level masks

        1. `level_error`
        1. `level_warn`
        1. `level_debug`
        1. `level_info`
            > NS_LOG_INFO(...)
        1. `level_function`
        1. `level_logic`
        1. `level_all`
        1. `all`

    - Enable all modules

    ```shell
    $ NS_LOG="*=level_function" ./waf --run scratch/myfirst
        or
    $ export NS_LOG="*=level_function"
    ```

    - Output log

    ```
    $ ./waf --run scratch/myfirst > out.log 2>&1
    ```

+ PCAP Tracing
    > Dump the `*.pcap` file

    ```c++
        ...
    // output pcap file name
    #if 1
        pointToPoint.EnablePcapAll ("myfirst");
    #else
        // only generate pcap file of NodeId-DeviceId
        // pointToPoint::EnablePcap (filename, <NodeId>, <DeviceId>);
        pointToPoint::EnablePcap ("myfirst", 0, 0);
    #endif
        ...
    Simulator::Run()
    ```

    - pcap file naming

    ```
    <Output_name>-<Node_number>-<NetDevice_number>.pcap
    ```

    - View pcap file

    ```
    $ tcpdump -nn -tt -r second-0-0.pcap
    ```

+ gnuplot

```
$ sudo apt-get install gnuplot

# generate data
$ ./waf --run scratch/fifth > cwnd.dat 2>&1

# convert to *.png
$ gnuplot

  gnuplot> set terminal png size 640,480
  gnuplot> set output "cwnd.png"
  gnuplot> plot "cwnd.dat" using 1:2 title 'Congestion Window' with linespoints
  gnuplot> exit
```

# MISC

+ IPv6
    - address format

    ```
    # hex
    [16 bits] * 8
    xxxx : xxxx : xxxx : xxxx : xxxx : xxxx : xxxx : xxxx
    ```

    - address representation
        1. One or more leading zeroes from any groups of *hexadecimal* digits are removed;
        For example, the group `0042` is converted to `42`.

        ```
                        2001:0DB8:0000:0000:0000:0000:1428:57ab
        abbreviating    2001:DB8:0:0:0:0:1428:57ab
        ```

        1. Consecutive sections of zeroes are replaced with a double colon `::`.
        The double colon may only be used once in an address

        ```
                        2001:0DB8:0000:0000:0000:0000:1428:57ab
        abbreviating    2001:DB8:0::0:1428:57ab
        abbreviating    2001:DB8::1428:57ab

        Error abbreviating  2001::25de::cade (two double colon)
        ```
    - Loopback address

    ```
                    0000:0000:0000:0000:0000:0000:0000:0001
    abbreviating    ::1
    ```

    - IPv4 convert to IPv6

    ```
    [IPv4]
    decimal     : 135.75.43.52
    hexadecimal : 87.4B.2B.34

    [IPv6]
    hexadecimal > 0000:0000:0000:0000:0000:ffff:874B:2B34
    abbreviating> ::ffff:874B:2B34
    IPv4-compatible address> ::ffff:135.75.43.52
    ```



