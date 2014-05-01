// $Id: $
// File name:   pixelcontroller.sv
// Created:     4/28/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Obtains bunch of pixels or write bunch of pixels based on requested address offset and number of pixel wanted
//	        and also greyscalify each pixel

module pixelcontroller
#(
	parameter W_ADDR_SIZE_BITS = 16,
	parameter W_DATA_SIZE_WORDS = 3,
	parameter W_WORD_SIZE_BYTES = 1,
	parameter DATA_BUS_FLOAT = 24'hz,
	parameter BIT_PER_PIXEL = 8
)
(
	input wire clk,
	input wire enable,
	output reg [19:0][BIT_PER_PIXEL - 1:0] data_out,           //requested pixels from SRAM
	input reg [19:0][BIT_PER_PIXEL - 1:0] data_in,		   //requested pixels to be written to SRAM
	input wire [W_ADDR_SIZE_BITS - 1:0] address_write_offset,  //starting at what address do we start writing to
	input wire [W_ADDR_SIZE_BITS - 1:0] address_read_offset, //starting at what address do we start reading from
	input wire [24:0] num_pix_read,		   //how many pixels do we need to read
	input wire [24:0] num_pix_write,		   //how many pixels do we need to write
	input wire n_rst,
	output wire read_now,        //flag that pixel data must be read now
	//SRAM Controls
	output reg [W_ADDR_SIZE_BITS - 1:0] address,
	output reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data,
	input wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data,
	output reg read_enable,
	output reg write_enable
);

typedef enum bit[1:0] {IDLE, WRITE_OP, READ_OP, DONE} state_type;
state_type state, next_state;


/* GLOBAL COUNTS */

reg [4:0] total_read, next_total_read;
reg [4:0] total_written;

/* READ TIMER SIGNALS */
reg [W_ADDR_SIZE_BITS - 1:0] next_address;
reg Rtim_rst, Wtim_rst;
reg Rtim_clear, Wtim_clear;
reg Rtim_en, Wtim_en;
reg [3:0] Rindex;
reg [3:0] Windex;
reg write_now;
/* Temporary Regs */
reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1:0] temp;



always @ (posedge clk, negedge n_rst)
begin
	if(1'b0 == n_rst) begin
		state = IDLE;
		address = 24'hz;
		total_read = 0;
	end else begin
		address = next_address;
		state = next_state;
		total_read = next_total_read;
	end
end
flex_counter #(.NUM_CNT_BITS(4)) Rtimer(
      .clk(clk),
      .n_rst(Rtim_rst),
      .clear(Rtim_clear),
      .count_enable(Rtim_en),
      .rollover_val(4'hF),//supposed to be 12 nano 
      .count_out(Rindex),
      .rollover_flag(read_now),
      .back_to_zero(1'b0));

/* WRITE TIMER SIGNALS goes below */
flex_counter #(.NUM_CNT_BITS(4)) Wtimer(
      .clk(clk),
      .n_rst(Wtim_rst),
      .clear(Wtim_clear),
      .count_enable(Wtim_en),
      .rollover_val(4'hF),//supposed to be 12 nano 
      .count_out(Windex),
      .rollover_flag(write_now),
      .back_to_zero(1'b0));

always_comb
begin
	Rtim_clear = 1'b0;
	Rtim_rst = 1'b1;
	Wtim_rst = 1'b1;
	Wtim_clear = 1'b0;
	next_state = IDLE;
	if(state == IDLE) begin
		next_state = IDLE;
		if(enable == 1'b1) begin
			//If pixelcontroller is enabled proceed to READ stuff 
			Rtim_en = 1'b1;
			Rtim_clear = 1'b1;
			next_state = READ_OP;
			total_written = 0;	
			//write_now = 0;
			read_enable =0;
			write_enable =0;
			next_address = 24'hz;
			Wtim_rst = 0;
			Wtim_rst = 1;
			next_total_read = 0;
			total_written = 0;
		end
	end else if(state == READ_OP) begin
		next_state = READ_OP; //stay in READ_OP unless operation is finished
		if(total_read == num_pix_read) begin
			next_state = WRITE_OP;
			Wtim_en = 1'b1;
			Wtim_clear = 1'b1;
		end	

		write_enable = 1'b0;
		read_enable = 1'b1; //Enable read
		
		if(read_now) begin
	
		
			next_address = address_read_offset + total_read; //Output address wanted
			

			//sum RBG
			temp = ((r_data >> 16) & 24'hFF) + ((r_data >> 8) & 24'hFF) + (r_data & 24'hFF);	
			//store only grayscale equivalent by averaging-ish 
			data_out[total_read] = ((temp >> 2) + (temp >> 4) + (temp >> 6) + (temp >> 8));
			//move on
			next_total_read = total_read + 1;
		end
	end else if(state == WRITE_OP) begin
		next_state = WRITE_OP;
		if(total_written == num_pix_write) begin
			next_state = DONE;
		end
		
		next_address = address_write_offset + total_written; //address wish to write to
	  	write_enable = 1'b1;
		read_enable = 1'b0;
		
		w_data = data_in[total_written ];
		if(write_now) begin
			total_written = total_written + 1;
		end else begin
			//no more write now
			write_enable = 1'b0;
		end

	end else if(state == DONE) begin
		next_state = DONE;
		//Stay here and rot forever
		read_enable = 1'b0;
		write_enable = 1'b0;
		Rtim_en = 1'b0;
		Wtim_en = 1'b0;
	end
end
endmodule
