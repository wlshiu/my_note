// 分析第三個例子 third.cc。 該例子包含了P2P信道，以太信道和WiFi信道。
// 網絡拓撲如下：

// Default Network Topology
//
//   Wifi 10.1.3.0
//                 AP
//  *    *    *    *
//  |    |    |    |    10.1.1.0
// n5   n6   n7   n0 -------------- n1   n2   n3   n4
//                   point-to-point  |    |    |    |
//                                   ================
//                                     LAN 10.1.2.0

// 接下來我們來分析一下 third.cc 源碼的實現：
// --------------------------------------------------------------------------------------------

#include "ns3/core-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/network-module.h"
#include "ns3/applications-module.h"
#include "ns3/wifi-module.h"
#include "ns3/mobility-module.h"
#include "ns3/csma-module.h"
#include "ns3/internet-module.h"

using namespace ns3;

//聲明了一個叫SecondScriptExample的日誌構件,可以實現打開或者關閉控制台日誌的輸出。
NS_LOG_COMPONENT_DEFINE("ThirdScriptExample");

int main(int argc, char *argv[])
{
    //定義變量，用於決定是否開啟兩個UdpApplication的Logging組件;默認true開啟
    bool        verbose = true;
    uint32_t    nCsma = 3;
    uint32_t    nWifi = 3;

    CommandLine     cmd;
    cmd.AddValue("nCsma", "Number of \"extra\" CSMA nodes/devices", nCsma);
    cmd.AddValue("nWifi", "Number of wifi STA devices", nWifi);
    cmd.AddValue("verbose", "Tell echo applications to log if true", verbose);

    cmd.Parse(argc, argv);

    if(nWifi > 18)
    {
        std::cout << "Number of wifi nodes " << nWifi <<
                  " specified exceeds the mobility bounding box" << std::endl;
        exit(1);
    }

    if(verbose)
    {
        LogComponentEnable("UdpEchoClientApplication", LOG_LEVEL_INFO);
        LogComponentEnable("UdpEchoServerApplication", LOG_LEVEL_INFO);
    }

    /********************網絡拓撲部分************************/
    //創建使用P2P鏈路鏈接的2個節點
    NodeContainer   p2pNodes;
    p2pNodes.Create(2);

    //設置傳送速率和信道延遲
    PointToPointHelper      pointToPoint;
    pointToPoint.SetDeviceAttribute("DataRate", StringValue("5Mbps"));
    pointToPoint.SetChannelAttribute("Delay", StringValue("2ms"));

    //安裝P2P網卡設備到P2P網絡節點
    NetDeviceContainer      p2pDevices;
    p2pDevices = pointToPoint.Install(p2pNodes);

    //創建NodeContainer類對象，用於總線(CSMA)網絡
    NodeContainer       csmaNodes;
    //將第二個P2P節點添加到CSMA的NodeContainer
    csmaNodes.Add(p2pNodes.Get(1));
    //創建Bus network上另外3個node
    csmaNodes.Create(nCsma);

    //創建和連接CSMA設備及信道
    CsmaHelper      csma;
    csma.SetChannelAttribute("DataRate", StringValue("100Mbps"));
    csma.SetChannelAttribute("Delay", TimeValue(NanoSeconds(6560)));

    //安裝網卡設備到CSMA信道的網絡節點
    NetDeviceContainer      csmaDevices;
    csmaDevices = csma.Install(csmaNodes);

    //創建NodeContainer類對象，用於WiFi網絡
    NodeContainer       wifiStaNodes;
    wifiStaNodes.Create(nWifi);
    //設置WiFi網絡的第一個節點為AP
    NodeContainer wifiApNode = p2pNodes.Get(0);

    //初始化物理信道
    YansWifiChannelHelper   channel = YansWifiChannelHelper::Default();
    YansWifiPhyHelper       phy = YansWifiPhyHelper::Default();
    phy.SetChannel(channel.Create());

    WifiHelper      wifi = WifiHelper::Default();
    wifi.SetRemoteStationManager("ns3::AarfWifiManager");

    //Mac層設置
    NqosWifiMacHelper       mac = NqosWifiMacHelper::Default();

    Ssid ssid = Ssid("ns-3-ssid");
    mac.SetType("ns3::StaWifiMac",
                 "Ssid", SsidValue(ssid),
                 "ActiveProbing", BooleanValue(false));

    //安裝網卡設備到WiFi信道的網絡節點，並配置參數
    NetDeviceContainer      staDevices;
    staDevices = wifi.Install(phy, mac, wifiStaNodes);

    mac.SetType("ns3::ApWifiMac",
                 "Ssid", SsidValue(ssid));

    ////安裝網卡設備到WiFi信道的AP節點，並配置參數
    NetDeviceContainer      apDevices;
    apDevices = wifi.Install(phy, mac, wifiApNode);

    //添加移動模型
    MobilityHelper      mobility;

    mobility.SetPositionAllocator("ns3::GridPositionAllocator",
                                   "MinX", DoubleValue(0.0),
                                   "MinY", DoubleValue(0.0),
                                   "DeltaX", DoubleValue(5.0),
                                   "DeltaY", DoubleValue(10.0),
                                   "GridWidth", UintegerValue(3),
                                   "LayoutType", StringValue("RowFirst"));

    mobility.SetMobilityModel("ns3::RandomWalk2dMobilityModel",
                               "Bounds", RectangleValue(Rectangle(-50, 50, -50, 50)));
    //在STA節點上安裝移動模型
    mobility.Install(wifiStaNodes);

    //設置AP：固定在一個位置上
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(wifiApNode);

    //安裝網絡協議
    InternetStackHelper     stack;
    stack.Install(csmaNodes);
    stack.Install(wifiApNode);
    stack.Install(wifiStaNodes);

    Ipv4AddressHelper   address;

    //安排P2P網段的地址
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer p2pInterfaces;
    p2pInterfaces = address.Assign(p2pDevices);

    //安排csma網段的地址
    address.SetBase("10.1.2.0", "255.255.255.0");
    Ipv4InterfaceContainer      csmaInterfaces;
    csmaInterfaces = address.Assign(csmaDevices);

    //安排wifi網段的地址
    address.SetBase("10.1.3.0", "255.255.255.0");
    address.Assign(staDevices);
    address.Assign(apDevices);
    /********************網絡拓撲部分結束*********************/

    /**********************應用程序部分*********************/
    UdpEchoServerHelper         echoServer(9);

    //將Server服務安裝在CSMA網段的最後一個節點上
    ApplicationContainer        serverApps = echoServer.Install(csmaNodes.Get(nCsma));
    serverApps.Start(Seconds(1.0));
    serverApps.Stop(Seconds(10.0));

    UdpEchoClientHelper         echoClient(csmaInterfaces.GetAddress(nCsma), 9);
    echoClient.SetAttribute("MaxPackets", UintegerValue(1));
    echoClient.SetAttribute("Interval", TimeValue(Seconds(1.0)));
    echoClient.SetAttribute("PacketSize", UintegerValue(1024));

    //將Client應用安裝在WiFi網段的倒數第二個節點上
    ApplicationContainer    clientApps =
                                echoClient.Install(wifiStaNodes.Get(nWifi - 1));
    clientApps.Start(Seconds(2.0));
    clientApps.Stop(Seconds(10.0));

    /****************調用全局路由Helper幫助建立網絡路由*******************/
    Ipv4GlobalRoutingHelper::PopulateRoutingTables();

    Simulator::Stop(Seconds(10.0));

    /****************開啟pcap跟蹤*******************/
    pointToPoint.EnablePcapAll("third");
    phy.EnablePcap("third", apDevices.Get(0));
    csma.EnablePcap("third", csmaDevices.Get(0), true);

    Simulator::Run();
    Simulator::Destroy();
    return 0;
}


// -----------------------------------------------------------------------------------------------
// 運行結果如下：



// 注意：
// 1、YansWifiChannelHelper
// YansWifiPhyHelper共享相同的底層信道,也就是說,它們共享相同的無線介質,可以相互通信。

// 2、NqosWifiMacHelper
// 使用NqosWifiMacHelper對象設置MAC參數，表示使用沒有QoS保障的Mac層機制。

// 3、RandomWalk2dMobilityModel
// 表示在一個邊界框中，節點以一個隨機的速度在一個隨機方向上移動
