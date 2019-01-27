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

#ifndef SW_MAC_HEADER_H
#define SW_MAC_HEADER_H

#include "ns3/header.h"
#include "ns3/nstime.h"
#include "ns3/simulator.h"
#include "ns3/mac48-address.h"

#define SW_PKT_TYPE_RTS   0
#define SW_PKT_TYPE_CTS   1
#define SW_PKT_TYPE_ACK   2
#define SW_PKT_TYPE_DATA  3

namespace ns3 {

class SwMacHeader : public Header
{
public:
  SwMacHeader ();
  
  SwMacHeader (const Mac48Address srcAddr, const Mac48Address dstAddr, uint8_t type);
  virtual ~SwMacHeader ();
  
  static TypeId GetTypeId (void);

  void SetSource (Mac48Address addr);
  void SetDestination (Mac48Address addr);
  void SetType (uint8_t type);
  void SetDuration (Time duration);
  void SetSequence (uint16_t seq);
  
  Mac48Address GetSource () const;
  Mac48Address GetDestination () const;
  uint8_t GetType () const;
  Time GetDuration () const;
  uint32_t GetSize () const;
  uint16_t GetSequence () const;

  // Inherrited methods
  virtual uint32_t GetSerializedSize (void) const;
  virtual void Serialize (Buffer::Iterator start) const;
  virtual uint32_t Deserialize (Buffer::Iterator start);
  virtual void Print (std::ostream &os) const;
  virtual TypeId GetInstanceTypeId (void) const;
  
private:
  Mac48Address m_srcAddr;
  Mac48Address m_dstAddr;
  uint8_t m_type;
  uint16_t m_duration;
  uint16_t m_sequence;
};

}

#endif // SW_MAC_HEADER_H
