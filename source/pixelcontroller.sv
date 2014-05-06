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
	input wire [24:0] num_pix_read,		 	   //how many pixels do we need to read
	input wire [24:0] num_pix_write,		   //how many pixels do we need to write
	input wire n_rst,
	output wire read_now,        //flag that pixel data must be read now
	output reg end_of_operations,
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
reg postread_now;
/* Temporary Regs */
reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1:0] temp;
//reg end_of_operations;
reg addr_clearW; //Clear address for write op
reg [5:0] ctfill,ctfill_w;

always @ (posedge clk, negedge n_rst)
begin
	if(~n_rst) begin
		state = IDLE;
		address = address_read_offset;
		total_read = 0;
		Rtim_en = 1'b1;	
		Wtim_en = 1'b1;
		ctfill = 0;
		ctfill_w = 0;
	end else begin
		state = next_state;
		if(addr_clearW) begin
			address = address_write_offset;
		end else if(read_now) begin
			//Read now (or write now strobe)
			address = address + 1;
			ctfill = ctfill + 1;
			ctfill_w = ctfill_w + (state == WRITE_OP ? 1 : 0); // we don't want to strobe this unless we are in write mode
		end
	end
end

//Note: Read Timer is actually also for write timer as well as read
flex_counter #(.NUM_CNT_BITS(4)) Rtimer(
      .clk(clk),
      .n_rst(Rtim_rst),
      .clear(Rtim_clear),
      .count_enable(Rtim_en),
      .rollover_val(4'h9),//supposed to be 5+2 nano 
      .count_out(Rindex),
      .rollover_flag(read_now));

/* Post-Read TIMER SIGNALS goes below */
// Let W = PR
flex_counter #(.NUM_CNT_BITS(4)) PRtimer(
      .clk(clk),
      .n_rst(Wtim_rst),
      .clear(Wtim_clear),
      .count_enable(Wtim_en),
      .rollover_val(4'h9),//let PR trigger when ctfill is stable //same rate but later
      .count_out(Windex),
      .rollover_flag(postread_now));


always_comb
begin
	Rtim_clear = 1'b0;
	Rtim_rst = 1'b1;
	Wtim_rst = 1'b1;
	Wtim_clear = 1'b0;
	write_enable = 1'b0;
	read_enable = 1'b0; 	
	next_state = IDLE;
	addr_clearW = 1'b0;
	if(state == IDLE) begin
		
		next_state = READ_OP;
		
		Rtim_clear = 1'b1; //Flush Read Timer  
		Wtim_clear = 1'b1; //Flust Postread timer
		end_of_operations = 1'b0;
	end else if(state == READ_OP) begin
		next_state = READ_OP;
		write_enable = 1'b0;
		read_enable = 1'b1;
	
		temp = ((r_data >> 16) & 24'hFF) + ((r_data >> 8) & 24'hFF) + (r_data & 24'hFF);	
		
		//if(read_now)		
		//store only grayscale equivalent by averaging-ish 
		if(~read_now) begin //Sample our point a bit later
			data_out[ctfill] = ((temp >> 2) + (temp >> 4) + (temp >> 6) + (temp >> 8)); 
		end
		if((address - address_read_offset) == (num_pix_read)) begin
			//if we have had enough of reading operations
			next_state = WRITE_OP; //go to WRITE OP
			//otherwise stay here
			addr_clearW = 1'b1;
		end
	end else if(state == WRITE_OP) begin
		next_state = WRITE_OP;
		write_enable = 1'b1;
		read_enable = 1'b0;
		addr_clearW = 1'b0;
		w_data = data_in[ctfill_w];
		if((address - address_write_offset) == (num_pix_write)) begin
			next_state = DONE;
			write_enable = 1'b0;
			end_of_operations = 1'b1;
		end
	end else if(state == DONE) begin
		//never get out of done state until next operation is manually started via reset
		next_state = DONE;
	end

end

endmodule
