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

#include "ns3/packet.h"
#include "ns3/simulator.h"
#include "ns3/mobility-model.h"
#include "ns3/net-device.h"
#include "ns3/node.h"
#include "ns3/log.h"
#include "ns3/pointer.h"
#include "ns3/object-factory.h"

//#include "ns3/object.h"
//#include "ns3/mobility-model.h"
//#include "ns3/node.h"
//#include "ns3/log.h"
#include "ns3/double.h"

#include "sw-channel.h"
#include "ns3/propagation-loss-model.h"

NS_LOG_COMPONENT_DEFINE ("SwChannel");

namespace ns3 {

NS_OBJECT_ENSURE_REGISTERED (SwChannel);

TypeId
SwChannel::GetTypeId ()
{
  static TypeId tid = TypeId ("ns3::SwChannel")
    .SetParent<Object> ()
    .AddConstructor<SwChannel> ()
    .AddAttribute ("PropagationLossModel", "A pointer to the propagation loss model attached to this channel.",
                   PointerValue (CreateObject<LogDistancePropagationLossModel> ()),
                   MakePointerAccessor (&SwChannel::m_loss),
                   MakePointerChecker<PropagationLossModel> ())
    .AddAttribute ("PropagationDelayModel", "A pointer to the propagation delay model attached to this channel.",
                   PointerValue (CreateObject<ConstantSpeedPropagationDelayModel> ()),
                   MakePointerAccessor (&SwChannel::m_delay),
                   MakePointerChecker<ConstantSpeedPropagationDelayModel> ())
    .AddAttribute ("DeleteTxFlowLater",
                   "Delete tx-flow later a certain time",
                   TimeValue (NanoSeconds (100)),
                   MakeTimeAccessor (&SwChannel::m_delNoiseEntryLater),
                   MakeTimeChecker ())
    .AddAttribute ("NoiseFloor",
                   "Noise Floor (dBm)",
                   DoubleValue (-120.0),
                   MakeDoubleAccessor (&SwChannel::m_noiseFloor),
                   MakeDoubleChecker<double> ())
    ;
  return tid;
}
SwChannel::SwChannel ()
  : Channel ()
{
}
SwChannel::~SwChannel ()
{}
void
SwChannel::Clear ()
{
  m_devList.clear ();
  m_noiseEntry.clear ();
}
uint32_t
SwChannel::GetNDevices () const
{
	return m_devList.size ();
}
Ptr<NetDevice>
SwChannel::GetDevice (uint32_t i) const
{
	return m_devList[i].first;
}
void
SwChannel::AddDevice (Ptr<SwNetDevice> dev, Ptr<SwPhy> phy)
{
  NS_LOG_INFO ("CH: Adding dev/phy pair number " << m_devList.size ()+1);
  m_devList.push_back (std::make_pair (dev, phy));
}

bool 
SwChannel::SendPacket (Ptr<SwPhy> phy, Ptr<Packet> packet, double txPower, Time txDuration)
{
  NS_LOG_FUNCTION ("");
  Ptr<MobilityModel> senderMobility = 0;
  Ptr<MobilityModel> recvMobility = 0;

  // NoiseEntry stores information, how much signal a node will get and how long that signal will exist.
  // This information will be used by PHY layer to obtain SINR value.
  NoiseEntry ne;
  ne.packet = packet;
  ne.txDuration = txDuration;

  SwDeviceList::const_iterator it = m_devList.begin ();
  for (; it != m_devList.end (); it++)
    {
      if (phy == it->second)
        {
          senderMobility = it->first->GetNode ()->GetObject<MobilityModel> ();
          break;
        }
    }
  NS_ASSERT (senderMobility != 0);
  
  Simulator::Schedule (txDuration, &SwChannel::SendPacketDone, this, phy, packet);
  
  uint32_t j = 0;
  it = m_devList.begin ();
  for (; it != m_devList.end (); it++)
    {
      if (phy != it->second)
        {
          recvMobility = it->first->GetNode ()->GetObject<MobilityModel> ();
          Time delay = m_delay->GetDelay (senderMobility, recvMobility); // propagation delay
          double rxPower = m_loss->CalcRxPower (txPower, senderMobility, recvMobility); // receive power (dBm)

          uint32_t dstNodeId = it->first->GetNode ()->GetId ();
          Ptr<Packet> copy = packet->Copy ();

          ne.packet = copy;
          ne.phy = it->second;
          ne.rxPower = rxPower;
          ne.txEnd = Simulator::Now () + txDuration + delay;

          Simulator::ScheduleWithContext (dstNodeId, delay, &SwChannel::ReceivePacket, this, j, ne);
        }
      j++;
    }

  return true;
}
void 
SwChannel::SendPacketDone (Ptr<SwPhy> phy, Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("");
  phy->SendPacketDone (packet);
}

void 
SwChannel::ReceivePacket (uint32_t i, NoiseEntry ne)
{
  NS_LOG_FUNCTION ("");
  m_noiseEntry.push_back (ne);
  m_devList[i].second->ReceivePacket (ne.packet, ne.txDuration, ne.rxPower);
  Simulator::Schedule (ne.txDuration, &SwChannel::ReceivePacketDone, this, i, ne);
}
void 
SwChannel::ReceivePacketDone (uint32_t i, NoiseEntry ne)
{
  NS_LOG_FUNCTION ("");
  m_devList[i].second->ReceivePacketDone (ne.packet, ne.rxPower);
  // If concurrent transmissions end at the same time, some of them can be missed from SINR calculation
  // So, delete a noise entry a few seconds later
  Simulator::Schedule (m_delNoiseEntryLater, &SwChannel::DeleteNoiseEntry, this, ne);
}

void
SwChannel::DeleteNoiseEntry (NoiseEntry ne)
{
  NS_LOG_FUNCTION (this);
  std::list<NoiseEntry>::iterator it = m_noiseEntry.begin ();
  for (; it != m_noiseEntry.end (); ++it)
    {
      if (it->packet == ne.packet && it->phy == ne.phy)
        {
          m_noiseEntry.erase (it);
          break;
        }
    }
}

double
SwChannel::GetNoiseW (Ptr<SwPhy> phy, Ptr<Packet> signal)
{
  Time now = Simulator::Now ();
  double noiseW = DbmToW (m_noiseFloor);
  std::list<NoiseEntry>::iterator it = m_noiseEntry.begin ();
  // calculate the cumulative noise power
  for (; it != m_noiseEntry.end (); ++it)
    {
      if (it->phy == phy && it->packet != signal && it->txEnd + NanoSeconds (1) >= now)
        {
          noiseW += DbmToW (it->rxPower);
        }
    }
  return noiseW;
}

double
SwChannel::DbmToW (double dbm)
{
  double mw = pow(10.0,dbm/10.0);
  return mw / 1000.0;
}

} // namespace ns3
