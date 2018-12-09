NS-3 guide
---

# Setup environment
```
$ ./ns3_env_setup.sh
$ wget https://www.nsnam.org/releases/ns-allinone-3.29.tar.bz2 ~/NS-3
$ cd ~/NS-3 && tar -jxf ns-allinone-3.29.tar.bz2
$ ./ns3_pre_build.sh ns-allinone-3.29
```

# Software architecture
```
build
├── bindings
├── c4che
├── examples    (obj files of examples)
├── lib         (ns-3 lib of .so of modules)
├── ns3         (header files)
├── scratch     (compiler working space)
├── src         (obj files of ns-3 modules)
└── utils       (obj files of utils)
```


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

    /**
     * Start simulation
     */
    Simulator::Run ();
    Simulator::Destroy ();
    return 0;
}

```

+ Compiler and Run

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
$ ./waf --command-template="gdb %s" --run <program-name>
```


