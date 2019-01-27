/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */
/*
 * Copyright (c) 2010 University of Arizona
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as 
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * Author: Junseok Kim <junseok@email.arizona.edu> <engr.arizona.edu/~junseok>
 */

// Node 0 periodically transmits UDP packet to Node 1 and Node 2 is overhearing
//      Node 0 ----------> Node 1              Node 2
//    (0, 0, 0)         (150, 0, 0)         (300, 0, 0)

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/mobility-module.h"
#include "ns3/tools-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"

#include "ns3/sw-channel.h"
#include "ns3/sw-mac-csma-helper.h"
#include "ns3/sw-phy-basic-helper.h"
#include <vector>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("SwSimpleEx");

int main (int argc, char *argv[])
{
  LogComponentEnable("SwMacCsma", LOG_LEVEL_ALL);
  //LogComponentEnable("SwPhy", LOG_LEVEL_ALL);
  //LogComponentEnable("SwChannel", LOG_LEVEL_ALL);
  
  uint8_t numNodes = 3;
  
  NodeContainer nodes;
  nodes.Create (numNodes);
  
  Ptr<SwChannel> swChan = CreateObject<SwChannel> ();
  SwMacCsmaHelper swMac = SwMacCsmaHelper::Default ();
  SwPhyBasicHelper swPhy = SwPhyBasicHelper::Default ();
  SwHelper sw;
  NetDeviceContainer devices = sw.Install (nodes, swChan, swPhy, swMac);
  
  MobilityHelper mobility;
  Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator> ();
  positionAlloc->Add (Vector (0.0, 0.0, 0.0));
  positionAlloc->Add (Vector (150.0, 0.0, 0.0));
  positionAlloc->Add (Vector (300.0, 0.0, 0.0));
  mobility.SetPositionAllocator (positionAlloc);
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.Install (nodes);
  
  InternetStackHelper internet;
  internet.Install (nodes);
  
  Ipv4AddressHelper ipv4;
  ipv4.SetBase ("10.1.1.0", "255.255.255.0");
  Ipv4InterfaceContainer iface = ipv4.Assign (devices);
  
  UdpEchoServerHelper echoServer (9);

  ApplicationContainer serverApps = echoServer.Install (nodes.Get (1));
  serverApps.Start (Seconds (1.0));
  serverApps.Stop (Seconds (5.0));

  UdpEchoClientHelper echoClient (iface.GetAddress (1), 9);
  echoClient.SetAttribute ("MaxPackets", UintegerValue (10));
  echoClient.SetAttribute ("Interval", TimeValue (Seconds (0.5)));
  echoClient.SetAttribute ("PacketSize", UintegerValue (500));

  ApplicationContainer clientApps;
  clientApps = echoClient.Install (nodes.Get (0));
  clientApps.Start (Seconds (2.0));
  clientApps.Stop (Seconds (5.0));
  
  Simulator::Run ();
  Simulator::Destroy ();

  return 0;
}

