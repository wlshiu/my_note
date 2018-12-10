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
#include "ns3/network-module.h"
#include "ns3/csma-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
#include "ns3/ipv4-global-routing-helper.h"

// Default Network Topology
//
//       10.1.1.0
// n0 -------------- n1   n2   n3   n4
//    point-to-point  |    |    |    |
//                    ================
//                      LAN 10.1.2.0


using namespace ns3;

// module name for log
NS_LOG_COMPONENT_DEFINE ("SecondScriptExample");

int
main (int argc, char *argv[])
{
    /**
     *  在主函數中先定義兩個變量, verbose 這個bool值用於打開或關閉 UdpEchoClientApplication 和 UdpEchoServerApplication 的日誌模塊,
     *  默認情況下, 在設置了 NS_LOG_COMPONENT_DEFINE 後, 日誌就打開了, 但還是可以人為的關閉應用的日誌.
     *  整數值nCsma用於設置當前LAN中node的數量.
     */
    bool verbose = true;
    uint32_t nCsma = 3;

    /**
     *  定義命令行系統對象cmd, 並在命令行系統中加入用戶自定義屬性nCsma和verbose,
     *  使我們可以用命令行對這兩個變量進行設置.
     */
    CommandLine     cmd;
    cmd.AddValue ("nCsma", "Number of \"extra\" CSMA nodes/devices", nCsma);
    cmd.AddValue ("verbose", "Tell echo applications to log if true", verbose);

    cmd.Parse (argc, argv);

    /**
     *  設定程序運行特性
     */
    if (verbose) {
        LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
        LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);
    }

    nCsma = nCsma == 0 ? 1 : nCsma;

    /**
     *  使用 NodeContainer 拓撲工具類定義一個節點容器, 用於生成兩個點對點網絡節點.
     */
    NodeContainer   p2pNodes;
    p2pNodes.Create (2);

    /**
     *  再次定義了一個節點容器, 用於生成 csma LAN 網絡節點.
     *  而且在 LAN 中加入的第一個節點是 p2p 網絡中的第二個, 之後又為 LAN 生成了數量為 nCsma 個的節點.
     *  那個既屬於 P2P 也屬於 CSMA 的 node, 將有兩個 net devices, 一個是 p2p 的, 另一個是 cmsa 的.
     */
    NodeContainer   csmaNodes;
    csmaNodes.Add (p2pNodes.Get (1));
    csmaNodes.Create (nCsma);

    /**
     *  與first.cc相同, 我們初始化了一個P2P工具類對象, 由此設置了兩個 Devic e屬性: DataRate 和 Delay.
     */
    PointToPointHelper      pointToPoint;
    pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
    pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));

    /**
     *  初始化 NetDeviceContainer 對象, 用它來跟蹤 P2P 設備,
     *  然後使用 PointToPointHelper 對象將 P2P devices 安裝到 P2P 的 nodes 上.
     */
    NetDeviceContainer      p2pDevices;
    p2pDevices = pointToPoint.Install (p2pNodes);

    /**
     *  初始化一個 CsmaHelper 對象, 它將用來完成 csma devices 和 Channels 的生成, 配置, 與連接.
     *  這裡使用 csma 設置了兩個信道屬性 DataRate 和 Delay.
     *  ps. 這裡的 DataRate 屬性設置為 Channel 屬性, 而不是 P2P 裡面的 Device 屬性,
     *  這是因為在 CSMA 網絡中不允許速率混雜(即整個 LAN 以某個速率通信, 各節點收發速率保持一致).
     *  這裡將 DataRate 設為 100mbps, Delay 設為 6560ns(任選值).
     *
     *  ps. 設置屬性時要使用相應的內置數據類型: StringValue("100Mbps") 和 TimeValue(NanoSeconds(6560)).
     */
    CsmaHelper      csma;
    csma.SetChannelAttribute ("DataRate", StringValue ("100Mbps"));
    csma.SetChannelAttribute ("Delay", TimeValue (NanoSeconds (6560)));

    /**
     *  生成一個 NetDeviceContainer 對象 csmaDevices, 用來存放安裝在 csma nodes 上的 csma Devices.
     */
    NetDeviceContainer      csmaDevices;
    csmaDevices = csma.Install (csmaNodes);

    //======================================================
    //  到目前為止, 我們生成了 nodes, netdevices, channels, 下面我們設置 protocols.
    //======================================================

    /**
     *  使用 InternetStackHelper 對象來安裝配置協議棧.
     */
    InternetStackHelper     stack;
    stack.Install (p2pNodes.Get (0));
    stack.Install (csmaNodes);

    /**
     *  設置 P2P 網絡地址為 10.10.1.0, 子網掩碼 255.255.255.0,
     *  還生成了 Ipv4InterfaceContainer 對象來存放已經分配了地址的 p2p devices.
     */
    Ipv4AddressHelper       address;
    address.SetBase ("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer      p2pInterfaces;
    p2pInterfaces = address.Assign (p2pDevices);


    /**
     *  設置LAN網絡地址為 10.10.2.0, 子網掩碼 255.255.255.0,
     *  還生成了 Ipv4InterfaceContainer 對象來存放已經分配了地址的 CSMA devices.
     */
    address.SetBase ("10.1.2.0", "255.255.255.0");
    Ipv4InterfaceContainer      csmaInterfaces;
    csmaInterfaces = address.Assign (csmaDevices);

    //======================================================
    // 安裝配置了協議之後, 下面為 node 建立應用, 這部分與 first.cc 中有很多類似.
    // 我們要在含有 csma device 的一個 node 上初始化一個 Server 應用,
    // 在僅含有點對點設備的 node 上初始化一個 Client 應用.
    //======================================================


    /**
     *  生成 UdpEchoServerHelper 對象用於管理 server Application, 參數 9 表示 echo server application 的監聽端口為 9.
     *  之後, 建立 ApplicationContainer, 管理安裝在 csma node 上的 echo Server Applications,
     *  注意這裡使用 nCsma 值為索引, 使用 csmaNodes.Get(nCsma) 獲得了第 nCsma 個節點
     *  (LAN 中共有 nCsma+1 個 nodes, 從 0 計數, 第 0 個為既有 p2p 設備也有 csma 設備的節點, 1~nCsma 為僅含有 csma 設備的節點).
     *  之後使用 serverApps.start() 和 stop() 方法, 使 serverApps 在第 1s 啟動, 第 10s 結束.
     */
    UdpEchoServerHelper     echoServer (9);

    ApplicationContainer    serverApps = echoServer.Install (csmaNodes.Get (nCsma));
    serverApps.Start (Seconds (1.0));
    serverApps.Stop (Seconds (10.0));

    /**
     *  生成 echoClient 這個 UdpEchoClientHelper 對象, 並分配 ip 地址和端口號 9,
     *  之後設置 echo client 的屬性:
     *      MaxPackets 為 1
     *      Interval 為 1s
     *      PacketSize 為 1024.
     *  之後初始化 client application 容器, 存放安裝在 p2p 節點上的應用 echo Client,
     *  在第 2s 啟動該應用, 在第 10s 關閉.
     */
    UdpEchoClientHelper     echoClient (csmaInterfaces.GetAddress (nCsma), 9);
    echoClient.SetAttribute ("MaxPackets", UintegerValue (1));
    echoClient.SetAttribute ("Interval", TimeValue (Seconds (1.0)));
    echoClient.SetAttribute ("PacketSize", UintegerValue (1024));

    ApplicationContainer    clientApps = echoClient.Install (p2pNodes.Get (0));
    clientApps.Start (Seconds (2.0));
    clientApps.Stop (Seconds (10.0));


    //======================================================
    // 下面我們要建立某種形式的網絡路由. ns-3 提供了稱為 global routing 的模型.
    // Global routing 利用了我們建立的網絡在運行模擬時均可訪問, 且貫穿於每個節點.
    // 它可以在用戶不進行配置路由器的情況下, 啟動路由功能.
    // 一般情況下, 發生的情況是每個節點的行為就好像是一個 OSPF router, 他能即時, 神奇地與幕後的所有其他路由器進行通信.
    // 每個節點生成鏈接廣告, 並直接與全局路由管理器. 全局路由管理器使用全局信息為每個節點構建路由表.
    //======================================================


    /**
     *  生成 Ipv4GlobalRoutingHelper 中 PopulateRoutingTables.
     */
    Ipv4GlobalRoutingHelper::PopulateRoutingTables ();

    /**
     *  開啟 pcap Tracing. 110行中開啟csma helper的方法中, 使用了一個額外的參數.
     *  由於 csma 網絡是一個多點接入網絡, 意味著共享媒介上有多個端點.
     *  每個端點有一個 csma 網卡. 有兩種可互相替換的方法來Tracing這類網絡.
     *  一種是為每個 net device 生成 Tracing 文件, 並且只保存那些被這個設備發出或接收的數據包;
     *  另一種, 選一個 net device, 將其設為混雜模式監聽所有的數據包. 這個方式就像 tcpdump 的工作方式.
     *  語句 csma.EnablePcap ("second", csmaDevices.Get (1), true) 中最後一個參數, 告訴 csma helper 是否安排以混雜模式捕捉數據包.
     *  在本例中, 我們選擇了 csmaDevices.Get (1) 這個設備, 將其設置為混雜模式來 sniffing 網絡.
     */
    pointToPoint.EnablePcapAll ("second");
    csma.EnablePcap ("second", csmaDevices.Get (1), true);

    /**
     *  啟動模擬, 並在運行完畢後結束,
     */
    Simulator::Run ();
    Simulator::Destroy ();
    return 0;
}
