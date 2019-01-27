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

#ifndef SW_HELPER_H_
#define SW_HELPER_H_

#include <string>
#include "ns3/attribute.h"
#include "ns3/object-factory.h"
#include "ns3/node-container.h"
#include "ns3/net-device-container.h"
#include "ns3/sw-net-device.h"

namespace ns3
{
class SwMac;
class SwPhy;
class SwChannel;

class SwMacHelper
{
public:
  virtual ~SwMacHelper ();
  virtual Ptr<SwMac> Create (void) const = 0;
};

class SwPhyHelper
{
public:
  virtual ~SwPhyHelper ();
  virtual Ptr<SwPhy> Create (void) const = 0;
};

class SwHelper
{
public:
  SwHelper();
  virtual ~SwHelper();
  NetDeviceContainer Install (NodeContainer c, Ptr<SwChannel> channel, const SwPhyHelper &phyHelper, const SwMacHelper &macHelper) const;
  
private:
  ObjectFactory m_mac;
  ObjectFactory m_phy;
};


} //end namespace ns3

#endif /* SW_HELPER_H_ */
