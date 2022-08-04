USB Enumeration [[Back]](note_usb_device.md#Bus-Enumeration)
---



# USB Enumeration 過程

    - 用戶將一個 USB Device 插入 USB port, Host 為 USB port 供電, Device 此時處於上電狀態. Host 檢測 Device. Hub 使用中斷通道將事件報告給 Host.

    - Host 發送 `Get_Port_Status`(讀端口狀態) Request, 以獲取更多的 Device 信息. Device 返回消息告訴 Host 該 Device 是什麼時候連接的.
    Hub 檢測 Device 是低速運行還是高速運行, 並將此信息送給 Host, 這是對 Get_Port_Status 請求的響應

    - Host 發送`Set_Port_Feature`(寫端口狀態) Request 給 Hub, 要求它 reset USB port, 請求 Hub 來重新設置 USB port.
    Hub 使 Device 的 USB 數據線處於 RESET 狀態至少 **10ms**

    - Host 使用 Chirp K 信號來瞭解 Full-Speed Device 是否支持 High-Speed 運行

    - Host 發送另一個`Get_Port_Status` Request, 確定 Device 是否已經從 RESET 狀態退出; 返回的數據有一位表示 Device 仍然處於 RESET 狀態.
    當 Hub 釋放了 RESET 狀態, Device 此時處於 Default 狀態, 且已准備好在 endpoint0 響應 Host 控制傳輸
    **Default Address 為 0x00h**, Device 能從 Bus 獲取高達 `100mA`的電流

    - Hub 檢測 Device 速度; Hub 通過測定 `D+`或`D-`在 Idle 時為高電壓, 來檢測 Device 是 Low-Speed or Full-Speed
        > Full/High Speed Device 在 `D+` 有上拉電阻, Low-Speed Device 則是 `D-` 有上拉電阻

    - 獲取最大數據包長度
        > Host 向 `Address 0` 發送 `Get_Descriptor`(讀 Device Descriptor)報文, 以取得 default 控制管道所支持的最大數據包長度, 並在有限的時間內等待 USB Device 的響應.
        該長度包含在 Device 描述符的 `bMaxPacketSize0` 中(offset 7-bytes), 所以這時 Host 只需讀取該描述符的前 8 個 bytes.
        注意, **Host 一次只能枚舉一個 USB Device, 所以同一時刻只能有一個 USB Device 使用 default address 0x00**
        >> e.g. Host 向 Device 發送一個 8-bytes 請求`80 06 00 01 00 00 40 00`, Device 接收到 Request 後產生一個中斷, 我們可以通過讀中斷寄存器知道中斷源,
        並且可以加讀最後狀態寄存器, 來確定第一個接到的包是否為一個 Setup packet.
        當控制器處理程序判斷出它是一個 `Get_Descriptor` Request 時, 把 Device Descriptor 的前 16 bytes 發送到 endpoint0 緩沖區中.
        剩下的 2 bytes 在第一次請求時不再發送

    - Host 分配一個新的 Address 給 Device
        >  Host 通過發送一個 `Set_Address` 請求來分配一個唯一的地址給 Device.
        Device 讀取這個請求, 返回一個確認, 並保存新的地址. 從此開始所有通信都使用這個新地址
        >> 當 Host 收到正確的前 16 bytes 描述符後, 會給 Device 分配一個地址.
        假設 PC 分配的地址為`0x03`(這個要看當時 USB ports 的 Device 數目而定);
        `Set_Address` 請求所發送的數據為`00 05 03 00 00 00 00 00`, 其中的`03`就表示 Host 為 Device 分配的地址為 `0x03`, 在以後的通信裡 Device 就只對 0x03 地址作出應答.
        當 Device 產生一個接收中斷後, 根據所分配的地址, 設置 Device 的地址寄存器相應位

    - Host 向新地址重新發送 `Get_Descriptor` 命令, 此次讀取其 Device Descriptor 的全部字段, 以瞭解該 Device 的總體信息
        > e.g. Host 發送 `Get_descriptor` Request `80 06 00 01 00 00 12 00`, 此次將要求把 18 個 bytes 全部發送完.
        所以 Host 要分兩次來讀取. 第一次讀取 16 個 bytes, 第二次讀取 2 bytes, 最後 Host 發送 0 表示發送完畢的應答

    - Host 向 Device 循環發送`Get_Configuration`命令, 要求 USB Device 回答, 以讀取全部配置信息

    - Host 發送`Get_Device_String`命令, 獲得 String Descriptor(unicode), 比如產商, 產品描述, 型號等等.
    此時 Host 將會彈出窗口, 展示發現新 Device 的信息, 產商, 產品描述, 型號等.
         > 根據`Device_Descriptor`和`Device_Configuration`應答, PC 判斷是否能夠提供 USB 的 Driver,
         若 OS 能提供幾大類的 Device, 如游戲操作桿, 存儲,打印機, 掃描儀等, 操作就在後台運行.
         若 OS 無法提供, 此時將會彈出對話框, 索要 USB 的 Driver

    - Host 分配並加載 Device 驅動程序, 這時就可能作應用中的數據傳輸了

    - Host 發送`Set_Configuration(x)`(寫配置)命令請求, 為該 Device 選擇一個合適的配置(x 代表非 0 的配置值).
    如果配置成功, USB Device 進入 `Configured` status, 並可以和客戶軟件進行數據傳輸.
    此時, 常規的 USB 完成了其必須進行的配置和連接工作, 至此 Device 應當可以開始使用.
    不過, USB 協議還提供了一些用戶可選的協議, Device 如果不應答, 也不會出錯, 但是會影響到系統的功能.

    - Host 為復合 Device 接口分配驅動程序. 如果 Hub 檢測到有 excess current (大電流), 或者 Host 要求 Hub 關閉電源, 則 USB bus 切斷 Device 供電電源.
    在這種情況下, Device 與 Host 無法通信, 但 Device 處於連接狀態



# Reference
+ [USB 列舉教學，詳解](https://wwssllabcd.github.io/2012/11/28/usb-emulation/)
+ [USB列舉過程](https://www.796t.com/p/123921.html)


