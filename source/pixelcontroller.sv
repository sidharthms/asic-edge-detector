// $Id: $
// File name:   pixelcontroller.sv
// Created:     4/28/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Obtains bunch of pixels or write bunch of pixels based on requested address offset and number of pixel wanted
//	        and also greyscalify each pixel

localparam W_ADDR_SIZE_BITS = 16;
localparam W_DATA_SIZE_WORDS = 3;
localparam W_WORD_SIZE_BYTES = 1;
localparam DATA_BUS_FLOAT = 24'hz;
localparam BIT_PER_PIXEL = 8;

module pixelcontroller(
	input wire clk,
	input wire enable,
	output reg [19:0][BIT_PER_PIXEL - 1:0] data_out,           //requested pixels from SRAM
	input reg [19:0][BIT_PER_PIXEL - 1:0] data_in,		   //requested pixels to be written to SRAM
	input wire [W_ADDR_SIZE_BITS - 1:0] address_write_offset,  //starting at what address do we start writing to
	input wire [W_ADDR_SIZE_BITS - 1:0] address_read_offset, //starting at what address do we start reading from
	input wire [4:0] num_pix_read,		   //how many pixels do we need to read
	input wire [4:0] num_pix_write,		   //how many pixels do we need to write
	input wire n_rst,
	//SRAM Controls
	output reg [W_ADDR_SIZE_BITS - 1:0] address,
	output reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data,
	input wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data,
	output reg read_enable,
	output reg write_enable
);

typedef enum {IDLE, WRITE_OP, READ_OP} state_type;
state_type state, next_state;

always @ (posedge clk, negedge n_rst)
begin
	if(1'b0 == n_rst) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

/* GLOBAL COUNTS */

reg [4:0] total_read;
reg [4:0] total_write;

/* READ TIMER SIGNALS */

reg Rtim_rst;
reg Rtim_clear;
reg Rtim_en;
reg [3:0] Rindex;
reg Rtim_done;

flex_counter #(.NUM_CNT_BITS(4)) Rtimer(
      .clk(clk),
      .n_rst(Rtim_rst),
      .clear(Rtim_clear),
      .count_enable(Rtim_en),
      .rollover_val(5),//supposed to be 12 nano 
      .count_out(Rindex),
      .rollover_flag(Rtim_done));

/* WRITE TIMER SIGNALS goes below */

always_comb
begin
	Rtim_clear = 1'b0;
	Rtim_rst = 1'b1;
	if(state == IDLE) begin
		next_state = IDLE;
		if(enable == 1'b1) begin
			//If pixelcontroller is enabled proceed to READ stuff 
			Rtim_en = 1'b1;
			Rtim_clear = 1'b1;
			next_state = READ_OP;
			total_read = 0;
			total_write = 0;
		end
	end else if(state == READ_OP) begin
		next_state = READ_OP; //stay in READ_OP unless operation is finished on this pixel
		
		address = address_read_offset + total_read; //Output address wanted
		write_enable = 1'b0;
		read_enable = 1'b1; //Enable read
		
		if(Rtim_done) begin
			total_read = total_read + 1;
		end
	end
end
endmodule
