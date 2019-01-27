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

#ifndef SW_NET_DEVICE_H
#define SW_NET_DEVICE_H

#include "ns3/net-device.h"
#include "ns3/pointer.h"
#include "ns3/traced-callback.h"

namespace ns3 {

class SwChannel;
class SwPhy;
class SwMac;

class SwNetDevice : public NetDevice
{
public:
  static TypeId GetTypeId (void);

  SwNetDevice ();
  virtual ~SwNetDevice ();

  void SetMac (Ptr<SwMac> mac);
  void SetPhy (Ptr<SwPhy> phy);
  void SetChannel (Ptr<SwChannel> channel);

  Ptr<SwMac> GetMac (void) const;
  Ptr<SwPhy> GetPhy (void) const;

  void Clear (void);

  // Purely virtual functions from base class
  virtual void SetIfIndex (const uint32_t index);
  virtual uint32_t GetIfIndex (void) const;
  virtual Ptr<Channel> GetChannel (void) const;
  virtual Address GetAddress (void) const;
  virtual bool SetMtu (const uint16_t mtu);
  virtual uint16_t GetMtu (void) const;
  virtual bool IsLinkUp (void) const;
  virtual bool IsBroadcast (void) const;
  virtual Address GetBroadcast (void) const;
  virtual bool IsMulticast (void) const;
  virtual Address GetMulticast (Ipv4Address multicastGroup) const;
  virtual Address GetMulticast (Ipv6Address addr) const;
  virtual bool IsBridge (void) const ;
  virtual bool IsPointToPoint (void) const;
  virtual bool Send (Ptr<Packet> packet, const Address& dest, uint16_t protocolNumber);
  virtual bool SendFrom (Ptr<Packet> packet, const Address& source, const Address& dest, uint16_t protocolNumber);
  virtual Ptr<Node> GetNode (void) const;
  virtual void SetNode (Ptr<Node> node);
  virtual bool NeedsArp (void) const;
  virtual void SetReceiveCallback (NetDevice::ReceiveCallback cb);
  virtual void SetPromiscReceiveCallback (PromiscReceiveCallback cb);
  virtual bool SupportsSendFrom (void) const;
  virtual void AddLinkChangeCallback (Callback<void> callback);
  virtual void SetAddress (Address address);
  
private:
  virtual void ForwardUp (Ptr<Packet> packet, Mac48Address src, Mac48Address dest);
  Ptr<SwChannel> DoGetChannel (void) const;
  
  Ptr<Node> m_node;
  Ptr<SwChannel> m_channel;
  Ptr<SwMac> m_mac;
  Ptr<SwPhy> m_phy;

  std::string m_name;
  uint32_t m_ifIndex;
  uint16_t m_mtu;
  bool m_linkup;
  TracedCallback<> m_linkChanges;
  ReceiveCallback m_forwardUp;

  TracedCallback<Ptr<const Packet>, Mac48Address> m_rxLogger;
  TracedCallback<Ptr<const Packet>, Mac48Address> m_txLogger;

  bool m_arp;

protected:
  virtual void DoDispose ();
};

} // namespace ns3

#endif // SW_NET_DEVICE_H 
