// ~/ns-3.29/examples/stats/wifi-example-apps.cc

void Sender::SendPacket ()
{
    Ptr<Packet>     packet = Create<Packet>(m_pktSize);//創建數據包
    TimestampTag    timestamp; //時間戳

    timestamp.SetTimestamp (Simulator::Now ());
    packet->AddByteTag (timestamp);//給數據包打上時間戳

    m_socket->SendTo (packet, 0, InetSocketAddress (m_destAddr, m_destPort));//發送數據包，地址和端口
    m_txTrace (packet); //記錄trace
    if (++m_count < m_numPkts)
    {
        m_sendEvent = Simulator::Schedule (Seconds (m_interval->GetValue ()),
                                           &Sender::SendPacket, this);//設計中斷發送數據包
    }
}