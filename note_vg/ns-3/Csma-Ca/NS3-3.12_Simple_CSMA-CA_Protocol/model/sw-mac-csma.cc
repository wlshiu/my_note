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

#include "ns3/attribute.h"
#include "ns3/uinteger.h"
#include "ns3/boolean.h"
#include "ns3/double.h"
#include "ns3/nstime.h"
#include "ns3/random-variable.h"
#include "ns3/log.h"
#include "ns3/trace-source-accessor.h"
#include "ns3/node.h"
#include "sw-mac-header.h"
#include "sw-mac-csma.h"

NS_LOG_COMPONENT_DEFINE ("SwMacCsma");

namespace ns3 {

NS_OBJECT_ENSURE_REGISTERED (SwMacCsma);

SwMacCsma::SwMacCsma ()
  : SwMac (),
    m_phy (0),
    m_state (IDLE),
    m_ccaTimeoutEvent (),
    m_backoffTimeoutEvent (),
    m_ctsTimeoutEvent (),
    m_ackTimeoutEvent (),
    m_sendCtsEvent (),
    m_sendAckEvent (),
    m_sendDataEvent (),
    m_retry (0),
    m_pktTx (0),
    m_pktData (0)
{
  m_cw = m_cwMin;
  m_nav = Simulator::Now ();
  m_localNav = Simulator::Now ();
  m_backoffRemain = Seconds (0);
  m_backoffStart = Seconds (0);
  m_sequence = 0;
}
SwMacCsma::~SwMacCsma ()
{
  Clear ();
}
void
SwMacCsma::Clear ()
{
  m_pktTx = 0;
  m_pktData = 0;
  m_pktQueue.clear ();
  m_seqList.clear ();
}

TypeId
SwMacCsma::GetTypeId (void)
{
  static TypeId tid = TypeId ("ns3::SwMacCsma")
    .SetParent<Object> ()
    .AddConstructor<SwMacCsma> ()
    .AddAttribute ("EnableRts",
                   "If true, RTS is enabled",
                   BooleanValue (true),
                   MakeBooleanAccessor (&SwMacCsma::m_rtsEnable),
                   MakeBooleanChecker ())
    .AddAttribute ("CwMin",
                   "Minimum value of CW",
                   UintegerValue (8),
                   MakeUintegerAccessor (&SwMacCsma::m_cwMin),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("CwMax",
                   "Maximum value of CW",
                   UintegerValue (1024),
                   MakeUintegerAccessor (&SwMacCsma::m_cwMax),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("SlotTime",
                   "Time slot duration for MAC backoff",
                   TimeValue (MicroSeconds (15)),
                   MakeTimeAccessor (&SwMacCsma::m_slotTime),
                   MakeTimeChecker ())
    .AddAttribute ("SifsTime",
                   "Short Inter-frame Space",
                   TimeValue (MicroSeconds (30)),
                   MakeTimeAccessor (&SwMacCsma::m_sifs),
                   MakeTimeChecker ())
    .AddAttribute ("DifsTime",
                   "DFS Inter-frame Space",
                   TimeValue (MicroSeconds (60)),
                   MakeTimeAccessor (&SwMacCsma::m_difs),
                   MakeTimeChecker ())
    .AddAttribute ("BasicRate",
                   "Transmission Rate (bps) for Control Packets",
                   DoubleValue (2000000), // 2Mbps
                   MakeDoubleAccessor (&SwMacCsma::m_basicRate),
                   MakeDoubleChecker<double> ())
    .AddAttribute ("DataRate",
                   "Transmission Rate (bps) for Data Packets",
                   DoubleValue (11000000), // 11Mbps
                   MakeDoubleAccessor (&SwMacCsma::m_dataRate),
                   MakeDoubleChecker<double> ())
    .AddAttribute ("QueueLimit",
                   "Maximum packets to queue at MAC",
                   UintegerValue (20),
                   MakeUintegerAccessor (&SwMacCsma::m_queueLimit),
                   MakeUintegerChecker<uint32_t> ())
    .AddAttribute ("RtsRetryLimit",
                   "Maximum Limit for RTS Retransmission",
                   UintegerValue (7),
                   MakeUintegerAccessor (&SwMacCsma::m_rtsRetryLimit),
                   MakeUintegerChecker<uint16_t> ())
    .AddAttribute ("DataRetryLimit",
                   "Maximum Limit for Data Retransmission",
                   UintegerValue (2),
                   MakeUintegerAccessor (&SwMacCsma::m_dataRetryLimit),
                   MakeUintegerChecker<uint16_t> ())
    .AddTraceSource ("CtsTimeout",
                     "Trace Hookup for CTS Timeout",
                     MakeTraceSourceAccessor (&SwMacCsma::m_traceCtsTimeout))
    .AddTraceSource ("AckTimeout",
                     "Trace Hookup for ACK Timeout",
                     MakeTraceSourceAccessor (&SwMacCsma::m_traceAckTimeout))
    .AddTraceSource ("SendDataDone",
                     "Trace Hookup for sending a data",
                     MakeTraceSourceAccessor (&SwMacCsma::m_traceSendDataDone))
    .AddTraceSource ("Enqueue",
                     "Trace Hookup for enqueue a data",
                     MakeTraceSourceAccessor (&SwMacCsma::m_traceEnqueue))
  ;
  return tid;
}
// ------------------------ Set Functions -----------------------------
void
SwMacCsma::AttachPhy (Ptr<SwPhy> phy)
{
  m_phy = phy;
}
void
SwMacCsma::SetDevice (Ptr<SwNetDevice> dev)
{
  m_device = dev;
  SetCw (m_cwMin);
}
void
SwMacCsma::SetAddress (Mac48Address addr)
{
  NS_LOG_FUNCTION (addr);
  m_address = addr;
  // to help each node have different random seed
  uint8_t tmp[6];
  m_address.CopyTo (tmp);
  SeedManager::SetSeed (tmp[5]+9);
}
void
SwMacCsma::SetForwardUpCb (Callback<void, Ptr<Packet>, Mac48Address, Mac48Address> cb)
{
  m_forwardUpCb = cb;
}
void
SwMacCsma::SetCwMin (uint32_t cw)
{
  m_cwMin = cw;
}
void
SwMacCsma::SetCw (uint32_t cw)
{
  m_cw = cw;
}
void
SwMacCsma::SetSlotTime (Time duration)
{
  m_slotTime = duration;
}
// ------------------------ Get Functions -----------------------------
uint32_t
SwMacCsma::GetCw (void)
{
  return m_cw;
}
Time
SwMacCsma::GetSlotTime (void)
{
  return m_slotTime;
}
Time
SwMacCsma::GetSifs (void) const
{
  return m_sifs;
}
Time
SwMacCsma::GetDifs (void) const
{
  return m_difs;
}
uint32_t
SwMacCsma::GetBasicRate ()
{
  return m_basicRate;
}
uint32_t
SwMacCsma::GetDataRate ()
{
  return m_dataRate;
}
Mac48Address
SwMacCsma::GetAddress () const
{
  return this->m_address;
}

Mac48Address
SwMacCsma::GetBroadcast (void) const
{
  return Mac48Address::GetBroadcast ();
}
Time
SwMacCsma::GetCtrlDuration (uint16_t type)
{
  SwMacHeader header = SwMacHeader (m_address, m_address, type);
  return m_phy->CalTxDuration (header.GetSize (), 0, m_basicRate, m_dataRate);
}
Time
SwMacCsma::GetDataDuration (Ptr<Packet> p)
{
  return m_phy->CalTxDuration (0, p->GetSize (), m_basicRate, m_dataRate);
}
std::string
SwMacCsma::StateToString (State state)
{
  switch (state)
    {
    case IDLE:
      return "IDLE";
    case BACKOFF:
      return "BACKOFF";
    case WAIT_TX:
      return "WAIT_TX";
    case TX:
      return "TX";
    case WAIT_RX:
      return "WAIT_RX";
    case RX:
      return "RX";
    case COLL:
      return "COLL";
    default:
      return "??";
    }
}
// ----------------------- Queue Functions -----------------------------
bool
SwMacCsma::Enqueue (Ptr<Packet> packet, Mac48Address dest)
{
  NS_LOG_FUNCTION ("dest" << dest << "#queue" << m_pktQueue.size () << 
                  "state" << m_state << "pktSize" << packet->GetSize ());
  if (m_pktQueue.size () >= m_queueLimit)
    {
      return false;
    }
  m_traceEnqueue (m_device->GetNode ()->GetId (), m_device->GetIfIndex ());
  
  packet->AddHeader (SwMacHeader (m_address, dest, SW_PKT_TYPE_DATA));
  m_pktQueue.push_back (packet);
  
  if (m_state == IDLE)
    { 
      CcaForDifs ();
    }
  
  return false;
}
void
SwMacCsma::Dequeue ()
{
  NS_LOG_FUNCTION (m_pktQueue.size ());
  m_pktQueue.remove(m_pktData);
}
// ------------------ Channel Access Functions -------------------------
void
SwMacCsma::CcaForDifs ()
{
  NS_LOG_FUNCTION ("q-size" << m_pktQueue.size ()  << "nav" << m_nav << m_localNav << StateToString(m_state) << m_phy->IsIdle ());
  Time now = Simulator::Now ();
  
  if (m_pktQueue.size () == 0 || m_ccaTimeoutEvent.IsRunning ())
    {
      return;
    }
  Time nav = std::max (m_nav, m_localNav);
  if (nav > now + GetSlotTime ())
    {
      m_ccaTimeoutEvent = Simulator::Schedule (nav - now, &SwMacCsma::CcaForDifs, this);
      return;
    }
  if (m_state != IDLE || !m_phy->IsIdle ())
    {
      m_ccaTimeoutEvent = Simulator::Schedule (GetDifs (), &SwMacCsma::CcaForDifs, this);
      return;
    }
  m_ccaTimeoutEvent = Simulator::Schedule (GetDifs (), &SwMacCsma::BackoffStart, this);
}
void
SwMacCsma::BackoffStart ()
{
  NS_LOG_FUNCTION ("BO remain" << m_backoffRemain << StateToString(m_state) << m_phy->IsIdle ());
  if (m_state != IDLE || !m_phy->IsIdle ())
    {
      CcaForDifs ();
      return;
    }
  if (m_backoffRemain == Seconds (0))
    {
      UniformVariable uv;
      uint32_t cw = uv.GetInteger (0, m_cw - 1);
      m_backoffRemain = Seconds ((double)(cw) * GetSlotTime().GetSeconds ());
      NS_LOG_DEBUG ("Select a random number (0, " << m_cw - 1 << ") " << cw << 
                    " backoffRemain " << m_backoffRemain << " will finish " << m_backoffRemain + Simulator::Now ());
    }
  m_backoffStart = Simulator::Now ();
  m_backoffTimeoutEvent = Simulator::Schedule (m_backoffRemain, &SwMacCsma::ChannelAccessGranted, this);
}
void
SwMacCsma::ChannelBecomesBusy ()
{
  NS_LOG_FUNCTION ("");
  if (m_backoffTimeoutEvent.IsRunning ())
    {
      m_backoffTimeoutEvent.Cancel ();
      Time elapse;
      if (Simulator::Now () > m_backoffStart)
        {
          elapse = Simulator::Now () - m_backoffStart;
        }
      if (elapse < m_backoffRemain)
        {
          m_backoffRemain = m_backoffRemain - elapse;
          m_backoffRemain = RoundOffTime (m_backoffRemain);
        }
      NS_LOG_DEBUG("Freeze backoff! Remain " << m_backoffRemain);
    }
  CcaForDifs ();
}
void
SwMacCsma::ChannelAccessGranted ()
{
  NS_LOG_FUNCTION ("");
  if (m_pktQueue.size () == 0) { return; }
  
  m_backoffStart = Seconds (0);
  m_backoffRemain = Seconds (0);
  m_state = WAIT_TX;
  
  m_pktData = m_pktQueue.front();
  m_pktQueue.pop_front ();
  
  if (m_pktData == 0)
    NS_ASSERT ("Queue has null packet");
  
  SwMacHeader header;
  m_pktData->PeekHeader (header);
  
  if (header.GetDestination () != GetBroadcast () && m_rtsEnable == true)
    {
      SendRts (m_pktData);
    }
  else
    {
      SendData ();
    }
}
// ---------- Network allocation vector (NAV) functions ----------------
void
SwMacCsma::UpdateNav (Time nav)
{
  Time newNav;
  newNav = RoundOffTime (Simulator::Now () + nav);
  
  if (newNav > m_nav) { m_nav = newNav; }
  NS_LOG_INFO ("NAV: " << m_nav);
}
void
SwMacCsma::UpdateLocalNav (Time nav)
{
  m_localNav = RoundOffTime (Simulator::Now () + nav);
}
// ----------------------- Send Functions ------------------------------
void
SwMacCsma::SendRts (Ptr<Packet> pktData)
{
  NS_LOG_FUNCTION ("");
  
  SwMacHeader dataHeader;
  pktData->PeekHeader (dataHeader);
  NS_LOG_DEBUG("Send RTS to " << dataHeader.GetDestination ());
  Ptr<Packet> packet = Create<Packet> (0);
  SwMacHeader rtsHeader = SwMacHeader (m_address, dataHeader.GetDestination (), SW_PKT_TYPE_RTS);
  
  Time nav = GetSifs () + GetCtrlDuration (SW_PKT_TYPE_CTS)
           + GetSifs () + GetDataDuration (pktData)
           + GetSifs () + GetCtrlDuration (SW_PKT_TYPE_ACK) 
           + GetSlotTime ();
  
  rtsHeader.SetDuration (nav);
  packet->AddHeader (rtsHeader);
  
  Time ctsTimeout = GetCtrlDuration (SW_PKT_TYPE_RTS) 
                  + GetSifs () + GetCtrlDuration (SW_PKT_TYPE_CTS)
                  + GetSlotTime ();
  if (SendPacket (packet, 0))
    {
      UpdateLocalNav (ctsTimeout);
      m_ctsTimeoutEvent = Simulator::Schedule (ctsTimeout, &SwMacCsma::CtsTimeout, this);
    }
  else
    {
      StartOver ();
    }
}
void
SwMacCsma::SendCts (Mac48Address dest, Time duration)
{
  NS_LOG_FUNCTION ("to" << dest);
  NS_LOG_DEBUG("Send CTS to " << dest);
  Ptr<Packet> packet = Create<Packet> (0);
  SwMacHeader ctsHeader = SwMacHeader (m_address, dest, SW_PKT_TYPE_CTS);
  
  Time nav = duration - GetSifs () - GetCtrlDuration (SW_PKT_TYPE_CTS);
  ctsHeader.SetDuration (nav);
  packet->AddHeader (ctsHeader);
  if (SendPacket (packet, 0))
    {
      UpdateLocalNav (duration - GetSifs ());
    }
}
void
SwMacCsma::SendData ()
{
  SwMacHeader header;
  m_pktData->RemoveHeader (header);
  NS_LOG_FUNCTION ("# dest" << header.GetDestination () << "seq" << m_sequence << "q-size" << m_pktQueue.size());
  
  if (header.GetDestination () != GetBroadcast ()) // Unicast
    {
      Time nav = GetSifs () + GetCtrlDuration (SW_PKT_TYPE_ACK);
      header.SetDuration (nav);
      header.SetSequence (m_sequence);
      m_pktData->AddHeader (header);
      if (SendPacket (m_pktData, 1))
        {
          Time ackTimeout = GetDataDuration (m_pktData) + GetSifs () + GetCtrlDuration (SW_PKT_TYPE_ACK) + GetSlotTime ();
          UpdateLocalNav (ackTimeout);
          m_ackTimeoutEvent = Simulator::Schedule (ackTimeout, &SwMacCsma::AckTimeout, this);
      }
      else
        {
          StartOver ();
        }
    }
  else // Broadcast
    {
      header.SetDuration (Seconds (0));
      header.SetSequence (m_sequence);
      m_pktData->AddHeader (header);
      if (SendPacket (m_pktData, 0))
        {
          UpdateLocalNav (GetDataDuration (m_pktData) + GetSlotTime ());
        }
      else
        {
          StartOver ();
        }
    }
}
void
SwMacCsma::SendAck (Mac48Address dest)
{
  NS_LOG_FUNCTION ("to" << dest);
  
  Ptr<Packet> packet = Create<Packet> (0);
  SwMacHeader ackHeader = SwMacHeader (m_address, dest, SW_PKT_TYPE_ACK);
  packet->AddHeader (ackHeader);
  
  Time nav = GetCtrlDuration (SW_PKT_TYPE_ACK);
  ackHeader.SetDuration (Seconds (0));
  UpdateLocalNav (nav + GetSlotTime ());
  SendPacket (packet, 0);
}
bool 
SwMacCsma::SendPacket (Ptr<Packet> packet, bool rate)
{
  NS_LOG_FUNCTION ("state" << m_state << "now" << Simulator::Now ());
  
  if (m_state == IDLE || m_state == WAIT_TX) {
    if (m_phy->SendPacket (packet, rate)) {
      m_state = TX;
      m_pktTx = packet;
      return true;
    }
    else
      m_state = IDLE;
  }
  return false;
}
void 
SwMacCsma::SendPacketDone (Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("state" << m_state);
  
  if (m_state != TX || m_pktTx != packet)
    {
      NS_LOG_DEBUG ("Something is wrong!");
      return;
    }
  m_state = IDLE;
  SwMacHeader header;
  packet->PeekHeader (header);
  switch (header.GetType ())
    {
    case SW_PKT_TYPE_RTS:
    case SW_PKT_TYPE_CTS:
      break;
    case SW_PKT_TYPE_DATA:
      if (header.GetDestination () == GetBroadcast ())
        {
          SendDataDone (true);
          CcaForDifs ();
          return;
        }
	  break;
    case SW_PKT_TYPE_ACK:
      CcaForDifs ();
      break;
    default:
      CcaForDifs ();
      break;
    }
}
void 
SwMacCsma::SendDataDone (bool success)
{
  m_sequence++;
  if (success)
    {
      NS_LOG_FUNCTION ("Success to transmit DATA!");
      m_traceSendDataDone (m_device->GetNode ()->GetId (), m_device->GetIfIndex (), true);
    }
  else
    {
      NS_LOG_FUNCTION ("Fail to transmit DATA!");
      m_traceSendDataDone (m_device->GetNode ()->GetId (), m_device->GetIfIndex (), false);
    }
  m_pktData = 0;
  m_retry = 0;
  m_backoffStart = Seconds (0);
  m_backoffRemain = Seconds (0);
  // According to IEEE 802.11-2007 std (p261)., CW should be reset to minimum value 
  // when retransmission reaches limit or when DATA is transmitted successfully
  SetCw (m_cwMin);
  CcaForDifs ();
}
void
SwMacCsma::StartOver ()
{
  NS_LOG_FUNCTION ("");
  m_pktQueue.push_front (m_pktData);
  m_backoffStart = Seconds (0);
  m_backoffRemain = Seconds (0);
  CcaForDifs ();
}
// ---------------------- Receive Functions ----------------------------
void 
SwMacCsma::ReceiveRts (Ptr<Packet> packet) {
  NS_LOG_FUNCTION ("");
  SwMacHeader header;
  packet->RemoveHeader (header);
  
  if (header.GetDestination () != m_address)
    {
      UpdateNav (header.GetDuration ());
      m_state = IDLE;
      CcaForDifs ();
      return;
    }
  
  // if NAV indicates the channel is not busy, do not respond to RTS (802.11 std)
  if (std::max (m_nav, m_localNav) > Simulator::Now ())
    {
      return;
    }
  
  UpdateLocalNav (header.GetDuration ());
  m_state = WAIT_TX;
  m_sendCtsEvent = Simulator::Schedule (GetSifs (), &SwMacCsma::SendCts, this,
                               header.GetSource (), header.GetDuration ());
}
void 
SwMacCsma::ReceiveCts (Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("" << m_pktData);
  SwMacHeader header;
  packet->RemoveHeader (header);
  
  if (header.GetDestination () != m_address)
    {
      UpdateNav (header.GetDuration ());
      m_state = IDLE;
      CcaForDifs ();
      return;
    }
  
  m_retry = 0;
  UpdateLocalNav (header.GetDuration ());
  m_ctsTimeoutEvent.Cancel ();
  m_state = WAIT_TX;
  m_sendDataEvent = Simulator::Schedule (GetSifs (), &SwMacCsma::SendData, this);
}
void 
SwMacCsma::ReceiveData (Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("");
  SwMacHeader header;
  packet->RemoveHeader (header);
  header.GetDuration ();
  
  if (header.GetDestination () == GetBroadcast ())
    {
      m_state = IDLE;
      if (IsNewSequence (header.GetSource (), header.GetSequence ()))
        {
          m_forwardUpCb (packet, header.GetSource (), header.GetDestination ());
	    }
      CcaForDifs ();
      return;
    }
	
  if (header.GetDestination () !=  m_address) // destined not to me
    {
      UpdateNav (header.GetDuration ());
      m_state = IDLE;
      CcaForDifs ();
	  return;
    }
  UpdateLocalNav (header.GetDuration ());
  m_state = WAIT_TX;
  m_sendAckEvent = Simulator::Schedule (GetSifs (), &SwMacCsma::SendAck, this, header.GetSource ());
  // forward upper layer
  if (IsNewSequence (header.GetSource (), header.GetSequence ()))
    {
      m_forwardUpCb (packet, header.GetSource (), header.GetDestination ());
    }
}
void 
SwMacCsma::ReceiveAck (Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("");
  
  SwMacHeader header;
  packet->RemoveHeader (header);
  m_state = IDLE;
  
  if (header.GetDestination () == m_address)
    {
      m_ackTimeoutEvent.Cancel ();
      SendDataDone (true);
      return;
    }
  
  CcaForDifs ();
}
void
SwMacCsma::ReceivePacket (Ptr<SwPhy> phy, Ptr<Packet> packet)
{
  NS_LOG_FUNCTION ("");
  ChannelBecomesBusy ();
  switch (m_state)
    {
    case WAIT_TX:
    case RX:
    case WAIT_RX:
    case BACKOFF:
    case IDLE:
      m_state = RX;
      break;
    case TX:
    case COLL:
      break;
    }
}
void 
SwMacCsma::ReceivePacketDone (Ptr<SwPhy> phy, Ptr<Packet> packet, bool success)
{
  NS_LOG_FUNCTION ("success?" << success);
  
  m_state = IDLE;
  SwMacHeader header;
  packet->PeekHeader (header);
  
  if (!success)
    {
      NS_LOG_DEBUG ("The packet is not encoded correctly. Drop it!");
      CcaForDifs ();
      return;
    }
  
  switch (header.GetType ())
    {
    case SW_PKT_TYPE_RTS:
      ReceiveRts (packet);
      break;
    case SW_PKT_TYPE_CTS:
      ReceiveCts (packet);
      break;
    case SW_PKT_TYPE_DATA:
      ReceiveData (packet);
      break;
    case SW_PKT_TYPE_ACK:
      ReceiveAck (packet);
      break;
    default:
      CcaForDifs ();
      break;
    }
}
// -------------------------- Timeout ----------------------------------
void
SwMacCsma::CtsTimeout (void)
{
  NS_LOG_FUNCTION ("retry" << m_retry);
  NS_LOG_DEBUG ("!!! CTS timeout !!!");
  // Retransmission is over the limit. Drop it!
  m_traceCtsTimeout (m_device->GetNode ()->GetId (), m_device->GetIfIndex ());
  if (++m_retry > m_rtsRetryLimit) {
    SendDataDone (false);
    return;
  }
  
  m_pktQueue.push_front (m_pktData);
  DoubleCw ();
  m_backoffStart = Seconds (0);
  m_backoffRemain = Seconds (0);
  CcaForDifs ();
}
void
SwMacCsma::AckTimeout (void)
{
  NS_LOG_FUNCTION ("try" << m_retry);
  NS_LOG_DEBUG ("!!! ACK timeout !!!");
  m_state = IDLE;
  m_traceAckTimeout (m_device->GetNode ()->GetId (), m_device->GetIfIndex ());
  // Retransmission is over the limit. Drop it!
  if (++m_retry > m_dataRetryLimit)
    SendDataDone (false);
  else
    SendData ();
}
// --------------------------- ETC -------------------------------------
bool
SwMacCsma::IsNewSequence (Mac48Address addr, uint16_t seq)
{
  std::list<std::pair<Mac48Address, uint16_t> >::iterator it = m_seqList.begin ();
  for (; it != m_seqList.end (); ++it)
    {
      if (it->first == addr)
        {
          if (it->second == 65536 && seq < it->second)
            {
              it->second = seq;
              return true;
            }
          else if (seq > it->second)
            {
              it->second = seq;
              return true;
            }
          else
            {
              return false;
            }
         }
    }
  std::pair<Mac48Address, uint16_t> newEntry;
  newEntry.first = addr;
  newEntry.second = seq;
  m_seqList.push_back (newEntry);
  return true;
}
void
SwMacCsma::DoubleCw ()
{
  if (m_cw * 2 > m_cwMax)
    {
      m_cw = m_cwMax;
    }
  else
    {
      m_cw = m_cw * 2;
    }
}
// Nodes can start backoff procedure at different time because of propagation 
// delay and processing jitter (it's very small but matter in simulation), 
Time
SwMacCsma::RoundOffTime (Time time)
{
  int64_t realTime = time.GetMicroSeconds ();
  int64_t slotTime = GetSlotTime ().GetMicroSeconds ();
  if (realTime % slotTime >= slotTime / 2)
    {
      return Seconds (GetSlotTime().GetSeconds () * (double)(realTime / slotTime + 1));
    }
  else
    {
      return Seconds (GetSlotTime().GetSeconds () * (double)(realTime / slotTime));
    }
}

} // namespace ns3
