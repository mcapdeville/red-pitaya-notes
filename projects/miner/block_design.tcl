# Create clk_wiz
cell xilinx.com:ip:clk_wiz:5.4 pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 125.0
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7:5.5 ps_0 {
  PCW_IMPORT_BOARD_PRESET data/red_pitaya.xml
} {
	M_AXI_GP0_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0 {} {
  ext_reset_in const_0/dout
}

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 WriteReg {
  CFG_DATA_WIDTH 384
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins WriteReg/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_WriteReg_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_WriteReg_reg0]

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 State {
  DIN_WIDTH 384 DIN_FROM 255 DIN_TO 0 DOUT_WIDTH 256
} {
  Din WriteReg/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 Data {
  DIN_WIDTH 384 DIN_FROM 351 DIN_TO 256 DOUT_WIDTH 96
} {
  Din WriteReg/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 Control {
  DIN_WIDTH 384 DIN_FROM 352 DIN_TO 352 DOUT_WIDTH 1
} {
  Din WriteReg/cfg_data
}

cell mcapdeville:user:miner_sha256:1.0 Miner {
 DEPTH 2
} {
 clk pll_0/clk_out1
 data  Data/Dout
 state State/Dout
 stop Control/Dout
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 Status {
  NUM_PORTS 4
  IN0_WIDTH 32
  IN1_WIDTH 1
  IN2_WIDTH 1
  IN3_WIDTH 30
} {
  In0 Miner/result
  In1 Miner/running
  In2 Miner/found
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register:1.0 ReadReg {
  STS_DATA_WIDTH 64
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
	sts_data Status/Dout
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins ReadReg/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_ReadReg_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_ReadReg_reg0]

