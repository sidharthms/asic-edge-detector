#/bin/bash
#
vcom source/off_chip_sram_wrapper.vhd;
vlog source/tb_ARM.sv;
vsim work.tb_ARM;
#This is a test

