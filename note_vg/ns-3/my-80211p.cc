/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */
/*
 * Copyright (c) 2005,2006,2007 INRIA
 * Copyright (c) 2013 Dalian University of Technology
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Author: Mathieu Lacage <mathieu.lacage@sophia.inria.fr>
 * Author: Junling Bu <linlinjavaer@gmail.com>
 *
 */
/**
 * This example shows basic construction of an 802.11p node.  Two nodes
 * are constructed with 802.11p devices, and by default, one node sends a single
 * packet to another node (the number of packets and interval between
 * them can be configured by command-line arguments).  The example shows
 * typical usage of the helper classes for this mode of WiFi (where "OCB" refers
 * to "Outside the Context of a BSS")."
 */

#include <cstdlib>
#include <ctime>
#include "ns3/vector.h"
#include "ns3/string.h"
#include "ns3/socket.h"
#include "ns3/double.h"
#include "ns3/config.h"
#include "ns3/log.h"
#include "ns3/command-line.h"
#include "ns3/mobility-model.h"
#include "ns3/yans-wifi-helper.h"
#include "ns3/position-allocator.h"
#include "ns3/mobility-helper.h"
#include "ns3/internet-stack-helper.h"
#include <iostream>

#include "ns3/ocb-wifi-mac.h"
#include "ns3/wifi-80211p-helper.h"
#include "ns3/wave-mac-helper.h"
#include "ns3/seq-ts-header.h"

#include "ns3/wifi-radio-energy-model-helper.h"
#include "ns3/energy-module.h"

#include "ns3/netanim-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("MyWifiSimpleOcb");

/*
 * In WAVE module, there is no net device class named like "Wifi80211pNetDevice",
 * instead, we need to use Wifi80211pHelper to create an object of
 * WifiNetDevice class.
 *
 * usage:
 *  NodeContainer nodes;
 *  NetDeviceContainer devices;
 *  nodes.Create (2);
 *  YansWifiPhyHelper wifiPhy = YansWifiPhyHelper::Default ();
 *  YansWifiChannelHelper wifiChannel = YansWifiChannelHelper::Default ();
 *  wifiPhy.SetChannel (wifiChannel.Create ());
 *  NqosWaveMacHelper wifi80211pMac = NqosWave80211pMacHelper::Default();
 *  Wifi80211pHelper wifi80211p = Wifi80211pHelper::Default ();
 *  devices = wifi80211p.Install (wifiPhy, wifi80211pMac, nodes);
 *
 * The reason of not providing a 802.11p class is that most of modeling
 * 802.11p standard has been done in wifi module, so we only need a high
 * MAC class that enables OCB mode.
 */

class MyExample
{
public:

    /**
     * \brief Constructor
     * \return none
     */
    MyExample();

    /**
     * \brief Destructor
     * \return none
     */
    virtual ~MyExample();

    /// Send example function
    void SendExample (void);

private:
    /**
     * Send one packet function
     */
    void SendPacket(uint32_t local_node_id);

    /**
     * Receive function
     * \param dev the device
     * \param pkt the packet
     * \param protocol the protocol
     * \param address the sender address
     * \returns true if successful
     */
    bool ReceivePacket (Ptr<NetDevice> dev, Ptr<const Packet> pkt, uint16_t protocol, const Address &address);

    /// Create nodes function
    void CreateNodes (void);

    uint32_t                        m_numNodes; ///< number of nodes
    NodeContainer                   m_nodeContainer; ///< the nodes
    NetDeviceContainer              m_devices; ///< the devices
    DeviceEnergyModelContainer      m_deviceModels;

    int                             m_nodeSpeed; ///< in m/s
    int                             m_nodePause; ///< in s
    double                          m_txp; ///< distance
    int64_t                         m_streamIndex;

};

MyExample::MyExample()
    : m_numNodes(40),
      m_nodeSpeed(20),
      m_nodePause(0),
      m_txp(20),
      m_streamIndex(0)
{
}

MyExample::~MyExample()
{
}

bool MyExample::ReceivePacket(Ptr<NetDevice> device, Ptr<const Packet> packet, uint16_t protocol, const Address &address)
{
    SeqTsHeader     seqTs;
    packet->PeekHeader (seqTs);

#if 0
    std::cout << "receive a packet: " << std::endl
              << "  sequence = " << seqTs.GetSeq () << "," << std::endl
              << "  sendTime = " << seqTs.GetTs ().GetSeconds () << "s," << std::endl
              << "  recvTime = " << Now ().GetSeconds () << "s," << std::endl
              << "  packet size = " << packet->GetSize() << std::endl;
    std::cout << "  local = " << device->GetAddress() << std::endl;
    std::cout << "  from  = " << address << std::endl;
#endif

#if 0
    uint8_t     *buffer = new uint8_t[packet->GetSize()];
    packet->CopyData(buffer, packet->GetSize());
    for(uint32_t i = 0; i < packet->GetSize(); ++i)
        printf("%02x ", buffer[i]);
    printf("\n");
    delete[] buffer;
#endif
    return true;
}

void MyExample::SendPacket(uint32_t local_node_id)
{
    static int          sent_cnt = 0;
    Ptr<NetDevice>      device = DynamicCast<NetDevice> (m_devices.Get (local_node_id));
    printf("\nsend...%d\n", sent_cnt);

#if 0
    std::ostringstream      msg;
    msg << "Hello!" << '\0';
    Ptr<Packet>     packet = Create<Packet>((uint8_t*) msg.str().c_str(), msg.str().length());
#else
    uint8_t     tmp[100] = {0};
    snprintf((char*)tmp, 100, "%s", "123456");
    Ptr<Packet>     packet = Create<Packet>((uint8_t*)tmp, strlen((const char*)tmp) + 1);
#endif

    Address         address = device->GetBroadcast();
    SeqTsHeader     seqTs;

    seqTs.SetSeq (sent_cnt++);
    packet->AddHeader (seqTs);

    device->Send(packet, address, 1);
}

void
MyExample::CreateNodes (void)
{
    std::string     phyMode ("OfdmRate6MbpsBW10MHz");

    m_nodeContainer.Create (m_numNodes);

    // The below set of helpers will help us to put together the wifi NICs we want
    YansWifiPhyHelper       wifiPhy =  YansWifiPhyHelper::Default ();
    YansWifiChannelHelper   wifiChannel = YansWifiChannelHelper::Default ();
    Ptr<YansWifiChannel>    channel = wifiChannel.Create ();

    wifiPhy.SetChannel (channel);
    wifiPhy.SetPcapDataLinkType (WifiPhyHelper::DLT_IEEE802_11); // ns-3 supports generate a pcap trace
    wifiPhy.Set("TxPowerStart", DoubleValue(m_txp));
    wifiPhy.Set("TxPowerEnd", DoubleValue(m_txp));

    NqosWaveMacHelper   wifi80211pMac = NqosWaveMacHelper::Default ();
    Wifi80211pHelper    wifi80211p = Wifi80211pHelper::Default ();
#if 0
    wifi80211p.EnableLogComponents ();      // Turn on all Wifi 802.11p logging
#endif

    wifi80211p.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                        "DataMode", StringValue (phyMode),
                                        "ControlMode", StringValue (phyMode));

    m_devices = wifi80211p.Install (wifiPhy, wifi80211pMac, m_nodeContainer);

    // Tracing
    wifiPhy.EnablePcap ("simple-80211p", m_devices);

    /**
     *  mobility mode
     */
    ObjectFactory       pos;
    pos.SetTypeId("ns3::RandomBoxPositionAllocator");
    pos.Set("X", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=1500.0]"));
    pos.Set("Y", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=500.0]"));

    // we need antenna height uniform [1.0 .. 2.0] for loss model
    pos.Set("Z", StringValue("ns3::UniformRandomVariable[Min=1.0|Max=2.0]"));


    Ptr<PositionAllocator>      taPositionAlloc = pos.Create()->GetObject<PositionAllocator>();
    m_streamIndex += taPositionAlloc->AssignStreams(m_streamIndex);

    std::stringstream       ssSpeed;
    ssSpeed << "ns3::UniformRandomVariable[Min=0.0|Max=" << m_nodeSpeed << "]";

    std::stringstream       ssPause;
    ssPause << "ns3::ConstantRandomVariable[Constant=" << m_nodePause << "]";

    //------------------------------
    MobilityHelper          mobility;
    mobility.SetMobilityModel("ns3::RandomWaypointMobilityModel",
                                "Speed", StringValue(ssSpeed.str()),
                                "Pause", StringValue(ssPause.str()),
                                "PositionAllocator", PointerValue(taPositionAlloc));
    mobility.SetPositionAllocator(taPositionAlloc);

    mobility.Install(m_nodeContainer);
    m_streamIndex += mobility.AssignStreams(m_nodeContainer, m_streamIndex);

    /**
     *  attach callback of recv for all nodes
     */
    for (uint32_t i = 0; i != m_devices.GetN (); ++i) {
        Ptr<NetDevice>      dev = DynamicCast<NetDevice> (m_devices.Get (i));
        dev->SetReceiveCallback (MakeCallback (&MyExample::ReceivePacket, this));
    }
}

void
MyExample::SendExample ()
{
    CreateNodes ();

    Simulator::Stop (Seconds (5.0));

    Ptr<UniformRandomVariable>  uv = CreateObject<UniformRandomVariable> ();
    for(float act_time = 0.5f; act_time < 4.5f; act_time += 0.5f)
    {
        Simulator::Schedule (Seconds(act_time), &MyExample::SendPacket, this, rand() % m_numNodes);
    }

    AnimationInterface  anim("my-80211p.xml");
    Simulator::Run ();
    Simulator::Destroy ();
}

int main (int argc, char *argv[])
{
    CommandLine     cmd;
    cmd.Parse (argc, argv);

    srand(time(NULL));

    MyExample    example;
    std::cout << "run my case:" << std::endl;
    example.SendExample ();

    return 0;
}
