//
// Network topology
//
//  n0
//     \ p-p
//      \          (shared csma/cd)      p-p
//       n2 -------------------------n3--------n7
//      /            |        |
//     / p-p        n4--n8    n5 ---------- n6
//   n1                              p-p
//
// - CBR/UDP flows from n0 to n6
// - Tracing of queues and packet receptions to file "mixed-global-routing.tr"

#include <iostream>
#include <fstream>
#include <string>
#include <cassert>

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/csma-module.h"
#include "ns3/applications-module.h"
#include "ns3/internet-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("MixedGlobalRoutingExample");

int
main (int argc, char *argv[])
{
    Config::SetDefault ("ns3::OnOffApplication::PacketSize", UintegerValue (210));
    Config::SetDefault ("ns3::OnOffApplication::DataRate", StringValue ("448kb/s"));

    // Allow the user to override any of the defaults and the above
    // Bind ()s at run-time, via command-line arguments
    CommandLine cmd;
    cmd.Parse (argc, argv);

    NS_LOG_INFO ("Create nodes.");
    NodeContainer c;
    c.Create (9);
    NodeContainer n0n2 = NodeContainer (c.Get (0), c.Get (2));
    NodeContainer n1n2 = NodeContainer (c.Get (1), c.Get (2));
    NodeContainer n5n6 = NodeContainer (c.Get (5), c.Get (6));
    NodeContainer n3n7 = NodeContainer (c.Get (3), c.Get (7));
    NodeContainer n4n8 = NodeContainer (c.Get (4), c.Get (8));
    NodeContainer n2345 = NodeContainer (c.Get (2), c.Get (3), c.Get (4), c.Get (5));

    InternetStackHelper internet;
    internet.Install (c);

    // We create the channels first without any IP addressing information
    NS_LOG_INFO ("Create channels.");
    PointToPointHelper p2p;
    p2p.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
    p2p.SetChannelAttribute ("Delay", StringValue ("2ms"));
    NetDeviceContainer d0d2 = p2p.Install (n0n2);

    NetDeviceContainer d1d2 = p2p.Install (n1n2);

    p2p.SetDeviceAttribute ("DataRate", StringValue ("1500kbps"));
    p2p.SetChannelAttribute ("Delay", StringValue ("10ms"));
    NetDeviceContainer d5d6 = p2p.Install (n5n6);

    NetDeviceContainer d3d7 = p2p.Install (n3n7);

    NetDeviceContainer d4d8 = p2p.Install (n4n8);

    // We create the channels first without any IP addressing information
    CsmaHelper csma;
    csma.SetChannelAttribute ("DataRate", StringValue ("5Mbps"));
    csma.SetChannelAttribute ("Delay", StringValue ("2ms"));
    NetDeviceContainer d2345 = csma.Install (n2345);

    // Later, we add IP addresses.
    NS_LOG_INFO ("Assign IP Addresses.");
    Ipv4AddressHelper ipv4;
    ipv4.SetBase ("10.1.1.0", "255.255.255.0");
    ipv4.Assign (d0d2);

    ipv4.SetBase ("10.1.2.0", "255.255.255.0");
    ipv4.Assign (d1d2);

    ipv4.SetBase ("10.1.3.0", "255.255.255.0");
    Ipv4InterfaceContainer i5i6 = ipv4.Assign (d5d6);

    ipv4.SetBase ("10.1.4.0", "255.255.255.0");
    Ipv4InterfaceContainer i3i7 = ipv4.Assign (d3d7);

    ipv4.SetBase ("10.1.5.0", "255.255.255.0");
    Ipv4InterfaceContainer i4i8 = ipv4.Assign (d4d8);

    ipv4.SetBase ("10.250.1.0", "255.255.255.0");
    ipv4.Assign (d2345);

    // Create router nodes, initialize routing database and set up the routing
    // tables in the nodes.
    Ipv4GlobalRoutingHelper::PopulateRoutingTables ();

    // Create the OnOff application to send UDP datagrams of size
    // 210 bytes at a rate of 448 Kb/s
    NS_LOG_INFO ("Create Applications.");
    uint16_t port = 9;   // Discard port (RFC 863)
    OnOffHelper onoff ("ns3::UdpSocketFactory",
                       InetSocketAddress (i5i6.GetAddress (1), port));
    onoff.SetConstantRate (DataRate ("300bps"));
    onoff.SetAttribute ("PacketSize", UintegerValue (50));

    ApplicationContainer apps = onoff.Install (c.Get (0));
    apps.Start (Seconds (1.0));
    apps.Stop (Seconds (10.0));

    AsciiTraceHelper ascii;
    Ptr<OutputStreamWrapper> stream = ascii.CreateFileStream ("mixed-global-routing.tr");
    p2p.EnableAsciiAll (stream);
    csma.EnableAsciiAll (stream);

    p2p.EnablePcapAll ("mixed-global-routing");
    csma.EnablePcapAll ("mixed-global-routing", false);

    NS_LOG_INFO ("Run Simulation.");
    Simulator::Run ();
    Simulator::Destroy ();
    NS_LOG_INFO ("Done.");
}

// 參考NS3源碼, 初步搭建了一個網絡拓撲結構，可以添加子網。

// 執行  . / waf --run test  --vis

// 將輸出網絡拓撲結構。

