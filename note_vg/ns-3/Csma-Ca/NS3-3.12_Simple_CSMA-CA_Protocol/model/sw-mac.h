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

#ifndef SW_MAC_H
#define SW_MAC_H

#include "ns3/address.h"
#include "ns3/object.h"
#include "ns3/packet.h"
#include "ns3/ipv4-l3-protocol.h"
#include "ns3/nstime.h"
#include "ns3/ptr.h"
#include "sw-net-device.h"
#include "sw-phy.h"
#include "sw-channel.h"

namespace ns3 {

class SwPhy;
class SwChannel;
class SwNetDevice;

class SwMac : public Object
{
public:
  virtual void AttachPhy (Ptr<SwPhy> phy) = 0;
  virtual void SetDevice (Ptr<SwNetDevice> dev) = 0;
  virtual void SetAddress (Mac48Address addr) = 0;
  virtual void SetCwMin (uint32_t cw) = 0;
  virtual Mac48Address GetAddress (void) const = 0;
  virtual Mac48Address GetBroadcast (void) const = 0;
  virtual uint32_t GetBasicRate () = 0;
  virtual uint32_t GetDataRate () = 0;
  
  virtual bool Enqueue (Ptr<Packet> pkt, Mac48Address dest) = 0;
  
  virtual void SendPacketDone (Ptr<Packet> packet) = 0;
  virtual void ReceivePacket (Ptr<SwPhy> phy, Ptr<Packet> packet) = 0;
  virtual void ReceivePacketDone (Ptr<SwPhy> phy, Ptr<Packet> packet, bool collision) = 0;
  virtual void SetForwardUpCb (Callback<void, Ptr<Packet>, Mac48Address, Mac48Address> cb) = 0;
  
  virtual void Clear (void) = 0;

};

}

#endif // SW_MAC_H
