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

#include "ns3/mobility-model.h"
#include "ns3/log.h"
#include "ns3/config.h"
#include "ns3/simulator.h"
#include "ns3/mac48-address.h"
#include "sw-helper.h"
#include "ns3/sw-mac.h"
#include "ns3/sw-phy.h"
#include "ns3/sw-channel.h"

#include <sstream>
#include <string>

NS_LOG_COMPONENT_DEFINE("SwHelper");

namespace ns3
{
  
SwMacHelper::~SwMacHelper ()
{}

SwPhyHelper::~SwPhyHelper ()
{}

SwHelper::SwHelper ()
{
  m_mac.SetTypeId ("ns3::SwMacCsma");
  m_phy.SetTypeId ("ns3::SwPhy");
}

SwHelper::~SwHelper ()
{}

NetDeviceContainer
SwHelper::Install (NodeContainer c, Ptr<SwChannel> channel, const SwPhyHelper &phyHelper, const SwMacHelper &macHelper) const
{
  NetDeviceContainer devices;
  for (NodeContainer::Iterator i = c.Begin (); i != c.End (); i++)
    {
      Ptr<Node> node = *i;
      Ptr<SwNetDevice> device = CreateObject<SwNetDevice> ();

      Ptr<SwMac> mac = macHelper.Create ();
      Ptr<SwPhy> phy = phyHelper.Create ();
      mac->SetAddress (Mac48Address::Allocate ());
      device->SetMac (mac);
      device->SetPhy (phy);
      device->SetChannel (channel);

      node->AddDevice (device);
      devices.Add (device);

      NS_LOG_DEBUG ("node="<<node<<", mob="<<node->GetObject<MobilityModel> ());
  }
  return devices;
}

} //end namespace ns3
