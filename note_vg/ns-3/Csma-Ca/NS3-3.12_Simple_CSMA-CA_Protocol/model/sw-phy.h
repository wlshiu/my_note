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

#ifndef SW_PHY_H
#define SW_PHY_H

#include "ns3/simulator.h"
#include "ns3/event-id.h"
#include "sw-mac.h"
#include "sw-phy.h"

namespace ns3 {

class SwPhy : public Object
{
public:
  enum State
    {
      IDLE, TX, RX, COLL
    };
  
  SwPhy ();
  virtual ~SwPhy ();
  void Clear ();
  
  static TypeId GetTypeId (void);
  
  void SetDevice (Ptr<SwNetDevice> device);
  void SetMac (Ptr<SwMac> mac);
  void SetChannel (Ptr<SwChannel> channel);
  void SetTxPower (double dBm);
  
  Ptr<SwChannel> GetChannel ();
  Mac48Address GetAddress ();
  double GetRxPowerTh ();
  double GetTxPower ();
  
  bool SendPacket (Ptr<Packet> packet, bool rate);
  void SendPacketDone (Ptr<Packet> packet);
  void ReceivePacket (Ptr<Packet> packet, Time txDuration, double_t rxPower);
  void ReceivePacketDone (Ptr<Packet> packet, double rxPower);
  
  bool IsIdle ();
  Time CalTxDuration (uint32_t basicSize, uint32_t dataSize, double basicRate, double dataRate);

private:
  State m_state;
  Ptr<SwNetDevice> m_device;
  Ptr<SwMac> m_mac;
  Ptr<SwChannel> m_channel;
  
  Ptr<Packet> m_pktRx;
  Time m_preambleDuration;
  uint32_t m_trailerSize;
  uint32_t m_headerSize;
  
  double m_txPower;  // transmission power (dBm)
  double m_sinrTh;   // SINR threshold
  double m_csTh;     // carrier sense threshold (dBm)
  bool m_csBusy;
  Time m_csBusyEnd;

protected:
};

} // namespace ns3

#endif // SW_PHY_H
