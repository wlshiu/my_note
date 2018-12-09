#include <iostream>
#include <string>

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/csma-module.h"

using namespace std;
using namespace ns3;

NS_LOG_COMPONENT_DEFINE("two");

//回調函數
static void recvCallback(Ptr<Socket> sock)
{
	Ptr<Packet>     packet = sock->Recv();
	cout << "size:" << packet->GetSize() << endl;
}

int main(int argc, char *argv[])
{
	NodeContainer   nodes;
	nodes.Create(5);

	InternetStackHelper     stack;
	stack.Install(nodes);

	CsmaHelper          csmaHelper;
	NetDeviceContainer  cmsaNetDevice = csmaHelper.Install(nodes);

	Ipv4AddressHelper       addressHelper;
	addressHelper.SetBase("192.168.1.0", "255.255.255.0");
	Ipv4InterfaceContainer interfaces = addressHelper.Assign(cmsaNetDevice);

	//server sockets
	TypeId              tid = TypeId::LookupByName("ns3::UdpSocketFactory");
	Ptr<Socket>         server = Socket::CreateSocket(nodes.Get(0), tid);
	InetSocketAddress   addr = InetSocketAddress(Ipv4Address::GetAny(), 10086);
	server->Bind(addr);

	server->SetRecvCallback(MakeCallback(&recvCallback)); //設置回調函數

	//client sockets
	Ptr<Socket>         client = Socket::CreateSocket(nodes.Get(4), tid);
	InetSocketAddress   serverAddr = InetSocketAddress(interfaces.GetAddress(0), 10086);
	client->Connect(serverAddr);
	client->Send(Create<Packet>(500));

	client->Close();
	csmaHelper.EnablePcap("two", nodes);

	Simulator::Run();
	Simulator::Destroy();


	return 0;
}
