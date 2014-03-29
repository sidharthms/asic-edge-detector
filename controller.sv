// $Id: mg79$
// File name:   controller.sv
// Created:     3/17/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Main Controller

module controller
(
	input wire clk,
	input wire n_rst,
	input wire en_filter_phase,		// Start the filtering phase.
	input wire read_done,			// Pixel block read complete.
	input wire all_read,			// All pixels have been processed, only need to output last pixel.
	input wire filter_done,			// Filtering operation complete.
	input wire send_done,			// Transmission of last filtered pixel complete.
	output reg en_read,				// Start reading the next pixel block.
	output reg en_filter,			// Start filter for current pixel.
	output reg en_send,				// Start sending previous filtered pixel.
	output reg filter_phase_done	// Filter phase completed for all pixels.
);

	typedef enum {IDLE, START_READ, READING, START_FILTER_N_SEND, FILTERING_N_SENDING, DONE} state_type;
	state_type state, next_state;
	
	reg next_en_filter;
	reg next_en_send;
	reg next_en_read;
	reg next_filter_phase_done;
	
	// Don't enable filter if all pixels are already processed. Only send previous result.
	assign next_en_filter = (next_state == START_FILTER_N_SEND) && read_done && ~all_read;
	
	assign next_en_read = next_state == START_READ;
	assign next_en_send = next_state == START_FILTER_N_SEND;
	assign next_filter_phase_done = next_state == DONE;
	
	always @ (posedge clk, negedge n_rst)
	begin
		if (n_rst == 1'b0)
		begin
			state <= IDLE;
			en_read <= 1'b0;
			en_filter <= 1'b0;
			en_send <= 1'b0;
			filter_phase_done <= 1'b0;
		end
		else 
		begin
			state <= next_state;
			en_read <= next_en_read;
			en_filter <= next_en_filter;
			en_send <= next_en_send;
			filter_phase_done <= next_filter_phase_done;
		end
	end
	
	always @ (state, en_filter_phase, read_done, all_read, filter_done, send_done)
	begin
		next_state = IDLE;
		case (state)
			IDLE:
			begin
				if (en_filter_phase)
					next_state = START_READ;
				else
					next_state = IDLE;
			end
			START_READ:
				next_state = READING;
			READING:
			begin
				if (read_done || all_read)
					next_state = START_FILTER_N_SEND;
				else
					next_state = READING;
			end
			START_FILTER_N_SEND:
				next_state = FILTERING_N_SENDING;
			FILTERING_N_SENDING:
				if (send_done && all_read)
					next_state = DONE;
				else if (send_done && (~all_read && filter_done))
					next_state = START_READ;
				else
					next_state = FILTERING_N_SENDING;
			DONE:
				next_state = IDLE;
		endcase
	end
endmodule
