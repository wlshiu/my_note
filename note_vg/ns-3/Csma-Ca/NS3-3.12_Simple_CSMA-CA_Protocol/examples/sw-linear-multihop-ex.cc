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

// This example generates the route from node 0 to node N using AODV and
// transmits UDP packets periodically
//
//    Node 0 -------> Node 1 -------> Node 2 -------> Node N
//  (0, 0, 0)      (150, 0, 0)     (300, 0, 0)     (450, 0, 0)

#include "ns3/core-module.h"
#include "ns3/mobility-module.h"
#include "ns3/tools-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/aodv-module.h"

#include "ns3/sw-net-device.h"
#include "ns3/sw-channel.h"
#include "ns3/sw-mac-csma-helper.h"
#include "ns3/sw-phy-basic-helper.h"

#define NUM_NODE 4

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("SwLinearMultihopEx");

void InitializeReport ();
void Report (Ptr<UdpServer> server);
void CtsTimeout (std::string context, uint32_t nodeId, uint32_t iface);
void AckTimeout (std::string context, uint32_t nodeId, uint32_t iface);
void SendDataDone (std::string context, uint32_t nodeId, uint32_t iface, bool success);
void Enqueue (std::string context, uint32_t nodeId, uint32_t iface);

int m_nCtsTimeout [NUM_NODE];
int m_nAckTimeout [NUM_NODE];
int m_nSendDataSuccess [NUM_NODE];
int m_nSendDataFail [NUM_NODE];
int m_nEnqueue [NUM_NODE];

int main (int argc, char *argv[])
{
  LogComponentEnable("SwMacCsma", LogLevel(LOG_FUNCTION | LOG_DEBUG | LOG_PREFIX_TIME | LOG_PREFIX_NODE) );
  //LogComponentEnable("SwPhy", LogLevel(LOG_FUNCTION | LOG_DEBUG | LOG_PREFIX_TIME | LOG_PREFIX_NODE) );
  //LogComponentEnable("SwChannel", LogLevel(LOG_FUNCTION | LOG_INFO | LOG_PREFIX_TIME | LOG_PREFIX_NODE) );
  LogComponentEnable("SwLinearMultihopEx", LogLevel(LOG_INFO) );
  
  Time stopTime = Seconds (30);
  
  NodeContainer nodes;
  nodes.Create (NUM_NODE);
  
  Ptr<SwChannel> swChan = CreateObject<SwChannel> ();
  SwMacCsmaHelper swMac = SwMacCsmaHelper::Default ();
  SwPhyBasicHelper swPhy = SwPhyBasicHelper::Default ();
  SwHelper sw;
  NetDeviceContainer devices = sw.Install (nodes, swChan, swPhy, swMac);
  
  MobilityHelper mobility;
  Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator> ();
  for (double i = 0; i <= 150.0 * NUM_NODE; i = i + 150.0) {
    positionAlloc->Add (Vector (i, 0.0, 0.0));
  }
  mobility.SetPositionAllocator (positionAlloc);
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.Install (nodes);
  
  // Each node has a unique object for routing protocol 
  // but all these objects share a single routing table
  AodvHelper aodv;
  aodv.Set ("HelloInterval", TimeValue (Seconds (50)));
  aodv.Set ("ActiveRouteTimeout", TimeValue (Seconds (50)));
  aodv.Set ("DestinationOnly", BooleanValue (true));
  InternetStackHelper internet;
  internet.SetRoutingHelper (aodv);
  internet.Install (nodes);
  
  Ipv4AddressHelper ipv4;
  ipv4.SetBase ("10.1.1.0", "255.255.255.0");
  Ipv4InterfaceContainer iface = ipv4.Assign (devices);
  
  // for routing and/or ARP setup
  UdpServerHelper server (4000);
  UdpClientHelper client (iface.GetAddress (NUM_NODE - 1), 4000);
  ApplicationContainer apps = server.Install (nodes.Get(NUM_NODE - 1));
  apps = client.Install (nodes.Get (0));
  client.SetAttribute ("MaxPackets", UintegerValue (1));
  apps.Start (Seconds (0.1));
  apps.Stop (Seconds (1.0));
  
  Simulator::Schedule (Seconds (1.0), &InitializeReport);
  
  // real transmission
  UdpServerHelper server2 (5000);
  ApplicationContainer apps2 = server2.Install (nodes.Get(NUM_NODE - 1));
  UdpClientHelper client2 (iface.GetAddress (NUM_NODE - 1), 5000);
  client2.SetAttribute ("MaxPackets", UintegerValue (5));
  client2.SetAttribute ("Interval", TimeValue (Seconds (1)));
  client2.SetAttribute ("PacketSize", UintegerValue (700));
  apps = client2.Install (nodes.Get (0));
  apps.Start (Seconds (3.0));
  apps.Stop (stopTime);
  
  Config::Connect ("/NodeList/*/DeviceList/*/$ns3::SwNetDevice/Mac/CtsTimeout", MakeCallback (&CtsTimeout));
  Config::Connect ("/NodeList/*/DeviceList/*/$ns3::SwNetDevice/Mac/AckTimeout", MakeCallback (&AckTimeout));
  Config::Connect ("/NodeList/*/DeviceList/*/$ns3::SwNetDevice/Mac/Enqueue", MakeCallback (&Enqueue));
  Config::Connect ("/NodeList/*/DeviceList/*/$ns3::SwNetDevice/Mac/SendDataDone", MakeCallback (&SendDataDone));
  
  Simulator::Stop (stopTime);
  Simulator::Schedule (stopTime - NanoSeconds (5), &Report, server2.GetServer ());
  Simulator::Run ();
  Simulator::Destroy ();
  
  
  return 0;
}

void CtsTimeout (std::string context, uint32_t nodeId, uint32_t iface) {
  m_nCtsTimeout [nodeId]++;
}
void AckTimeout (std::string context, uint32_t nodeId, uint32_t iface) {
  m_nAckTimeout [nodeId]++;
}
void SendDataDone (std::string context, uint32_t nodeId, uint32_t iface, bool success) {
  if (success)
    m_nSendDataSuccess [nodeId]++;
  else
    m_nSendDataFail [nodeId]++;
}
void Enqueue (std::string context, uint32_t nodeId, uint32_t iface) {
  m_nEnqueue [nodeId]++;
}
void InitializeReport ()
{
  for (uint16_t i = 0; i < NUM_NODE; i++) {
    m_nEnqueue [i] = 0;
    m_nCtsTimeout [i] = 0;
    m_nAckTimeout [i] = 0;
    m_nSendDataSuccess [i] = 0;
    m_nSendDataFail [i] = 0;
  }
}
void Report (Ptr<UdpServer> server)
{
  int nEnqueue = 0;
  int nCtsTimeout = 0;
  int nAckTimeout = 0;
  int nSendDataSuccess = 0;
  int nSendDataFail = 0;
  
  for (uint16_t i = 0; i < NUM_NODE; i++) {
    NS_LOG_INFO ("Node ID: " << i <<
                  " #enqueue: " << m_nEnqueue [i] <<
                  " #ctsTimeout: " << m_nCtsTimeout [i] <<
                  " #ackTimeout: " << m_nAckTimeout [i] <<
                  " #sendDataSuccess: " << m_nSendDataSuccess [i] <<
                  " #sendDataFail: " << m_nSendDataFail [i]);
    nEnqueue += m_nEnqueue [i];
    nCtsTimeout += m_nCtsTimeout [i];
    nAckTimeout += m_nAckTimeout [i];
    nSendDataSuccess += m_nSendDataSuccess [i];
    nSendDataFail += m_nSendDataFail [i];
  }
  NS_LOG_INFO ("TOTAL #enqueue: " << nEnqueue << " #ctsTimeout: " << nCtsTimeout <<
               " #ackTimeout: " << nAckTimeout << " #sendDataSuccess: " << nSendDataSuccess <<
               " #sendDataFail: " << nSendDataFail);
}

