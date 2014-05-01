onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_pixelcontroller/tb_clk
add wave -noupdate /tb_pixelcontroller/tb_rst
add wave -noupdate -expand -group Important /tb_pixelcontroller/read_enable
add wave -noupdate -expand -group Important /tb_pixelcontroller/PIXCON/read_now
add wave -noupdate -expand -group Important /tb_pixelcontroller/PIXCON/write_now
add wave -noupdate -expand -group Important -radix hexadecimal /tb_pixelcontroller/address
add wave -noupdate -expand -group Important -radix hexadecimal /tb_pixelcontroller/w_data
add wave -noupdate -expand -group Important -radix hexadecimal /tb_pixelcontroller/r_data
add wave -noupdate -expand -group Important -radix hexadecimal /tb_pixelcontroller/bidata
add wave -noupdate -expand -group Important /tb_pixelcontroller/PIXCON/state
add wave -noupdate -expand -group Important /tb_pixelcontroller/PIXCON/total_read
add wave -noupdate /tb_pixelcontroller/AHB_HCLK
add wave -noupdate /tb_pixelcontroller/init_file_number
add wave -noupdate /tb_pixelcontroller/dump_file_number
add wave -noupdate /tb_pixelcontroller/mem_clr
add wave -noupdate /tb_pixelcontroller/mem_init
add wave -noupdate /tb_pixelcontroller/mem_dump
add wave -noupdate /tb_pixelcontroller/verbose
add wave -noupdate /tb_pixelcontroller/start_address
add wave -noupdate /tb_pixelcontroller/last_address
add wave -noupdate /tb_pixelcontroller/sread_enable
add wave -noupdate /tb_pixelcontroller/pread_enable
add wave -noupdate /tb_pixelcontroller/write_enable
add wave -noupdate /tb_pixelcontroller/swrite_enable
add wave -noupdate /tb_pixelcontroller/pwrite_enable
add wave -noupdate /tb_pixelcontroller/paddress
add wave -noupdate /tb_pixelcontroller/saddress
add wave -noupdate /tb_pixelcontroller/tb_address
add wave -noupdate /tb_pixelcontroller/sw_data
add wave -noupdate /tb_pixelcontroller/pw_data
add wave -noupdate /tb_pixelcontroller/tb_w_data
add wave -noupdate /tb_pixelcontroller/tb_r_data
add wave -noupdate /tb_pixelcontroller/tb_start
add wave -noupdate /tb_pixelcontroller/io_done
add wave -noupdate /tb_pixelcontroller/tb_writemode
add wave -noupdate /tb_pixelcontroller/global_setup
add wave -noupdate /tb_pixelcontroller/fd
add wave -noupdate /tb_pixelcontroller/read_in
add wave -noupdate /tb_pixelcontroller/count
add wave -noupdate /tb_pixelcontroller/code
add wave -noupdate /tb_pixelcontroller/current_addr
add wave -noupdate /tb_pixelcontroller/tbp_enable
add wave -noupdate /tb_pixelcontroller/tbp_data_out
add wave -noupdate /tb_pixelcontroller/tbp_data_in
add wave -noupdate /tb_pixelcontroller/tbp_address_write_offset
add wave -noupdate /tb_pixelcontroller/tbp_address_read_offset
add wave -noupdate /tb_pixelcontroller/tbp_num_pix_read
add wave -noupdate /tb_pixelcontroller/tbp_num_pix_write
add wave -noupdate /tb_pixelcontroller/tbp_n_rst
add wave -noupdate /tb_pixelcontroller/tbp_read_now
add wave -noupdate /tb_pixelcontroller/in_file
add wave -noupdate /tb_pixelcontroller/out_file
add wave -noupdate /tb_pixelcontroller/i
add wave -noupdate /tb_pixelcontroller/J
add wave -noupdate /tb_pixelcontroller/r
add wave -noupdate /tb_pixelcontroller/PIXCON/address_write_offset
add wave -noupdate /tb_pixelcontroller/PIXCON/address_read_offset
add wave -noupdate /tb_pixelcontroller/PIXCON/num_pix_read
add wave -noupdate /tb_pixelcontroller/PIXCON/num_pix_write
add wave -noupdate /tb_pixelcontroller/PIXCON/address
add wave -noupdate /tb_pixelcontroller/PIXCON/w_data
add wave -noupdate /tb_pixelcontroller/PIXCON/r_data
add wave -noupdate /tb_pixelcontroller/PIXCON/clk
add wave -noupdate /tb_pixelcontroller/PIXCON/enable
add wave -noupdate /tb_pixelcontroller/PIXCON/read_enable
add wave -noupdate /tb_pixelcontroller/PIXCON/write_enable
add wave -noupdate /tb_pixelcontroller/PIXCON/Rtim_en
add wave -noupdate /tb_pixelcontroller/PIXCON/Wtim_clear
add wave -noupdate /tb_pixelcontroller/PIXCON/Wtim_en
add wave -noupdate /tb_pixelcontroller/PIXCON/next_state
add wave -noupdate /tb_pixelcontroller/PIXCON/total_written
add wave -noupdate /tb_pixelcontroller/PIXCON/SYNOPSYS_UNCONNECTED__0
add wave -noupdate /tb_pixelcontroller/PIXCON/SYNOPSYS_UNCONNECTED__1
add wave -noupdate /tb_pixelcontroller/PIXCON/SYNOPSYS_UNCONNECTED__2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {284484 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 327
configure wave -valuecolwidth 236
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {511744 ps}
