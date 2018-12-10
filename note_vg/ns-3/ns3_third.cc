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
#include "ns3/point-to-point-module.h"
#include "ns3/network-module.h"
#include "ns3/applications-module.h"
#include "ns3/csma-module.h"
#include "ns3/internet-module.h"

// 本程序較之second.cc多引用了幾個
#include "ns3/wifi-module.h"
#include "ns3/mobility-module.h"



// Default Network Topology
//
// Number of wifi or csma nodes can be increased up to 250
//                          |
//                 Rank 0   |   Rank 1
// -------------------------|----------------------------
//   Wifi 10.1.3.0
//                 AP
//  *    *    *    *
//  |    |    |    |    10.1.1.0
// n5   n6   n7   n0 -------------- n1   n2   n3   n4
//                   point-to-point  |    |    |    |
//                                   ================
//                                     LAN 10.1.2.0
//
// n0, n5-n7: wifi網絡,
//      n0 為 AP,
//      n5, n6, n7 為無線 STA;
//
// n0 和 n1： p2p 通信;
//      n1-n4： csma 網絡.
//
// 示例中實現了節點 n7 和 n4 通信.
// ps. 這是一個默認的網絡拓撲結構, 可以做為一個基礎的拓撲模板, 通過改變 nodes 數量擴展為自己所需的拓撲
// 改變參數 nCsma 可以改變右側 CSMA LAN 中額外 node 的數量 (不含中間 n0 及 n1 point-to-point 網絡的 nodes).
// 而設置參數 nWifi 可以控制在一次模擬中生成多少個 STA (station) nodes.
// 無線網絡裡總有一個 AP(ACCESS POINT).
//

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("ThirdScriptExample");

int
main (int argc, char *argv[])
{
    bool verbose = true;

    /**
     *  在third.cc中默認了 csma lan 中有 3 個額外節點,
     *      IP 地址 10.1.2.2 ~ 10.1.2.4,
     *
     *  wifi 網有 3 個 STA nodes, node 0 被設為 wifi AP,
     *      IP 地址默認為 10.1.3.2 ~ 10.1.3.4.
     */
    uint32_t nCsma = 3;
    uint32_t nWifi = 3;
    bool tracing = false;

    CommandLine     cmd;
    cmd.AddValue ("nCsma", "Number of \"extra\" CSMA nodes/devices", nCsma);
    cmd.AddValue ("nWifi", "Number of wifi STA devices", nWifi);
    cmd.AddValue ("verbose", "Tell echo applications to log if true", verbose);
    cmd.AddValue ("tracing", "Enable pcap tracing", tracing);

    cmd.Parse (argc, argv);

    // Check for valid number of csma or wifi nodes
    // 250 should be enough, otherwise IP addresses
    // soon become an issue
    if (nWifi > 250 || nCsma > 250)
    {
        std::cout << "Too many wifi or csma nodes, no more than 250 each." << std::endl;
        return 1;
    }

    if (verbose)
    {
        LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
        LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);
    }

    /**
     *  使用 NodeContainer 拓撲工具類定義一個節點容器, 用於生成兩個點對點網絡節點.
     */
    NodeContainer   p2pNodes;
    p2pNodes.Create (2);

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
     *  定義了一個節點容器, 用於生成 csma LAN 網絡節點.
     *  而且在 LAN 中加入的第一個節點是 p2p 網絡中的第二個, 之後又為 LAN 生成了數量為 nCsma 個的節點.
     *  那個既屬於 P2P 也屬於 CSMA 的 node, 將有兩個 net devices, 一個是 p2p 的, 另一個是 cmsa 的.
     */
    NodeContainer   csmaNodes;
    csmaNodes.Add (p2pNodes.Get (1));
    csmaNodes.Create (nCsma);

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

    /**
     *  生成一個 NodeContainer 對象 wifiStaNodes, 然後按參數 nwifi 值(默認為 3) 生成若干 wifi nodes,
     *  然後有生成了另一個 NodeContainer 對象 wifiApNode, 並將 p2p2Nodes.Get(0), 也即node 0, 作為 wifiApNode.
     *  這裡將 wifi 節點分成了兩類, 一類是普通的 Node, 另一類是 AP 型 Node, 使用不同的 Node 容器對象來生成.
     */
    NodeContainer       wifiStaNodes;
    wifiStaNodes.Create (nWifi);
    NodeContainer       wifiApNode = p2pNodes.Get (0);


    /**
     *  構建 wifi 物理層模型和通信信道(NS3 目前就提供一種信道模型 YansWifiChannel).
     *  配置 PHY 和 channel Helper, 生成了 YansWifiChannelHelper 對象 channel 和 YansWifiPhyHelper 對象 phy,
     *  即 wifi mac 層模型對象和物理層對象, 之後還調用了方法 phy.SetChannel(channel.Create()),
     *  用於在所有被 YansWifiPhyHelper 生成的 PHY 層對象中共享共同的 channel, 共享同樣的無線媒介使其能夠通信.
     */
    YansWifiChannelHelper   channel = YansWifiChannelHelper::Default ();
    YansWifiPhyHelper       phy = YansWifiPhyHelper::Default ();
    phy.SetChannel (channel.Create ());

    /**
     *  設置 wifi 全局的 mac 層速率控制算法
     *  生成 WiFiHelper 對象 wifi.SetRemoteStationManager 方法告訴 helper 選用的速率控制算法的類型.
     *  這裡設置為 ns3::AarfWifiManager.
     *  對於 wifi MAC 層, 我們選擇無 QoS MACs.
     */
    WifiHelper      wifi;
    wifi.SetRemoteStationManager ("ns3::AarfWifiManager");

    /**
     *  構建MAC層模型並設置 SSID, active probing, 速率控制算法等配置項.
     *  配置 MAC 層, wifi 的 SSID, wifi 站點不執行活躍探測.
     *  Ssid 類的對象 ssid 是一個 802.11 服務站標識符對象, 用戶設置 MAC 層實現的 ssid 屬性.
     *  要使用指定類型的 MAC 層模型, 可以通過 MACHelper 對象 mac 的 SetType 方法確定.
     */
#if 1
    // 這個 Helper 對象會自動設置 MAC 層屬性 QosSupported 為 false.
    NqosWifiMacHelper   mac = NqosWifiMacHelper::Default();
#else
    // WifiMacHelper mac 可能會設置屬性 QosSupported 為 true.
    WifiMacHelper       mac;
#endif
    Ssid                ssid = Ssid ("ns-3-ssid");
    mac.SetType ("ns3::StaWifiMac",
                 "Ssid", SsidValue (ssid),
                 "ActiveProbing", BooleanValue (false));

    /**
     *  使用 Install 方法生成 STA 節點的 wifi 網絡設備.
     *  使用 WifiHelper 對象的 install 方法安裝 phy, mac 相同的設備到 wifiStaNodes 上,
     *  並將這些設備交給 NetDeviceContainer 容器對象 staDevices 管理.
     */
    NetDeviceContainer      staDevices;
    staDevices = wifi.Install (phy, mac, wifiStaNodes);

    /**
     *  配置一個 AP 節點 (P2P 最左邊的那個節點), 物理層屬性與 Station 節點一致
     *  先創建一個 NetDevice 容器對象 apDevices, 然後以之前設定的 phy, mac, wifiApNode 為參數調用 wifi.Install 方法.
     */
    mac.SetType ("ns3::ApWifiMac",
                 "Ssid", SsidValue (ssid));

    NetDeviceContainer      apDevices;
    apDevices = wifi.Install (phy, mac, wifiApNode);

    /**
     *  指定移動模型與移動方式.
     *  創建了 MobilityHelper 對象 mobility, 這有利於我們完成後續工作.
     */
    MobilityHelper      mobility;

    /**
     *  設置 mobility 屬性 position allocator ("定位").
     *  其中參數告訴 mobility 這個 helper 使用 2維 grid 區域安排 Sta 節點 (細節看 ns3::GridPositionAllocator 文檔).
     */
    mobility.SetPositionAllocator ("ns3::GridPositionAllocator",
                                   "MinX", DoubleValue (0.0),
                                   "MinY", DoubleValue (0.0),
                                   "DeltaX", DoubleValue (5.0),
                                   "DeltaY", DoubleValue (10.0),
                                   "GridWidth", UintegerValue (3),
                                   "LayoutType", StringValue ("RowFirst"));

    /**
     *  設置移動方式模型為 ns3::RandomWalk2dMobilityModel, 即2維隨機遊走模型.
     */
    mobility.SetMobilityModel ("ns3::RandomWalk2dMobilityModel",
                               "Bounds", RectangleValue (Rectangle (-50, 50, -50, 50)));

    /**
     *  將 mobility 安裝到所有 STA 節點上.
     */
    mobility.Install (wifiStaNodes);

    /**
     *  為了將AP節點安排在一個固定位置, 需要完成與下面語句:
     *  設置移動方式模型 ns3::ConstantPositionMobilityModel, 並將它安裝到 wifiApNode 上.
     */
    mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
    mobility.Install (wifiApNode);

    /**
     *  配置網絡層 ip 地址
     *  創建 IP 協議棧 Helper 對象 stack, 然後將這個 stack 安裝到本例中的全部節點(csmaNodes, wifiApNode, wifiStaNodes)上.
     */
    InternetStackHelper     stack;
    stack.Install (csmaNodes);
    stack.Install (wifiApNode);
    stack.Install (wifiStaNodes);

    /**
     *  創建 ip 地址 Helper 對象 address.
     */
    Ipv4AddressHelper       address;

    /**
     *  使用 address 配置網絡地址為 10.1.1.0, 子網掩碼 255.255.255.0,
     *  創建 Ipv4 網卡容器 p2pInterfaces, 然後使用 address 的 Assign 方法將地址自動分配給配 p2pDevices.
     */
    address.SetBase ("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer      p2pInterfaces;
    p2pInterfaces = address.Assign (p2pDevices);

    /**
     *  與上面 3行類似, 分配地址給 csmaDevices.
     *  網絡地址為 10.1.2.0, 子網掩碼 255.255.255.0.
     */
    address.SetBase ("10.1.2.0", "255.255.255.0");
    Ipv4InterfaceContainer      csmaInterfaces;
    csmaInterfaces = address.Assign (csmaDevices);

    /**
     *  與上面類似, 分配地址給 staDevices 和 apDevices,
     *  網絡地址為 10.1.3.0, 子網掩碼 255.255.255.0.
     */
    address.SetBase ("10.1.3.0", "255.255.255.0");
    address.Assign (staDevices);
    address.Assign (apDevices);

    //=========================================
    // 配置Application(即設置傳輸層及更高層次)
    //=========================================


    /**
     *  創建 UdpEchoServerHelper 對象 echoServer, 並配置 server 監聽端口為 9
     */
    UdpEchoServerHelper     echoServer (9);

    /**
     *  創建應用容器 serverApps, 並將 csma 網絡中最右端節點作為服務器.
     */
    ApplicationContainer    serverApps = echoServer.Install (csmaNodes.Get (nCsma));

    // 設置這個server的啟動和停止時間.
    serverApps.Start (Seconds (1.0));
    serverApps.Stop (Seconds (10.0));

    /**
     *  創建 UdpEchoClientHelper 對象 echoClient, 客戶端 ip 地址有 csmaInterfaces.GetAddress(nCsma) 給出, 服務端口 9.
     *  設置 echoClient 屬性 MaxPackets, Interval, PacketSize 等.
     */
    UdpEchoClientHelper     echoClient (csmaInterfaces.GetAddress (nCsma), 9);
    echoClient.SetAttribute ("MaxPackets", UintegerValue (1));
    echoClient.SetAttribute ("Interval", TimeValue (Seconds (1.0)));
    echoClient.SetAttribute ("PacketSize", UintegerValue (1024));

    /**
     *  創建應用容器對象 clientApps, 並將安裝到最後一個 STA 節點上的 echoClient 應用交由 clientApps 管理.
     *  之後設置啟動這個客戶端應用的時間和結束時間.
     */
    ApplicationContainer    clientApps = echoClient.Install (wifiStaNodes.Get (nWifi - 1));
    clientApps.Start (Seconds (2.0));
    clientApps.Stop (Seconds (10.0));

    /**
     *  設置網絡路由
     *  使用 Ipv4GlobalRoutingHelper::PopulateRoutingTables () 啟動網絡路由.
     */
    Ipv4GlobalRoutingHelper::PopulateRoutingTables ();

    /**
     *  設置模擬停止時間
     *  設置本次模擬的停止時間為第 10 秒.由於 wifi 的 AP 會永不停止的發出 beacon,
     *  這會使 ns3 的調度器一直要安排相關事件進行下去, 所以必須使用這條語句來使整個模擬停下來.
     */
    Simulator::Stop (Seconds (10.0));

    /**
     *  設置 trace
     *  設置跟蹤記錄方式
     */
    if (tracing == true)
    {
        pointToPoint.EnablePcapAll ("third");
        phy.EnablePcap ("third", apDevices.Get (0));
        csma.EnablePcap ("third", csmaDevices.Get (0), true);
    }

    /**
     *  啟動與結束模擬
     */
    Simulator::Run ();
    Simulator::Destroy ();
    return 0;
}

