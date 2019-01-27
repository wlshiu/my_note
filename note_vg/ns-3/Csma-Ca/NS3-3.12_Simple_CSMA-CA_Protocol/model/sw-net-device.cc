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

#include "ns3/trace-source-accessor.h"
#include "ns3/traced-callback.h"
#include "ns3/llc-snap-header.h"
#include "ns3/pointer.h"
#include "ns3/node.h"
#include "ns3/assert.h"
#include "ns3/log.h"
#include "ns3/mac48-address.h"
#include "sw-net-device.h"
#include "sw-phy.h"
#include "sw-mac.h"
#include "sw-channel.h"


NS_LOG_COMPONENT_DEFINE ("SwNetDevice");

namespace ns3 {

NS_OBJECT_ENSURE_REGISTERED (SwNetDevice);

SwNetDevice::SwNetDevice ()
  : NetDevice (),
    m_mtu (64000),
    m_arp (true)
{
}
SwNetDevice::~SwNetDevice ()
{
}
void
SwNetDevice::Clear ()
{
  m_node = 0;
  if (m_mac)
    {
      m_mac->Clear ();
      m_mac = 0;
    }
  if (m_phy)
    {
      m_phy->Clear ();
      m_phy = 0;
    }
  if (m_channel)
    {
      m_channel->Clear ();
      m_channel = 0;
    }
}
void
SwNetDevice::DoDispose ()
{
  Clear ();
  NetDevice::DoDispose ();
}

TypeId
SwNetDevice::GetTypeId ()
{
  static TypeId tid = TypeId ("ns3::SwNetDevice")
    .SetParent<NetDevice> ()
    .AddAttribute ("Channel", "The channel attached to this device",
                   PointerValue (),
                   MakePointerAccessor (&SwNetDevice::DoGetChannel, &SwNetDevice::SetChannel),
                   MakePointerChecker<SwChannel> ())
    .AddAttribute ("Phy", "The PHY layer attached to this device.",
                   PointerValue (),
                   MakePointerAccessor (&SwNetDevice::GetPhy, &SwNetDevice::SetPhy),
                   MakePointerChecker<SwPhy> ())
    .AddAttribute ("Mac", "The MAC layer attached to this device.",
                   PointerValue (),
                   MakePointerAccessor (&SwNetDevice::GetMac, &SwNetDevice::SetMac),
                   MakePointerChecker<SwMac> ())
    .AddTraceSource ("Rx", "Received payload from the MAC layer.",
                     MakeTraceSourceAccessor (&SwNetDevice::m_rxLogger))
    .AddTraceSource ("Tx", "Send payload to the MAC layer.",
                     MakeTraceSourceAccessor (&SwNetDevice::m_txLogger))
  ;
  return tid;
}

void
SwNetDevice::SetNode (Ptr<Node> node)
{
  m_node = node;
}
void
SwNetDevice::SetMac (Ptr<SwMac> mac)
{
  if (mac != 0)
    {
      m_mac = mac;
      NS_LOG_DEBUG ("Set MAC");

      if (m_phy != 0)
        {
          m_phy->SetMac (m_mac);
          m_mac->AttachPhy (m_phy);
          m_mac->SetDevice (this);
          NS_LOG_DEBUG ("Attached MAC to PHY");
        }
      m_mac->SetForwardUpCb (MakeCallback (&SwNetDevice::ForwardUp, this));
    }
}
void
SwNetDevice::SetPhy (Ptr<SwPhy> phy)
{
  if (phy != 0)
    {
      m_phy = phy;
      m_phy->SetDevice (Ptr<SwNetDevice> (this));
      NS_LOG_DEBUG ("Set PHY");
      if (m_mac != 0)
        {
          m_mac->AttachPhy (phy);
          m_mac->SetDevice (this);
          m_phy->SetMac (m_mac);
          NS_LOG_DEBUG ("Attached PHY to MAC");
        }
    }
}
void
SwNetDevice::SetChannel (Ptr<SwChannel> channel)
{
  if (channel != 0)
    {
      m_channel = channel;
      NS_LOG_DEBUG ("Set CHANNEL");
      if (m_phy != 0)
        {
          m_channel->AddDevice (this, m_phy);
          m_phy->SetChannel (channel);
        }
    }
}
void
SwNetDevice::SetIfIndex (uint32_t index)
{
  m_ifIndex = index;
}
void
SwNetDevice::SetAddress (Address address)
{
  m_mac->SetAddress (Mac48Address::ConvertFrom (address));
}
bool
SwNetDevice::SetMtu (uint16_t mtu)
{
  m_mtu = mtu;
  return true;
}

bool
SwNetDevice::NeedsArp () const
{
  return m_arp;
}
bool
SwNetDevice::SupportsSendFrom (void) const
{
  return false;
}

Ptr<SwChannel>
SwNetDevice::DoGetChannel (void) const
{
  return m_channel;

}
Ptr<SwMac>
SwNetDevice::GetMac () const
{
  return m_mac;
}

Ptr<SwPhy>
SwNetDevice::GetPhy () const
{
  return m_phy;
}
uint32_t
SwNetDevice::GetIfIndex () const
{
  return m_ifIndex;
}

Ptr<Channel>
SwNetDevice::GetChannel () const
{
  return m_channel;
}

Address
SwNetDevice::GetAddress () const
{
  return m_mac->GetAddress ();
}
uint16_t
SwNetDevice::GetMtu () const
{
  return m_mtu;
}
bool
SwNetDevice::IsLinkUp () const
{
  return  (m_linkup && (m_phy != 0));
}

bool
SwNetDevice::IsBroadcast () const
{
  return true;
}
Address
SwNetDevice::GetBroadcast () const
{
  return m_mac->GetBroadcast ();
}
Ptr<Node>
SwNetDevice::GetNode () const
{
  return m_node;
}
bool
SwNetDevice::IsMulticast () const
{
  return false;
}

Address
SwNetDevice::GetMulticast (Ipv4Address multicastGroup) const
{
  NS_FATAL_ERROR ("SwNetDevice does not support multicast");
  return m_mac->GetBroadcast ();
}

Address
SwNetDevice::GetMulticast (Ipv6Address addr) const
{
  NS_FATAL_ERROR ("SwNetDevice does not support multicast");
  return m_mac->GetBroadcast ();
}

bool
SwNetDevice::IsBridge (void) const
{
  return false;
}
bool
SwNetDevice::IsPointToPoint () const
{
  return false;
}

bool 
SwNetDevice::Send (Ptr<Packet> packet, const Address& dest, uint16_t protocolNumber)
{
  NS_LOG_FUNCTION ("pkt" << packet << "dest" << dest);
  NS_ASSERT (Mac48Address::IsMatchingType (dest));
  Mac48Address destAddr = Mac48Address::ConvertFrom (dest);
  Mac48Address srcAddr = Mac48Address::ConvertFrom (GetAddress ());

  LlcSnapHeader llc;
  llc.SetType (protocolNumber);
  packet->AddHeader (llc);
  
  m_mac->Enqueue (packet, destAddr);
  
  return true;
}
bool
SwNetDevice::SendFrom (Ptr<Packet> packet, const Address& src, const Address& dest, uint16_t protocolNumber)
{
  NS_LOG_FUNCTION (src << dest);
  NS_ASSERT (Mac48Address::IsMatchingType (dest));
  NS_ASSERT (Mac48Address::IsMatchingType (src));
  Mac48Address destAddr = Mac48Address::ConvertFrom (dest);
  Mac48Address srcAddr = Mac48Address::ConvertFrom (src);

  LlcSnapHeader llc;
  llc.SetType (protocolNumber);
  packet->AddHeader (llc);

  m_mac->Enqueue (packet, destAddr);

  return true;
}


void
SwNetDevice::ForwardUp (Ptr<Packet> packet, Mac48Address src, Mac48Address dest)
{
  NS_LOG_FUNCTION ("pkt" << packet << "src" << src << "dest" << dest);
  NS_LOG_DEBUG ("Forwarding packet up to application");
  
  LlcSnapHeader llc;
  packet->RemoveHeader (llc);
  enum NetDevice::PacketType type;
  
  if (dest.IsBroadcast ())
    {
      type = NetDevice::PACKET_BROADCAST;
    }
  else if (dest.IsGroup ())
    {
      type = NetDevice::PACKET_MULTICAST;
    }
  else if (dest == m_mac->GetAddress ())
    {
      type = NetDevice::PACKET_HOST;
    }
  else 
    {
      type = NetDevice::PACKET_OTHERHOST;
    }

  if (type != NetDevice::PACKET_OTHERHOST)
    {
      m_rxLogger (packet, src);
      m_forwardUp (this, packet, llc.GetType (), src);
    }
  
}

void
SwNetDevice::SetReceiveCallback (NetDevice::ReceiveCallback cb)
{
  m_forwardUp = cb;
}
void
SwNetDevice::AddLinkChangeCallback (Callback<void> callback)
{
  m_linkChanges.ConnectWithoutContext (callback);
}
void
SwNetDevice::SetPromiscReceiveCallback (PromiscReceiveCallback cb)
{
  // Not implemented yet
  NS_ASSERT_MSG (0, "Not yet implemented");
}

} // namespace ns3

