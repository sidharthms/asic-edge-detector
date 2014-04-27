// $Id: $
// File name:   bus_iface
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// $Id: $
// File name:   bus_iface
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Bus Interface - read data from AHB BUS

parameter BUSWIDTH = 32;

module initializer
(
    	input wire ahb_hclk, //bus clock
   	input wire [1:0] ahb_htrans, //transfer kind
	input wire [2:0] ahb_hburst, //burst kind
	input wire ahb_hwrite, //transfer direction
	input wire ahb_hprot, //protection control
	input wire [BUSWIDTH-1:0] ahb_haddr, //address bus
	input wire [BUSWIDTH-1:0] ahb_hwdata, //write data bus
	input wire [BUSWIDTH-1:0] ahb_hrdata, //read data bus
	input wire ahb_hgrant, //bus grant
	output wire ahb_hready, //slave is ready
	input wire ahb_hlock, //locked transfer request
	input wire ahb_hbusreq, //bus request
	output wire ahb_hresp //transfer response
);

   typedef enum     {IDLE, READ_DIM, READ_ADDR1, READ_ADD2, READ_FILTER, KICKSTART} state_type;
   state_type state, next_state;
   
   reg width;
   reg height;
   reg readStartAddress;
   reg writeStartAddress;
   reg filterType;
   
    /*flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(clear),
      .count_enable(unit_final),
      .rollover_val(15),
      .count_out(index),
      .rollover_flag(on_last));*/
   always @
 
   end 
endmodule
