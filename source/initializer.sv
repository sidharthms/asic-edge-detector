// $Id: $
// File name:   initializer
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// $Id: $
// File name:   initializer
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Listens for request on AHB BUS
//		and starts controllers when start sequence is found

parameter BUSWIDTH = 32;

module initializer
(
	input wire n_rst,
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

   typedef enum {IDLE, READ_DIM, READ_ADDR1, READ_ADD2, READ_FILTER, KICKSTART} state_type;
   state_type state, next_state;
   
   reg width;
   reg height;
   reg readStartAddress;
   reg writeStartAddress;
   reg filterType;

   reg flex_clear, flex_en;   
   reg [3:0] flex_out;
   reg flex_done;

    flex_counter #(.NUM_CNT_BITS(4)) cycle_counter(
      .clk(ahb_clk),
      .n_rst(n_rst),
      .clear(flex_clear),
      .count_enable(flex_en),
      .rollover_val(15),
      .count_out(flex_out),
      .rollover_flag(flex_done));
  
   always @ (posedge ahb_hclk, negedge n_rst)
   begin
      if(n_rst == 1'b1) begin
	 state = next_state;
      end else if(n_rst == 1'b0) begin
         state = IDLE;
         //TODO: reset all other signals
      end
   end
 
endmodule
