// $Id: $
// File name:   sram_iface.sv
// Created:     4/27/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Does the talking to SRAM

localparam W_ADDR_SIZE_BITS = 16;
localparam W_DATA_SIZE_WORDS = 3;
localparam W_WORD_SIZE_BYTES = 1;
localparam DATA_BUS_FLOAT = 32'hz;

module sram_iface
(
	//Internal signals
	input wire clk,
	input wire rst,
	input wire start,
	input wire writemode, //0 read, 1 write
	input wire [0:W_ADDR_SIZE_BITS - 1] i_address,
	input reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] i_w_data,
	output wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] i_r_data,
	output reg io_done,
	//SRAM block output (connects to SRAM ports)
	output wire read_enable,
	output wire write_enable,
	output wire [0:W_ADDR_SIZE_BITS - 1] address,
	output wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data,
	input wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data
);

typedef enum {IDLE,IO} state_type;
state_type state, next_state;

always @ (posedge clk, negedge rst)
begin
	if(1'b0 == rst) begin
		state <= IDLE;
		//state <= next_state;
	end else begin
		state <= next_state;
	end
end


/* TIMER SIGNALS */

reg tim_rst;
reg tim_clear;
reg tim_en;
reg [3:0] index;
reg tim_done;

flex_counter #(.NUM_CNT_BITS(4)) timer(
      .clk(clk),
      .n_rst(tim_rst),
      .clear(tim_clear),
      .count_enable(tim_en),
      .rollover_val(4'b1100),
      .count_out(index),
      .rollover_flag(tim_done));

assign write_enable = writemode;
assign read_enable = ~writemode;
/*
always @ (posedge clk, negedge n_rst)
begin
	if(n_rst == 1'b1) begin
		state <= next_state;
	end else if (n_rst == 1'b0) begin
		state <= IDLE;
 	end
end
*/
assign address = i_address; //redirection
assign w_data = i_w_data;   //redirection
assign i_r_data = r_data;   //redirection

always_comb
begin
	tim_clear = 1'b0;
	io_done = 1'b0;
	tim_rst = 1'b1;
	if(state == IDLE) begin
		next_state = IDLE;
		tim_en = 1'b0;
		//wait for start to be strobed
		if(start == 1'b1) begin
			next_state = IO;
			//Begin timer
			tim_clear = 1'b1;
			tim_en = 1'b1; 
		end
			
	end else if(state == IO) begin
		next_state = IO;
		if(tim_done == 1'b1) begin
			tim_rst = 1'b0;
			io_done = 1'b1;
			next_state = IDLE;
		end
	end
end

endmodule
