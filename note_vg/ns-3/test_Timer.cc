/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/*
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
 */

#include "ns3/core-module.h"
#include "ns3/scheduler.h"

#include "ns3/timer.h"
#include "ns3/test.h"
#include "ns3/simulator.h"
#include "ns3/nstime.h"

// #include "ns3/netanim-module.h"


using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("TestExample");

class FakeApp
{
public:
    FakeApp();

    void FakeAppMain();
    void FakeAppCB(uint32_t id);
    void FakeAppCB2(void);

    uint32_t            m_dev_id;

    Timer               m_timer;
};

FakeApp::FakeApp()
{
}

void FakeApp::FakeAppCB(uint32_t id)
{
    std::cout << "[@@@ " << __PRETTY_FUNCTION__ << "] " << __LINE__ << ", " << Simulator::Now() << ", id= " << id << std::endl;

    m_timer.Schedule();
}

void FakeApp::FakeAppCB2(void)
{
    std::cout << "[@@@ " << __PRETTY_FUNCTION__ << "] " << __LINE__ << ", " << Simulator::Now()  << std::endl;
    // Simulator::Schedule(Seconds(0.001), &FakeApp::FakeAppCB, this, 4);

    m_timer.Schedule();
}

__attribute__ ((unused)) static void
_timer_routine(uint32_t id)
{
    std::cout << "[@@@ " << __PRETTY_FUNCTION__ << "] " << __LINE__ << ", " << Simulator::Now() << ", id= "  << id << std::endl;
}

void FakeApp::FakeAppMain(void)
{
    uint32_t    id = 3;
    Simulator::Stop(Seconds(5.0));

    m_timer = Timer(Timer::CANCEL_ON_DESTROY);

#if 1
    m_timer.SetFunction(&FakeApp::FakeAppCB, this);
    m_timer.SetArguments(id);
    m_timer.SetDelay(MilliSeconds(500));
#else
    m_timer.SetFunction(&_timer_routine);
    m_timer.SetArguments(id);
    m_timer.SetDelay(MilliSeconds(500));
#endif

    m_timer.Schedule();

    // Simulator::Schedule(Seconds(1.0), &FakeApp::FakeAppCB, this, 3);

    Simulator::Run();
    Simulator::Destroy();
}


int
main (int argc, char *argv[])
{
    CommandLine     cmd;
    cmd.Parse(argc, argv);

    FakeApp     fa;
    fa.FakeAppMain();
    return 0;
}
