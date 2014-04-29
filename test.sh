#/bin/bash
#
make clean;
vcom source/off_chip_sram_wrapper.vhd; #compile VHDL
vlog source/sram_iface.sv; #compile block
vlog source/tb_ARM.sv;
vlog source/pixelcontroller.sv
vsim work.tb_ARM; #simulate block

