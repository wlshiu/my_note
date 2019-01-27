/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/*
 * Copyright (c) 2007 INRIA
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Author: Mathieu Lacage <mathieu.lacage@sophia.inria.fr>
 */
#include "csmaca-random-stream.h"
#include "ns3/assert.h"

#include <cmath>

namespace ns3 {

CsmacaRandomStream::~CsmacaRandomStream ()
{
}


CsmacaRealRandomStream::CsmacaRealRandomStream ()
{
  m_stream = CreateObject<UniformRandomVariable> ();
}

uint32_t
CsmacaRealRandomStream::GetNext (uint32_t min, uint32_t max)
{
  return m_stream->GetInteger (min, max);
}

int64_t
CsmacaRealRandomStream::AssignStreams (int64_t stream)
{
  m_stream->SetStream (stream);
  return 1;
}

} // namespace ns3
