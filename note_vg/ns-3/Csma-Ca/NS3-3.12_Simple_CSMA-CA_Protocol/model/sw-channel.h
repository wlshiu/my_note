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

#ifndef SW_CHANNEL_H
#define SW_CHANNEL_H

#include "ns3/channel.h"
#include "ns3/packet.h"
#include "ns3/simulator.h"
#include "ns3/propagation-loss-model.h"
#include "ns3/propagation-delay-model.h"
#include "sw-net-device.h"
#include "sw-phy.h"
#include <list>
#include <vector>

namespace ns3 {

class PropagationLossModel;
class PropagationDelayModel;

class SwChannel : public Channel
{

typedef struct
{
  Ptr<Packet> packet;
  Ptr<SwPhy> phy;
  Time txDuration;
  Time txEnd;
  double_t rxPower;
} NoiseEntry;

public:
  SwChannel ();
  virtual ~SwChannel ();
  static TypeId GetTypeId ();
  
  virtual uint32_t GetNDevices () const;
  virtual Ptr<NetDevice> GetDevice (uint32_t i) const;
  void AddDevice (Ptr<SwNetDevice> dev, Ptr<SwPhy> phy);
  void Clear ();
  
  bool SendPacket (Ptr<SwPhy> phy, Ptr<Packet> packet, double txPower, Time delay);
  
  double GetNoiseW (Ptr<SwPhy> phy, Ptr<Packet> signal);
  double DbmToW (double dbm);
  
private:
  void SendPacketDone (Ptr<SwPhy> phy, Ptr<Packet> packet);
  void ReceivePacket (uint32_t i, NoiseEntry ne);
  void ReceivePacketDone (uint32_t i, NoiseEntry ne);
  
  void DeleteNoiseEntry (NoiseEntry ne);
  
  Time m_delNoiseEntryLater;
  double m_noiseFloor;
  
  Ptr<LogDistancePropagationLossModel> m_loss;
  Ptr<ConstantSpeedPropagationDelayModel> m_delay;
  
  typedef std::vector<std::pair<Ptr<SwNetDevice>, Ptr<SwPhy> > > SwDeviceList;
  SwDeviceList m_devList;
  std::list<NoiseEntry> m_noiseEntry;
  
protected:
  
};

}

#endif // SW_CHANNEL_H
