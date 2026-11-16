
📌 VexRiscv Murax SoC 開發進度與環境交接文件


# 1. 專案目標與目前狀態

+ 開發目標: 在 VexRiscv 專案上,將原生的 5 階管線 Murax SoC 精簡為 3 階管線(Fetch + Decode + Execute),同時完整保留 JTAG 除錯(DebugPlugin)、CSR 中斷控制(CsrPlugin) 與 UART / Timer 外部中斷,並準備進一步加入 Embedded Flash(eFlash) 支援。
+ 目前完成進度(皆已驗證通過):
	1. ✅ 硬體管線修改: 已修改原生 `Murax.scala` 為 3 階管線(方案 A),並成功透過 sbt 產生 `Murax.v` 與 `cpu0.yaml`。
	2. ✅ Verilator 行為模擬: 已解決 SpinalHDL 1.13.0 $urandom 與舊版 Verilator 的相容性問題,成功啟動 `./obj_dir/VMurax`,驗證 BOOT 訊息與 UART RX/TX 中斷迴響正常。
	3. ✅ OpenOCD / JTAG 除錯打通: 已建立專屬 `murax.cfg`(修正 4-bit IR 寬度與 jtagMapping),透過 OpenOCD + Telnet (localhost:4444) 成功驗證 `halt`、`reg pc`(0x800003c0)與 `step`(0x800003c4)單步執行。
	4. ✅ 韌體快速更新流程: 已建立 `update_ram.py`,可直接將編譯出的 `.bin` 檔切分為 4 個 byte-lane 初始化檔(`Murax.v_toplevel_system_ram_ram_symbol0~3.bin`,各 1024 行 / 9216 bytes),免重編 Verilog 即可載入新韌體模擬。

# 2. 關鍵硬體修改(src/main/scala/vexriscv/demo/Murax.scala)

採用 方案 A(3 階管線: Fetch -> Decode -> Execute),保留 RegFilePlugin(plugin.SYNC) 以使用 FPGA Block RAM 節省 LUT 資源。
相較於官方原生 Murax.scala 的唯一差異如下(共修改 3 處):

```diff
--- a/Murax.scala
+++ b/Murax.scala
@@ -85,7 +85,12 @@
         earlyInjection = false,
         bigEndian = bigEndian
       ),
-      new CsrPlugin(CsrPluginConfig.smallest(mtvecInit = if(withXip) 0xE0040020l else 0x80000020l)),
+      new CsrPlugin(
+        CsrPluginConfig.smallest(mtvecInit = if(withXip) 0xE0040020l else 0x80000020l).copy(
+          pipelineCsrRead = false,
+          deterministicInteruptionEntry = true
+        )
+      ),
       new DecoderSimplePlugin(
         catchIllegalInstruction = false
       ),
@@ -108,7 +113,7 @@
         pessimisticAddressMatch = false
       ),
       new BranchPlugin(
-        earlyBranch = false,
+        earlyBranch = true,
         catchAddressMisaligned = false
       ),
       new YamlPlugin("cpu0.yaml")
@@ -213,6 +218,8 @@
     //Instanciate the CPU
     val cpu = new VexRiscv(
       config = VexRiscvConfig(
+        withMemoryStage = false,
+        withWriteBackStage = false,
         plugins = cpuPlugins += new DebugPlugin(debugClockDomain, hardwareBreakpointCount)
       )
     )
```

(註: 原生 Murax.scala 已包含 externalInterrupt setWhen(uartCtrl.io.interrupt) 與 timerInterrupt setWhen(timer.io.interrupt) 連線。)

# 3. 開發環境與工具鏈關鍵設定(避坑備忘)


## A. 開發環境版本

+ 專案路徑: `/home/padauk/Working/vexriscv/VexRiscv`
+ SpinalHDL 版本: v1.13.0(產生的 Murax.v 預設含 `$urandom`,需轉為 `$random` 以相容本地 Verilator)
+ OpenOCD 版本: 0.11.0+dev(SpinalHDL 分支版,支援 vexriscv target)

## B. 產生 Verilog 與啟動 Verilator 模擬指令

```bash
# 1. 在專案根目錄產生帶初始化 RAM 的 Verilog 與 cpu0.yaml
sbt "runMain vexriscv.demo.MuraxWithRamInit"
sed -i 's/\$urandom/\$random/g' Murax.v

# 2. 編譯並執行 Verilator 模擬器(開啟 JTAG TCP port 7894 與 UART 終端)
cd src/test/cpp/murax
make clean run
```


## C. OpenOCD 連線設定檔(murax.cfg,位於專案根目錄)

關鍵細節: Murax.v 中 `JtagBridge` 的 `jtag_tap_instruction` 為 4-bit(`IR=1` 為 IDCODE,`IR=2` 為寫入,`IR=3` 為讀取),因此 `-irlen` 必須設為 4,且 `jtagMapping` 必須設為 `2 3 0 0 0 0`:

```tcl
adapter driver jtag_tcp
adapter speed 1000

set _CHIPNAME riscv
jtag newtap $_CHIPNAME cpu -irlen 4 -expected-id 0x10001fff

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME

vexriscv readWaitCycles 100
vexriscv cpuConfigFile cpu0.yaml
vexriscv jtagMapping 2 3 0 0 0 0

reset_config none
init
```


+ 啟動 `OpenOCD: openocd -f ./murax.cfg`(忽略啟動初期的無害提示 `Socket operation on non-socket`,出現 `[riscv.cpu] Target successfully examined`. 即連線成功)。
+ Telnet 除錯: `telnet localhost 4444` -> `halt` / `reg pc` / `step` / `resume`。

## D. 韌體更新腳本(src/test/cpp/murax/update_ram.py)

+ 將 `src/main/c/murax/hello_world/build/hello_world.bin` 依照 Little-Endian 拆分成 4 個 8-bit ASCII 二進位檔(`symbol0~3.bin`),
    並自動補滿 `00000000` 至 1024 行(對應 4 kB RAM)。
+ 更新後不可執行 `make clean run`(會覆蓋 `.bin`),直接執行 `./obj_dir/VMurax` 即可載入新程式。

# 4. 下一步待辦事項(Next Steps)

+ 加入 Embedded Flash(eFlash)支援:
	- 在 Murax.scala 的 `mainBusMapping` 中掛載唯讀 Flash 控制器(例如映射到 `0x00000000`),並將 `IBusSimplePlugin` 的 `resetVector` 指向 Flash 起始位址。
	- 保留 `0x80000000` 的 On-chip SRAM 專門存放 `.data`、`.bss` 與 Stack。
	- 同步調整 C 語言軟體專案的 `linker.ld` 與啟動檔 `crt.S`(在開機時將 `.data` 從 Flash 搬移至 SRAM)。

+ 軟硬體功能驗證與 FPGA 綜合:
	- 在 C 語言韌體中驗證 Timer 定時中斷與 UART 接收中斷,並評估 3 階管線 + eFlash 在目標晶片上的資源與時脈表現。

交接提示: 在新對話串貼上此文件後,你可以直接告訴 Gemini 你的目標平台是 ASIC(特定 eFlash IP) 還是 特定 FPGA 型號,
         請它直接幫你撰寫 `MuraxEmbeddedFlash` 控制器與對應的 linker.ld / crt.S。
