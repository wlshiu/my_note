package vexriscv.demo

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.bus.simple.PipelinedMemoryBus
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.spi.ddr.SpiXdrMaster
import spinal.lib.com.uart._
import spinal.lib.com.i2c._
import spinal.lib.com.spi._
import spinal.lib.io.{InOutWrapper, TriStateArray}
import spinal.lib.misc.{InterruptCtrl, Prescaler, Timer}
import spinal.lib.soc.pinsec.{PinsecTimerCtrl, PinsecTimerCtrlExternal}
import vexriscv.plugin._
import vexriscv.{VexRiscv, VexRiscvConfig, plugin}
import spinal.lib.com.spi.ddr._
import spinal.lib.bus.simple._
import scala.collection.mutable.ArrayBuffer
import scala.collection.Seq
import spinal.lib.com.jtag.JtagTapInstructionCtrl
import spinal.lib.misc.HexTools

/**
 * Created by PIC32F_USER on 28/07/2017.
 *
 * Murax is a very light SoC which could work without any external component.
 * - ICE40-hx8k + icestorm =>  53 MHz, 2142 LC
 * - 0.37 DMIPS/MHz
 * - 8 kB of on-chip ram
 * - JTAG debugger (eclipse/GDB/openocd ready)
 * - Interrupt support
 * - APB bus for peripherals
 * - 32 GPIO pin
 * - one 16 bits prescaler, two 16 bits timers
 * - one UART with tx/rx fifo
 */


case class MuraxConfig(coreFrequency : HertzNumber,
                       onChipRamSize      : BigInt,
                       onChipRamHexFile   : String,
                       eFlashSize         : BigInt,
                       eFlashHexFile      : String,
                       pipelineDBus       : Boolean,
                       pipelineMainBus    : Boolean,
                       pipelineApbBridge  : Boolean,
                       gpioWidth          : Int,
                       uartCtrlConfig     : UartCtrlMemoryMappedConfig,
                       spiMasterConfig    : SpiMasterCtrlMemoryMappedConfig,
                       i2cConfig          : I2cSlaveMemoryMappedGenerics,
                       xipConfig          : SpiXdrMasterCtrl.MemoryMappingParameters,
                       hardwareBreakpointCount : Int,
                       withNativeJtag      : Boolean,
                       cpuPlugins         : ArrayBuffer[Plugin[VexRiscv]]
                       ){
  require(pipelineApbBridge || pipelineMainBus, "At least pipelineMainBus or pipelineApbBridge should be enable to avoid wipe transactions")
  val genXip = xipConfig != null

}



object MuraxConfig{
  def default : MuraxConfig = default(false, false)
  def default(withXip : Boolean = false, bigEndian : Boolean = false) =  MuraxConfig(
    coreFrequency         = 32 MHz,
    onChipRamSize         = 2 kB,
    onChipRamHexFile      = null,
    eFlashSize            = 32 kB,
    eFlashHexFile         = null,
    pipelineDBus          = true,
    pipelineMainBus       = false,
    pipelineApbBridge     = true,
    gpioWidth = 16,
    xipConfig = ifGen(withXip) (SpiXdrMasterCtrl.MemoryMappingParameters(
      SpiXdrMasterCtrl.Parameters(8, 12, SpiXdrParameter(2, 2, 1)).addFullDuplex(0,1,false),
      cmdFifoDepth = 32,
      rspFifoDepth = 32,
      xip = SpiXdrMasterCtrl.XipBusParameters(addressWidth = 24, lengthWidth = 2)
    )),
    hardwareBreakpointCount = 4,
    withNativeJtag = false,
    cpuPlugins = ArrayBuffer( //DebugPlugin added by the toplevel
      new IBusSimplePlugin(
        resetVector = if(withXip) 0xF001E000l else 0x00000000l,
        cmdForkOnSecondStage = true,
        cmdForkPersistence = withXip, //Required by the Xip controller
        prediction = NONE,
        catchAccessFault = true,
        compressedGen = true,
        bigEndian = bigEndian
      ),
      new DBusSimplePlugin(
        catchAddressMisaligned = true,
        catchAccessFault = true,
        earlyInjection = false,
        bigEndian = bigEndian
      ),
      new CsrPlugin(
        CsrPluginConfig.smallest(mtvecInit = if(withXip) 0xE0040020l else 0x00000020l).copy(
          mepcAccess = CsrAccess.READ_WRITE,
          ecallGen = true,
          ebreakGen = true,
          wfiGenAsWait = true,
          deterministicInteruptionEntry = true
        )
      ),
      new DecoderSimplePlugin(
        catchIllegalInstruction = true
      ),
      new RegFilePlugin(
        regFileReadyKind = plugin.SYNC,
        zeroBoot = false,
        rv32e = true
      ),
      new IntAluPlugin,
      new SrcPlugin(
        separatedAddSub = false,
        executeInsertion = false
      ),
      new LightShifterPlugin,
      new MulSimplePlugin,
      new DivPlugin,
      new HazardSimplePlugin(
        bypassExecute = false,
        bypassMemory = false,
        bypassWriteBack = false,
        bypassWriteBackBuffer = false,
        pessimisticUseSrc = false,
        pessimisticWriteRegFile = false,
        pessimisticAddressMatch = false
      ),
      new BranchPlugin(
        earlyBranch = true,
        catchAddressMisaligned = false
      ),
      new YamlPlugin("cpu0.yaml")
    ),
    uartCtrlConfig = UartCtrlMemoryMappedConfig(
      uartCtrlConfig = UartCtrlGenerics(
        dataWidthMax      = 8,
        clockDividerWidth = 20,
        preSamplingSize   = 1,
        samplingSize      = 3,
        postSamplingSize  = 1
      ),
      initConfig = UartCtrlInitConfig(
        baudrate = 115200,
        dataLength = 7,  //7 => 8 bits
        parity = UartParityType.NONE,
        stop = UartStopType.ONE
      ),
      busCanWriteClockDividerConfig = false,
      busCanWriteFrameConfig = false,
      txFifoDepth = 4,
      rxFifoDepth = 4
    ),
    spiMasterConfig = SpiMasterCtrlMemoryMappedConfig(
      ctrlGenerics = SpiMasterCtrlGenerics(
        ssWidth      = 1,
        timerWidth   = 16,
        dataWidth    = 8
      ),
      cmdFifoDepth = 4,
      rspFifoDepth = 4
    ),
    i2cConfig = I2cSlaveMemoryMappedGenerics(
      ctrlGenerics = I2cSlaveGenerics(
        samplingWindowSize        = 3,
        samplingClockDividerWidth = 10 bits,
        timeoutWidth              = 20 bits
      ),
      addressFilterCount = 0,
      masterGenerics = I2cMasterMemoryMappedGenerics(
        timerWidth = 12
      )
    )

  )

  def fast = {
    val config = default

    //Replace HazardSimplePlugin to get datapath bypass
    config.cpuPlugins(config.cpuPlugins.indexWhere(_.isInstanceOf[HazardSimplePlugin])) = new HazardSimplePlugin(
      bypassExecute = true,
      bypassMemory = true,
      bypassWriteBack = true,
      bypassWriteBackBuffer = true
    )
//    config.cpuPlugins(config.cpuPlugins.indexWhere(_.isInstanceOf[LightShifterPlugin])) = new FullBarrelShifterPlugin()

    config
  }
}

// Read-Only Embedded Flash emulated by FPGA Block RAM
class MuraxEmbeddedFlash(eFlashSize : BigInt,
                         eFlashHexFile : String,
                         pipelinedMemoryBusConfig : PipelinedMemoryBusConfig,
                         bigEndian : Boolean = false) extends Component{
  val io = new Bundle{
    val bus = slave(PipelinedMemoryBus(pipelinedMemoryBusConfig))
    val writeError = out Bool()
  }

  val flash = Mem(Bits(32 bits), eFlashSize / 4)
  if(eFlashHexFile != null){
    HexTools.initRam(flash, eFlashHexFile, 0x00000000l)
  }

  io.bus.cmd.ready := True
  io.bus.rsp.valid := RegNext(io.bus.cmd.fire && !io.bus.cmd.write) init(False)
  io.writeError    := RegNext(io.bus.cmd.fire && io.bus.cmd.write) init(False)
  io.bus.rsp.data  := flash.readSync(
    address = io.bus.cmd.address(2, log2Up(eFlashSize / 4) bits),
    enable  = io.bus.cmd.fire && !io.bus.cmd.write
  )
}

// Custom Timer with split interrupts: Timer A -> MTI, Timer B -> MEI
class MuraxSplitApb3Timer extends Component {
  val io = new Bundle {
    val apb        = slave(Apb3(Apb3Config(addressWidth = 8, dataWidth = 32)))
    val interruptA = out Bool()
    val interruptB = out Bool()
  }

  val prescaler = Prescaler(16)
  val timerA    = Timer(16)
  val timerB    = Timer(16)

  val busCtrl = Apb3SlaveFactory(io.apb)
  val prescalerBridge = prescaler.driveFrom(busCtrl, 0x00)

  val timerABridge = timerA.driveFrom(busCtrl, 0x40)(
    ticks  = List(True, prescaler.io.overflow),
    clears = List(timerA.io.full)
  )

  val timerBBridge = timerB.driveFrom(busCtrl, 0x50)(
    ticks  = List(True, prescaler.io.overflow),
    clears = List(timerB.io.full)
  )

  val interruptCtrl = InterruptCtrl(2)
  val interruptCtrlBridge = interruptCtrl.driveFrom(busCtrl, 0x10)
  interruptCtrl.io.inputs(0) := timerA.io.full
  interruptCtrl.io.inputs(1) := timerB.io.full

  // Split interrupt outputs instead of OR-ing them together
  io.interruptA := interruptCtrl.io.pendings(0) && interruptCtrl.io.masks(0)
  io.interruptB := interruptCtrl.io.pendings(1) && interruptCtrl.io.masks(1)
}

// APB3 SysCtrl & 16-Pin IOPAD PinMux Controller (Base: 0xF0050000)
class MuraxSysCtrlPinMux(gpioWidth: Int, withNativeJtag: Boolean) extends Component {
  require(gpioWidth == 16, "MuraxSysCtrlPinMux requires gpioWidth == 16")

  val io = new Bundle {
    val apb        = slave(Apb3(Apb3Config(addressWidth = 8, dataWidth = 32)))

    // Internal peripheral interfaces
    val gpio       = slave(TriStateArray(16 bits))
    val uart       = slave(Uart())
    val spi        = slave(SpiMaster(ssWidth = 1))
    val i2c        = slave(I2c())
    val jtag       = ifGen(!withNativeJtag)(master(Jtag()))

    // Unified 16-pin Physical IOPAD interface
    val iopad      = master(TriStateArray(16 bits))
  }

  val busCtrl = Apb3SlaveFactory(io.apb)

  // 0x00: PINMUX_SEL0 (IOPAD[7:0], 2 bits per pin, default 0 = GPIO)
  // 0x04: PINMUX_SEL1 (IOPAD[15:8], 2 bits per pin, IOPAD[15:12] default 1 = JTAG -> 0x5500)
  val pinMuxSel0 = Reg(Bits(16 bits)) init(0x0000)
  val pinMuxSel1 = Reg(Bits(16 bits)) init(0x5500)
  val pinMuxLock = Reg(Bool()) init(False)

  busCtrl.read(pinMuxSel0, 0x00, 0)
  busCtrl.read(pinMuxSel1, 0x04, 0)
  busCtrl.onWrite(0x00) {
    when(!pinMuxLock) { pinMuxSel0 := io.apb.PWDATA(15 downto 0) }
  }
  busCtrl.onWrite(0x04) {
    when(!pinMuxLock) { pinMuxSel1 := io.apb.PWDATA(15 downto 0) }
  }

  // 0x08: SYS_STATUS (Read-Only: [31:16]=32 MHz, [7:0]=0x16 ID)
  busCtrl.read(B(0x00200016L, 32 bits), 0x08, 0)

  // 0x0C: PINMUX_LOCK (Write-1-Once Lock Bit: [0]=1 locks PINMUX_SEL0/1 until reset)
  busCtrl.read(pinMuxLock, 0x0C, 0)
  busCtrl.setOnSet(pinMuxLock, 0x0C, 0)

  val sel = Vec(Bits(2 bits), 16)
  for (i <- 0 until 8) {
    sel(i)     := pinMuxSel0(i * 2, 2 bits)
    sel(i + 8) := pinMuxSel1(i * 2, 2 bits)
  }

  // Default all IOPADs to GPIO
  for (i <- 0 until 16) {
    io.iopad.write(i)       := io.gpio.write(i)
    io.iopad.writeEnable(i) := io.gpio.writeEnable(i)
    io.gpio.read(i)         := io.iopad.read(i)
  }

  // IOPAD[0]: Mode 1 = UART_TXD
  when(sel(0) === 1) {
    io.iopad.write(0)       := io.uart.txd
    io.iopad.writeEnable(0) := True
  }

  // IOPAD[1]: Mode 1 = UART_RXD
  io.uart.rxd := (sel(1) === 1) ? io.iopad.read(1) | True
  when(sel(1) === 1) {
    io.iopad.writeEnable(1) := False
  }

  // IOPAD[2]: Mode 1 = I2C_SCL (Open-Drain: drive 0 when write == 0)
  io.i2c.scl.read := (sel(2) === 1) ? io.iopad.read(2) | True
  when(sel(2) === 1) {
    io.iopad.write(2)       := False
    io.iopad.writeEnable(2) := !io.i2c.scl.write
  }

  // IOPAD[3]: Mode 1 = I2C_SDA (Open-Drain: drive 0 when write == 0)
  io.i2c.sda.read := (sel(3) === 1) ? io.iopad.read(3) | True
  when(sel(3) === 1) {
    io.iopad.write(3)       := False
    io.iopad.writeEnable(3) := !io.i2c.sda.write
  }

  // IOPAD[4..7]: Mode 2 = SPI Master (SS0, SCLK, MOSI, MISO)
  when(sel(4) === 2) {
    io.iopad.write(4)       := io.spi.ss(0)
    io.iopad.writeEnable(4) := True
  }
  when(sel(5) === 2) {
    io.iopad.write(5)       := io.spi.sclk
    io.iopad.writeEnable(5) := True
  }
  when(sel(6) === 2) {
    io.iopad.write(6)       := io.spi.mosi
    io.iopad.writeEnable(6) := True
  }
  io.spi.miso := (sel(7) === 2) ? io.iopad.read(7) | True
  when(sel(7) === 2) {
    io.iopad.writeEnable(7) := False
  }

  // IOPAD[12..15]: Mode 1 = JTAG (TMS, TCK, TDI, TDO) - Enabled by default at reset
  if (!withNativeJtag) {
    io.jtag.tms := (sel(12).addTag(crossClockDomain) === 1) ? io.iopad.read(12) | True
    when(sel(12) === 1) { io.iopad.writeEnable(12) := False }

    io.jtag.tck := (sel(13).addTag(crossClockDomain) === 1) ? io.iopad.read(13) | False
    when(sel(13) === 1) { io.iopad.writeEnable(13) := False }

    io.jtag.tdi := (sel(14).addTag(crossClockDomain) === 1) ? io.iopad.read(14) | True
    when(sel(14) === 1) { io.iopad.writeEnable(14) := False }

    when(sel(15) === 1) {
      io.iopad.write(15)       := io.jtag.tdo
      io.iopad.writeEnable(15) := True
    }
  }
}

case class Murax(config : MuraxConfig) extends Component{
  import config._

  val io = new Bundle {
    //Clocks / reset
    val asyncReset = in Bool()
    val mainClk = in Bool()
    val inWfi = out Bool()

    // Unified 16-pin Physical IOPAD (Multiplexes GPIO[15:0], UART, SPI, I2C, JTAG)
    val iopad = master(TriStateArray(gpioWidth bits))

    val xip = ifGen(genXip)(master(SpiXdrMaster(xipConfig.ctrl.spi)))
  }

  val jtagNative = withNativeJtag generate new ClockingArea(debugClockDomain){
    val jtagCtrl = JtagTapInstructionCtrl()
    val tap = jtagCtrl.fromXilinxBscane2(userId = 2)
  }

  val resetCtrlClockDomain = ClockDomain(
    clock = io.mainClk,
    config = ClockDomainConfig(
      resetKind = BOOT
    )
  )

  val resetCtrl = new ClockingArea(resetCtrlClockDomain) {
    val mainClkResetUnbuffered  = False

    //Implement an counter to keep the reset axiResetOrder high 64 cycles
    // Also this counter will automatically do a reset when the system boot.
    val systemClkResetCounter = Reg(UInt(6 bits)) init(0)
    when(systemClkResetCounter =/= U(systemClkResetCounter.range -> true)){
      systemClkResetCounter := systemClkResetCounter + 1
      mainClkResetUnbuffered := True
    }
    when(BufferCC(io.asyncReset)){
      systemClkResetCounter := 0
    }

    //Create all reset used later in the design
    val mainClkReset = RegNext(mainClkResetUnbuffered)
    val systemReset  = RegNext(mainClkResetUnbuffered)
  }


  val systemClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.systemReset,
    frequency = FixedFrequency(coreFrequency)
  )

  val debugClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.mainClkReset,
    frequency = FixedFrequency(coreFrequency)
  )

  val system = new ClockingArea(systemClockDomain) {
    val pipelinedMemoryBusConfig = PipelinedMemoryBusConfig(
      addressWidth = 32,
      dataWidth = 32
    )

    val bigEndianDBus = config.cpuPlugins.exists(_ match{ case plugin : DBusSimplePlugin => plugin.bigEndian case _ => false})

    //Arbiter of the cpu dBus/iBus to drive the mainBus
    //Priority to dBus, !! cmd transactions can change on the fly !!
    val mainBusArbiter = new MuraxSafeMasterArbiter(pipelinedMemoryBusConfig, bigEndianDBus)

    //Instanciate the CPU
    val cpu = new VexRiscv(
      config = VexRiscvConfig(
        withMemoryStage = false,
        withWriteBackStage = false,
        plugins = cpuPlugins += new DebugPlugin(debugClockDomain, hardwareBreakpointCount)
      )
    )

    // Instantiate SysCtrl & PinMux early so JTAG can bind cleanly
    val sysCtrl = new MuraxSysCtrlPinMux(gpioWidth, config.withNativeJtag)
    sysCtrl.io.iopad <> io.iopad

    //Checkout plugins used to instanciate the CPU to connect them to the SoC
    val timerInterrupt = False
    val externalInterrupt = False
    for(plugin <- cpu.plugins) plugin match{
      case plugin : IBusSimplePlugin =>
        mainBusArbiter.io.iBus.cmd <> plugin.iBus.cmd
        mainBusArbiter.io.iBus.rsp <> plugin.iBus.rsp
      case plugin : DBusSimplePlugin => {
        if(!pipelineDBus)
          mainBusArbiter.io.dBus <> plugin.dBus
        else {
          mainBusArbiter.io.dBus.cmd << plugin.dBus.cmd.halfPipe()
          mainBusArbiter.io.dBus.rsp <> plugin.dBus.rsp
        }
      }
      case plugin : CsrPlugin        => {
        plugin.externalInterrupt := externalInterrupt
        plugin.timerInterrupt := timerInterrupt
        var rawInWfi: Bool = null
        var wfiFound: Bool = null
        cpu.rework {
          cpu.dslBody.walkDeclarations {
            case b: Bool if b.getName() != null && b.getName().endsWith("inWfi") =>
              rawInWfi = b
            case _ =>
          }
          require(rawInWfi != null, "CsrPlugin inWfi signal not found!")
          wfiFound = out(Bool()).setName("io_inWfi")
          wfiFound := rawInWfi
        }
        io.inWfi := wfiFound
      }
      case plugin : DebugPlugin         => plugin.debugClockDomain{
        resetCtrl.systemReset setWhen(RegNext(plugin.io.resetOut))
        if (withNativeJtag) {
          jtagNative.jtagCtrl <> plugin.io.bus.fromJtagInstructionCtrl(ClockDomain(jtagNative.tap.TCK),0)
        } else {
          sysCtrl.io.jtag <> plugin.io.bus.fromJtag()
        }
      }
      case _ =>
    }



    //****** MainBus slaves ********
    val mainBusMapping = ArrayBuffer[(PipelinedMemoryBus,SizeMapping)]()
    val eFlash = new MuraxEmbeddedFlash(
      eFlashSize = eFlashSize,
      eFlashHexFile = eFlashHexFile,
      pipelinedMemoryBusConfig = pipelinedMemoryBusConfig,
      bigEndian = bigEndianDBus
    )
    mainBusMapping += eFlash.io.bus -> (0x00000000l, eFlashSize)

    val ram = new MuraxPipelinedMemoryBusRam(
      onChipRamSize = onChipRamSize,
      onChipRamHexFile = onChipRamHexFile,
      pipelinedMemoryBusConfig = pipelinedMemoryBusConfig,
      bigEndian = bigEndianDBus
    )
    mainBusMapping += ram.io.bus -> (0x20000000l, onChipRamSize)

    val apbBridge = new PipelinedMemoryBusToApbBridge(
      apb3Config = Apb3Config(
        addressWidth = 20,
        dataWidth = 32
      ),
      pipelineBridge = pipelineApbBridge,
      pipelinedMemoryBusConfig = pipelinedMemoryBusConfig
    )
    mainBusMapping += apbBridge.io.pipelinedMemoryBus -> (0xF0000000l, 1 MB)



    //******** APB peripherals *********
    val apbMapping = ArrayBuffer[(Apb3, SizeMapping)]()
    val gpioACtrl = Apb3Gpio(gpioWidth = gpioWidth, withReadSync = true)
    sysCtrl.io.gpio <> gpioACtrl.io.gpio
    apbMapping += gpioACtrl.io.apb -> (0x00000, 4 kB)

    val uartCtrl = Apb3UartCtrl(uartCtrlConfig)
    uartCtrl.io.uart <> sysCtrl.io.uart
    externalInterrupt setWhen(uartCtrl.io.interrupt)
    apbMapping += uartCtrl.io.apb  -> (0x10000, 4 kB)

    val timer = new MuraxSplitApb3Timer()
    timerInterrupt    setWhen(timer.io.interruptA)
    externalInterrupt setWhen(timer.io.interruptB)
    apbMapping += timer.io.apb     -> (0x20000, 4 kB)

    val spiCtrl = new Apb3SpiMasterCtrl(spiMasterConfig)
    spiCtrl.io.spi <> sysCtrl.io.spi
    externalInterrupt setWhen(spiCtrl.io.interrupt)
    apbMapping += spiCtrl.io.apb   -> (0x30000, 4 kB)

    val i2cCtrl = new Apb3I2cCtrl(i2cConfig)
    i2cCtrl.io.i2c <> sysCtrl.io.i2c
    externalInterrupt setWhen(i2cCtrl.io.interrupt)
    apbMapping += i2cCtrl.io.apb   -> (0x40000, 4 kB)

    apbMapping += sysCtrl.io.apb   -> (0x50000, 4 kB)

    val xip = ifGen(genXip)(new Area{
      val ctrl = Apb3SpiXdrMasterCtrl(xipConfig)
      ctrl.io.spi <> io.xip
      externalInterrupt setWhen(ctrl.io.interrupt)
      apbMapping += ctrl.io.apb     -> (0x1F000, 4 kB)

      val accessBus = new PipelinedMemoryBus(PipelinedMemoryBusConfig(24,32))
      mainBusMapping += accessBus -> (0xE0000000l, 16 MB)

      ctrl.io.xip.fromPipelinedMemoryBus() << accessBus
      val bootloader = Apb3Rom("src/main/c/murax/xipBootloader/crt.bin")
      apbMapping += bootloader.io.apb     -> (0x1E000, 4 kB)
    })



    //******** Memory mappings *********
    val apbDecoder = Apb3Decoder(
      master = apbBridge.io.apb,
      slaves = apbMapping.toSeq
    )

    val mainBusDecoder = new Area {
      val logic = new MuraxSafePipelinedMemoryBusDecoder(
        master = mainBusArbiter.io.masterBus,
        specification = mainBusMapping.toSeq,
        pipelineMaster = pipelineMainBus
      )

      mainBusArbiter.io.masterBusRspError := logic.io.rspError || eFlash.io.writeError
    }
  }
}

// 支援回報 Access Fault (noHit / Read-Only Violation) 的安全匯流排仲裁器
class MuraxSafeMasterArbiter(pipelinedMemoryBusConfig : PipelinedMemoryBusConfig, bigEndian : Boolean = false) extends Component{
  val io = new Bundle{
    val iBus = slave(IBusSimpleBus(null))
    val dBus = slave(DBusSimpleBus(bigEndian))
    val masterBus = master(PipelinedMemoryBus(pipelinedMemoryBusConfig))
    val masterBusRspError = in Bool()
  }

  io.masterBus.cmd.valid   := io.iBus.cmd.valid || io.dBus.cmd.valid
  io.masterBus.cmd.write   := io.dBus.cmd.valid && io.dBus.cmd.wr
  io.masterBus.cmd.address := io.dBus.cmd.valid ? io.dBus.cmd.address | io.iBus.cmd.pc
  io.masterBus.cmd.data    := io.dBus.cmd.data
  io.masterBus.cmd.mask    := io.dBus.cmd.size.mux(
    0 -> B"0001",
    1 -> B"0011",
    default -> B"1111"
  ) |<< io.dBus.cmd.address(1 downto 0)
  io.iBus.cmd.ready := io.masterBus.cmd.ready && !io.dBus.cmd.valid
  io.dBus.cmd.ready := io.masterBus.cmd.ready

  val rspPending = RegInit(False) clearWhen(io.masterBus.rsp.valid)
  val rspTarget = RegInit(False)
  when(io.masterBus.cmd.fire && !io.masterBus.cmd.write){
    rspTarget  := io.dBus.cmd.valid
    rspPending := True
  }

  when(rspPending && !io.masterBus.rsp.valid){
    io.iBus.cmd.ready := False
    io.dBus.cmd.ready := False
    io.masterBus.cmd.valid := False
  }

  io.iBus.rsp.valid := io.masterBus.rsp.valid && !rspTarget
  io.iBus.rsp.inst  := io.masterBus.rsp.data
  io.iBus.rsp.error := io.masterBusRspError && !rspTarget

  io.dBus.rsp.ready := io.masterBus.rsp.valid && rspTarget
  io.dBus.rsp.data  := io.masterBus.rsp.data
  io.dBus.rsp.error := io.masterBusRspError && rspTarget
}

// 支援未映射位址 (noHit) 回報 rspError 的匯流排解碼器
class MuraxSafePipelinedMemoryBusDecoder(master : PipelinedMemoryBus, val specification : Seq[(PipelinedMemoryBus,SizeMapping)], pipelineMaster : Boolean) extends Area{
  val io = new Bundle {
    val rspError = out Bool()
  }
  val masterPipelined = PipelinedMemoryBus(master.config)
  if(!pipelineMaster) {
    masterPipelined.cmd << master.cmd
    masterPipelined.rsp >> master.rsp
  } else {
    masterPipelined.cmd <-< master.cmd
    masterPipelined.rsp >> master.rsp
  }

  val slaveBuses = specification.map(_._1)
  val memorySpaces = specification.map(_._2)

  val hits = for((slaveBus, memorySpace) <- specification) yield {
    val hit = memorySpace.hit(masterPipelined.cmd.address)
    slaveBus.cmd.valid   := masterPipelined.cmd.valid && hit
    slaveBus.cmd.payload := masterPipelined.cmd.payload
    hit
  }
  val noHit = !hits.orR
  masterPipelined.cmd.ready := (hits, slaveBuses).zipped.map(_ && _.cmd.ready).orR || noHit

  val rspPending  = RegInit(False) clearWhen(masterPipelined.rsp.valid) setWhen(masterPipelined.cmd.fire && !masterPipelined.cmd.write)
  val rspNoHit    = RegNext(noHit) init(False)
  val rspSourceId = RegNextWhen(OHToUInt(hits), masterPipelined.cmd.fire)
  masterPipelined.rsp.valid := slaveBuses.map(_.rsp.valid).orR || (rspPending && rspNoHit)
  masterPipelined.rsp.data  := slaveBuses.map(_.rsp.data).read(rspSourceId)

  // 當發生未映射位址讀取 (rspNoHit) 時，回報匯流排錯誤
  io.rspError := rspPending && rspNoHit

  when(rspPending && !masterPipelined.rsp.valid) {
    masterPipelined.cmd.ready := False
    slaveBuses.foreach(_.cmd.valid := False)
  }
}


object Murax{
  def main(args: Array[String]) {
    SpinalVerilog(Murax(MuraxConfig.default))
  }
}

object MuraxCfu{
  def main(args: Array[String]) {
    SpinalVerilog{
      val config = MuraxConfig.default
      config.cpuPlugins += new CfuPlugin(
        stageCount = 1,
        allowZeroLatency = true,
        encodings = List(
          CfuPluginEncoding (
            instruction = M"-------------------------0001011",
            functionId = List(14 downto 12),
            input2Kind = CfuPlugin.Input2Kind.RS
          )
        ),
        busParameter = CfuBusParameter(
          CFU_VERSION = 0,
          CFU_INTERFACE_ID_W = 0,
          CFU_FUNCTION_ID_W = 3,
          CFU_REORDER_ID_W = 0,
          CFU_REQ_RESP_ID_W = 0,
          CFU_INPUTS = 2,
          CFU_INPUT_DATA_W = 32,
          CFU_OUTPUTS = 1,
          CFU_OUTPUT_DATA_W = 32,
          CFU_FLOW_REQ_READY_ALWAYS = false,
          CFU_FLOW_RESP_READY_ALWAYS = false,
          CFU_WITH_STATUS = true,
          CFU_RAW_INSN_W = 32,
          CFU_CFU_ID_W = 4,
          CFU_STATE_INDEX_NUM = 5
        )
      )

      val toplevel = Murax(config)

      toplevel.rework {
        for (plugin <- toplevel.system.cpu.plugins) plugin match {
          case plugin: CfuPlugin => plugin.bus.toIo().setName("miaou")
          case _ =>
        }
      }

      toplevel
    }
  }
}


object Murax_iCE40_hx8k_breakout_board_xip{

  case class SB_GB() extends BlackBox{
    val USER_SIGNAL_TO_GLOBAL_BUFFER = in Bool()
    val GLOBAL_BUFFER_OUTPUT = out Bool()
  }

  case class SB_IO_SCLK() extends BlackBox{
    addGeneric("PIN_TYPE", B"010000")
    val PACKAGE_PIN = out Bool()
    val OUTPUT_CLK = in Bool()
    val CLOCK_ENABLE = in Bool()
    val D_OUT_0 = in Bool()
    val D_OUT_1 = in Bool()
    setDefinitionName("SB_IO")
  }

  case class SB_IO_DATA() extends BlackBox{
    addGeneric("PIN_TYPE", B"110000")
    val PACKAGE_PIN = inout(Analog(Bool))
    val CLOCK_ENABLE = in Bool()
    val INPUT_CLK = in Bool()
    val OUTPUT_CLK = in Bool()
    val OUTPUT_ENABLE = in Bool()
    val D_OUT_0 = in Bool()
    val D_OUT_1 = in Bool()
    val D_IN_0 = out Bool()
    val D_IN_1 = out Bool()
    setDefinitionName("SB_IO")
  }

  case class Murax_iCE40_hx8k_breakout_board_xip() extends Component{
    val io = new Bundle {
      val mainClk  = in  Bool()
      val jtag_tck = in  Bool()
      val jtag_tdi = in  Bool()
      val jtag_tdo = out Bool()
      val jtag_tms = in  Bool()
      val uart_txd = out Bool()
      val uart_rxd = in  Bool()

      val mosi = inout(Analog(Bool))
      val miso = inout(Analog(Bool))
      val sclk = out Bool()
      val spis = out Bool()

      val led = out Bits(8 bits)
    }
    val murax = Murax(MuraxConfig.default(withXip = true).copy(onChipRamSize = 8 kB))
    murax.io.asyncReset := False

    val mainClkBuffer = SB_GB()
    mainClkBuffer.USER_SIGNAL_TO_GLOBAL_BUFFER <> io.mainClk
    mainClkBuffer.GLOBAL_BUFFER_OUTPUT <> murax.io.mainClk

    // Connect to the unified 16-bit IOPAD interface
    murax.io.iopad.read := 0

    // UART (IOPAD[0] = TXD, IOPAD[1] = RXD)
    io.uart_txd := murax.io.iopad.write(0)
    murax.io.iopad.read(1) := io.uart_rxd

    // LEDs mapped to IOPAD[11:8] (4 bits available alongside peripherals)
    io.led := murax.io.iopad.write(11 downto 8).resized

    // JTAG (IOPAD[12]=TMS, IOPAD[13]=TCK, IOPAD[14]=TDI, IOPAD[15]=TDO)
    val jtagClkBuffer = SB_GB()
    jtagClkBuffer.USER_SIGNAL_TO_GLOBAL_BUFFER <> io.jtag_tck
    murax.io.iopad.read(13) := jtagClkBuffer.GLOBAL_BUFFER_OUTPUT

    murax.io.iopad.read(12) := io.jtag_tms
    murax.io.iopad.read(14) := io.jtag_tdi
    io.jtag_tdo := murax.io.iopad.write(15)



    val xip = new ClockingArea(murax.systemClockDomain) {
      RegNext(murax.io.xip.ss.asBool) <> io.spis

      val sclkIo = SB_IO_SCLK()
      sclkIo.PACKAGE_PIN <> io.sclk
      sclkIo.CLOCK_ENABLE := True

      sclkIo.OUTPUT_CLK := ClockDomain.current.readClockWire
      sclkIo.D_OUT_0 <> murax.io.xip.sclk.write(0)
      sclkIo.D_OUT_1 <> RegNext(murax.io.xip.sclk.write(1))

      val datas = for ((data, pin) <- (murax.io.xip.data, List(io.mosi, io.miso)).zipped) yield new Area {
        val dataIo = SB_IO_DATA()
        dataIo.PACKAGE_PIN := pin
        dataIo.CLOCK_ENABLE := True

        dataIo.OUTPUT_CLK := ClockDomain.current.readClockWire
        dataIo.OUTPUT_ENABLE <> data.writeEnable
        dataIo.D_OUT_0 <> data.write(0)
        dataIo.D_OUT_1 <> RegNext(data.write(1))

        dataIo.INPUT_CLK := ClockDomain.current.readClockWire
        data.read(0) := dataIo.D_IN_0
        data.read(1) := RegNext(dataIo.D_IN_1)
      }
    }

  }

  def main(args: Array[String]) {
    SpinalVerilog(Murax_iCE40_hx8k_breakout_board_xip())
  }
}

object MuraxDhrystoneReady{
  def main(args: Array[String]) {
    SpinalVerilog(Murax(MuraxConfig.fast.copy(onChipRamSize = 256 kB)))
  }
}

object MuraxDhrystoneReadyMulDivStatic{
  def main(args: Array[String]) {
    SpinalVerilog({
      val config = MuraxConfig.fast.copy(onChipRamSize = 256 kB)
      config.cpuPlugins += new MulPlugin
      config.cpuPlugins += new DivPlugin
      config.cpuPlugins.remove(config.cpuPlugins.indexWhere(_.isInstanceOf[BranchPlugin]))
      config.cpuPlugins +=new BranchPlugin(
        earlyBranch = false,
        catchAddressMisaligned = false
      )
      config.cpuPlugins += new IBusSimplePlugin(
        resetVector = 0x00000000l,
        cmdForkOnSecondStage = true,
        cmdForkPersistence = false,
        prediction = STATIC,
        catchAccessFault = false,
        compressedGen = false
      )
      config.cpuPlugins.remove(config.cpuPlugins.indexWhere(_.isInstanceOf[LightShifterPlugin]))
      config.cpuPlugins += new FullBarrelShifterPlugin
      Murax(config)
    })
  }
}

//Will blink led and echo UART RX to UART TX   (in the verilator sim, type some text and press enter to send UART frame to the Murax RX pin)
object MuraxWithRamInit{
  def main(args: Array[String]) {
    // ---- For Verilator simulation ----
    // SpinalVerilog(Murax(MuraxConfig.default.copy(eFlashSize = 32 kB, eFlashHexFile = "src/main/ressource/hex/muraxDemo.hex", onChipRamSize = 2 kB)))
    SpinalVerilog(Murax(MuraxConfig.default.copy(eFlashSize = 32 kB, eFlashHexFile = "src/main/ressource/hex/my_hello.hex", onChipRamSize = 2 kB)))

    // ---- For FPGA ----
    // SpinalConfig(
    //   noRandBoot = true
    // ).generateVerilog(
    //   Murax(MuraxConfig.default.copy(
    //     eFlashSize = 32 kB,
    //     eFlashHexFile = "src/main/ressource/hex/my_hello.hex",
    //     onChipRamSize = 2 kB
    //   ))
    // )
  }
}

object MuraxWithRamInitWithNativeJtag{
  def main(args: Array[String]) {
    val coreFrequency = if (args.nonEmpty) HertzNumber(BigDecimal(args(0))) else MuraxConfig.default.coreFrequency
    val (scaledValue, unit) = coreFrequency.decompose
    println(s"coreFrequency = $scaledValue $unit")
    SpinalVerilog(Murax(MuraxConfig.default.copy(coreFrequency=coreFrequency, withNativeJtag = true, onChipRamSize = 4 kB, onChipRamHexFile = "src/main/ressource/hex/muraxDemo.hex")))
  }
}

object Murax_arty{
  def main(args: Array[String]) {
    val hex = "src/main/c/murax/hello_world/build/hello_world.hex"
    SpinalVerilog(Murax(MuraxConfig.default(false).copy(coreFrequency = 100 MHz,onChipRamSize = 32 kB, onChipRamHexFile = hex)))
  }
}

object MuraxAsicBlackBox extends App{
  println("Warning this soc do not has any rom to boot on.")
  val config = SpinalConfig()
  config.addStandardMemBlackboxing(blackboxAll)
  config.generateVerilog(Murax(MuraxConfig.default()))
}
