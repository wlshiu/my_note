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

#include "ns3/simulator.h"
#include "ns3/log.h"
#include "ns3/uinteger.h"
#include "ns3/double.h"
#include "ns3/mac48-address.h"
#include "sw-mac.h"
#include "sw-phy.h"

NS_LOG_COMPONENT_DEFINE ("SwPhy");

namespace ns3 {

NS_OBJECT_ENSURE_REGISTERED (SwPhy);

SwPhy::SwPhy ()
 : m_device (0), 
   m_mac (0),
   m_channel (0),
   m_pktRx (0)
{
  m_csBusy = false;
  m_csBusyEnd = Seconds (0);
}
SwPhy::~SwPhy ()
{
  Clear ();
}
void
SwPhy::Clear ()
{
  m_pktRx = 0;
}
TypeId
SwPhy::GetTypeId (void)
{
  static TypeId tid = TypeId ("ns3::SwPhy")
    .SetParent<Object> ()
    .AddConstructor<SwPhy> ()
    .AddAttribute ("PreambleDuration",
                   "Duration (us) of Preamble of PHY Layer",
                   TimeValue (MicroSeconds (16)),
                   MakeTimeAccessor (&SwPhy::m_preambleDuration),
                   MakeTimeChecker ())
    .AddAttribute ("TrailerSize",
                   "Size of Trailer (e.g. FCS) (bytes)",
                   UintegerValue (2),
                   MakeUintegerAccessor (&SwPhy::m_trailerSize),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("HeaderSize",
                   "Size of Header (bytes)",
                   UintegerValue (3),
                   MakeUintegerAccessor (&SwPhy::m_headerSize),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("SinrTh",
                   "SINR Threshold",
                   DoubleValue (2),
                   MakeDoubleAccessor (&SwPhy::m_sinrTh),
                   MakeDoubleChecker<double> ())
    .AddAttribute ("CsPowerTh",
                   "Carrier Sense Threshold (dBm)",
                   DoubleValue (-110),
                   MakeDoubleAccessor (&SwPhy::m_csTh),
                   MakeDoubleChecker<double> ())
    .AddAttribute ("TxPower",
                   "Transmission Power (dBm)",
                   DoubleValue (10),
                   MakeDoubleAccessor (&SwPhy::SetTxPower),
                   MakeDoubleChecker<double> ())
    ;
  return tid;
}

void
SwPhy::SetDevice (Ptr<SwNetDevice> device)
{
  m_device = device;
}
void
SwPhy::SetMac (Ptr<SwMac> mac)
{
  m_mac = mac;
}
void
SwPhy::SetChannel (Ptr<SwChannel> channel)
{
  m_channel = channel;
}
void
SwPhy::SetTxPower (double dBm)
{
  m_txPower = dBm;
}

//-----------------------------------------------------------------
Ptr<SwChannel>
SwPhy::GetChannel ()
{
  return m_channel;
}
Mac48Address
SwPhy::GetAddress ()
{
  return m_mac->GetAddress ();
}
double
SwPhy::GetTxPower ()
{
  return m_txPower;
}
//----------------------------------------------------------------------
bool
SwPhy::SendPacket (Ptr<Packet> packet, bool rate)
{
  NS_LOG_FUNCTION ("");
  // RX might be interrupted by TX, but not vice versa
  if (m_state == TX) 
    {
      NS_LOG_DEBUG ("Already in transmission mode");
      return false;
    }
  
  m_state = TX;
  Time txDuration;
  if (rate) // transmit packet with data rate
    {
      txDuration = CalTxDuration (0, packet->GetSize (), 
                        m_mac->GetBasicRate (), m_mac->GetDataRate ());
    }
  else // transmit packets (e.g. RTS, CTS) with basic rate
    {
      txDuration = CalTxDuration (packet->GetSize (), 0, 
                        m_mac->GetBasicRate (), m_mac->GetDataRate ());
    }
  
  NS_LOG_DEBUG ("Tx will finish at " << (Simulator::Now () + txDuration).GetSeconds () << 
                "(" << txDuration.GetNanoSeconds() << "ns) txPower" << m_txPower);
  
  // forward to CHANNEL
  m_channel->SendPacket (Ptr<SwPhy> (this), packet, m_txPower, txDuration);
  
  return true;
}

void 
SwPhy::SendPacketDone (Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("");
  m_state = IDLE;
  m_mac->SendPacketDone (packet);
}

void 
SwPhy::ReceivePacket (Ptr<Packet> packet, Time txDuration, double_t rxPower)
{
  NS_LOG_FUNCTION ("rxPower" << rxPower << "busyEnd" << m_csBusyEnd);
  
  if (m_state == TX)
    {
      NS_LOG_INFO ("Drop packet due to half-duplex");
      return;
    }
  
  // Start RX when energy is bigger than carrier sense threshold 
  // 
  Time txEnd = Simulator::Now () + txDuration;
  if (rxPower > m_csTh && txEnd > m_csBusyEnd)
    {
      if (m_csBusy == false)
        {
          m_csBusy = true;
          m_pktRx = packet;
          m_mac->ReceivePacket (this, packet);
        }
      m_state = RX;
      m_csBusyEnd = txEnd;
    }
}

void 
SwPhy::ReceivePacketDone (Ptr<Packet> packet, double rxPower)
{
  NS_LOG_FUNCTION (m_csBusyEnd << Simulator::Now ());
  
  if (m_csBusyEnd <= Simulator::Now () + NanoSeconds (1))
    {
      m_csBusy = false;
    }
  
  if (m_state != RX)
    {
      NS_LOG_INFO ("Drop packet due to state");
      return;
    }
  
  if (packet == m_pktRx)
    {
      // We do support SINR !!
      double noiseW = m_channel->GetNoiseW (this, packet); // noise plus interference
      double rxPowerW = m_channel->DbmToW (rxPower);
      double sinr = rxPowerW / noiseW;
      if (sinr > m_sinrTh) {
        m_state = IDLE;
        m_mac->ReceivePacketDone (this, packet, true);
        return;
      }
    }
  
  if (! m_csBusy) // set MAC state IDLE
    {
      m_state = IDLE;
      m_mac->ReceivePacketDone (this, packet, false);
    }
}

bool 
SwPhy::IsIdle ()
{
  if (m_state == IDLE && !m_csBusy) { return true; }
  return false;
}

Time
SwPhy::CalTxDuration (uint32_t basicSize, uint32_t dataSize, double basicRate, double dataRate)
{
  double_t txHdrTime = (double)(m_headerSize + basicSize + m_trailerSize) * 8.0 / basicRate;
  double_t txMpduTime = (double)dataSize * 8.0 / dataRate;
  return m_preambleDuration + Seconds (txHdrTime) + Seconds (txMpduTime);
}

} // namespace ns3
