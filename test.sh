#/bin/bash
#
vcom source/off_chip_sram_wrapper.vhd;
vlog source/tb_ARM.sv;
#vlog source/sram_iface.sv;
vsim work.tb_ARM;

