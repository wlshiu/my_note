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

#ifndef SW_MAC_CSMA_H
#define SW_MAC_CSMA_H

#include "ns3/nstime.h"
#include "ns3/simulator.h"
#include "ns3/event-id.h"
#include "ns3/traced-value.h"
#include "sw-mac.h"
#include "sw-phy.h"
#include <list>

namespace ns3 {

class SwMacCsma : public SwMac
{
public:
  SwMacCsma ();
  virtual ~SwMacCsma ();
  static TypeId GetTypeId (void);
  
  virtual void SetCwMin (uint32_t cw);
  virtual void SetSlotTime (Time duration);
  virtual uint32_t GetCw (void);
  virtual Time GetSlotTime (void);
  virtual void AttachPhy (Ptr<SwPhy> phy);
  virtual void SetDevice (Ptr<SwNetDevice> dev);
  virtual void Clear (void);
  virtual void SetAddress (Mac48Address addr);
  virtual Mac48Address GetBroadcast (void) const;
  virtual Mac48Address GetAddress () const;
  virtual uint32_t GetBasicRate ();
  virtual uint32_t GetDataRate ();
  
  virtual bool Enqueue (Ptr<Packet> pkt, Mac48Address dest);
  
  virtual void SendPacketDone (Ptr<Packet> packet);
  virtual void SetForwardUpCb (Callback<void, Ptr<Packet>, Mac48Address, Mac48Address> cb);
  virtual void ReceivePacket (Ptr<SwPhy> phy, Ptr<Packet> packet);
  virtual void ReceivePacketDone (Ptr<SwPhy> phy, Ptr<Packet> packet, bool collision);
  
private:
  typedef enum {
    IDLE, BACKOFF, WAIT_TX, TX, WAIT_RX, RX, COLL
  } State;
  
  Time GetSifs (void) const;
  Time GetDifs (void) const;
  Time GetCtrlDuration (uint16_t type);
  Time GetDataDuration (Ptr<Packet> p);
  std::string StateToString (State state);
  
  void SetCw (uint32_t cw);
  
  void CcaForDifs ();
  void BackoffStart ();
  void ChannelBecomesBusy ();
  void ChannelAccessGranted ();
  void UpdateNav (Time nav);
  void UpdateLocalNav (Time nav);
  void Dequeue ();
  void SendRts (Ptr<Packet> pktData);
  void SendCts (Mac48Address dest, Time duration);
  void SendData ();
  void SendAck (Mac48Address dest);
  bool SendPacket (Ptr<Packet> packet, bool rate);
  void StartOver ();
  void SendDataDone (bool success);
  
  void ReceiveRts (Ptr<Packet> packet);
  void ReceiveCts (Ptr<Packet> packet);
  void ReceiveData (Ptr<Packet> packet);
  void ReceiveAck (Ptr<Packet> packet);
  
  void CtsTimeout ();
  void AckTimeout ();
  void DoubleCw ();
  Time RoundOffTime (Time time);
  bool IsNewSequence (Mac48Address addr, uint16_t seq);
  
  Callback <void, Ptr<Packet>, Mac48Address, Mac48Address> m_forwardUpCb;
  Mac48Address m_address;
  Ptr<SwPhy> m_phy;
  Ptr<SwNetDevice> m_device;
  
  State m_state;
  bool m_rtsEnable;
  
  EventId m_ccaTimeoutEvent;
  EventId m_backoffTimeoutEvent;
  EventId m_ctsTimeoutEvent;
  EventId m_ackTimeoutEvent;
  EventId m_sendCtsEvent;
  EventId m_sendAckEvent;
  EventId m_sendDataEvent;
  
  // Mac parameters
  uint16_t m_cw;
  uint16_t m_cwMin;
  uint16_t m_cwMax;
  uint16_t m_rtsRetryLimit;
  uint16_t m_dataRetryLimit;
  uint16_t m_retry;
  uint16_t m_sequence;
  Time m_slotTime;
  Time m_sifs;
  Time m_difs;
  double m_basicRate;
  double m_dataRate;

  Ptr<Packet> m_pktTx;
  Ptr<Packet> m_pktData;
  Time m_nav;
  Time m_localNav;
  Time m_backoffRemain;
  Time m_backoffStart;
  
  uint32_t m_queueLimit;
  std::list<Ptr<Packet> > m_pktQueue;
  std::list<std::pair<Mac48Address, uint16_t> > m_seqList;
  
  // for trace and performance evaluation
  TracedCallback<uint32_t, uint32_t> m_traceCtsTimeout;
  TracedCallback<uint32_t, uint32_t> m_traceAckTimeout;
  TracedCallback<uint32_t, uint32_t> m_traceEnqueue;
  TracedCallback<uint32_t, uint32_t, bool> m_traceSendDataDone;
  
protected:
};

}

#endif // SW_MAC_CSMA_H
