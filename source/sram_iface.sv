// $Id: $
// File name:   sram_iface.sv
// Created:     4/27/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Does the talking to SRAM

localparam W_ADDR_SIZE_BITS = 16;
localparam W_DATA_SIZE_WORDS = 1;
localparam W_WORD_SIZE_BYTES = 1;
localparam DATA_BUS_FLOAT = 16'hz;

module sram_iface
(
	//Internal signals
	input wire clk,
	input wire n_rst,
	input wire start,
	input wire writemode, //0 read, 1 write
	input wire [0:W_ADDR_SIZE_BITS - 1] i_address,
	input reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] i_w_data,
	output wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] i_r_data,
	output reg io_done,
	//SRAM block output (connects to SRAM ports)
	output reg read_enable,
	output reg write_enable,
	output wire [0:W_ADDR_SIZE_BITS - 1] address,
	output wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data,
	input wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data
);

typedef enum {IDLE, SETUP, WRITE, READ} state_type;
state_type state, next_state;

/* TIMER SIGNALS */

reg tim_rst;
reg tim_clear;
reg tim_en;
reg index;
reg tim_done;

flex_counter #(.NUM_CNT_BITS(2)) timer(
      .clk(clk),
      .n_rst(tim_rst),
      .clear(tim_clear),
      .count_enable(tim_en),
      .rollover_val(3),
      .count_out(index),
      .rollover_flag(tim_done));


always @ (posedge clk, negedge n_rst)
begin
	if(n_rst == 1'b1) begin
		state = next_state;
	end else if (n_rst == 1'b0) begin
		state = IDLE;
	end
end

assign address = i_address;
assign w_data = i_w_data;
assign i_r_data = r_data;

always_comb
begin
	next_state = IDLE;
	read_enable = 1'b0;
	write_enable = 1'b0;
	tim_clear = 1'b1;
	tim_en = 1'b0;

	if(state == IDLE) begin
		//wait for start to be strobed
		if(start == 1'b1 && writemode == 1'b1) begin
			next_state = WRITE;
		end else if (start == 1'b1 && writemode == 1'b0) begin
			next_state = READ;
		end
		if(next_state != IDLE) begin
			tim_clear = 1'b0;
			tim_en = 1'b1;
		end	
	end else if(state == WRITE) begin
		write_enable <= 1'b1;
		if(tim_done == 1'b1) begin
			io_done = 1'b1;
		end
	end else if(state == READ) begin
		read_enable <= 1'b1;
		if(tim_done == 1'b1) begin
			io_done = 1'b1;
		end
	end
end

endmodule
