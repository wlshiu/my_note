FPGA Design Flow (Concept)
---

Overall flow

```
+----------------------+    +------------+    +------------+
| Design Specification | -> | RTL Coding | -> | Simulation |
+----------------------+    +------------+    +------------+

    +-----------+    +----------------+    +--------------+
 -> | Synthesis | -> | Implementation | -> | Verification |
    +-----------+    +----------------+    +--------------+

```

+ Design Specification
    > 決定要做什麼功能的電路, 並規劃好架構,
    >> 像是要用多少資源, 速度要多快, FSM 該怎麼切等等

+ RTL Coding
    > 決定好架構後, 就可以開始 coding 了, 可以是 verilog 或 VHDL

+ Simulation
    > 寫完 RTL code 之後, 緊接著就是寫 test bench 來驗證行為正確性

+ Synthesis
    > 寫完的 RTL code 需經過合成, 把寫的 RTL 轉換成 Netlist 形式 (gate-level)
    >> gate-level 指的是, 把全部描述語言, 轉換成邏輯閘表示

    > 之後在做 place & route 時, 就是以 Netlist 為輸入檔,
    >> 假設你寫一個 1-bit 加法器, 就會產生以下的 netlist.v 檔

    ```verilog
    module Full_Adder( A, B, Cin, Sum, Cout );

        input A, B, Cin;
        output Sum, Cout;

        wire W1, W2, W3;

        xor xor1( W1, A, B );
        and and1( W2, W1, Cin );
        and and2( W3, A, B );
        xor xor2( Sum, W1, Cin );
        or  or1( Cout, W2, W3 );

    endmodule
    ```

+ Implementation
    > 當產生完 Netlist 檔之後, 就須決定各個 module, 裡面邏輯閘的擺放位置以及繞線
    >> 這個步驟是非常重要的, 因為這牽涉到電路是不是一個及格電路

    > 合格的電路除了要求的功能要對以外, timing 也要 MET (假設 clock 是 100MHz, 你的邏輯運算, 加上繞線的時間, 需要在 10ns 內完成),
    所以除了電路要寫的簡潔外, 再配合 EDA tool 的演算法, 最終才能完成一個合格的電路


+ Verification
    > 最後就是上板子實際驗證電路的正確性, 一般來說, test bench 驗證對了, timing 也沒有問題的話, 最後的電路大多都沒什麼問題

# Reference

+ [[Day25]淺談FPGA design flow - iT 邦幫忙::一起幫忙解決難題, 拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10195959)


