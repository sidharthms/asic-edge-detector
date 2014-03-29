// $Id: $
// File name:   phase_controller.sv
// Created:     3/18/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Filter Phase Controller

module phase_controller
(
	input wire clk,
	input wire n_rst,
	input wire en_process,				// Start the filtering process.
	input wire [1:0] filter_type,		// Filter to apply.
	input wire filter_phase_done,		// Current filter phase completed for all pixels.
	input wire [31:0] source_address,	// Address of source image.
	input wire [31:0] final_address,	// Address of final filtered image output.
	input wire [31:0] temp_address,		// Address to store temporary image.
	output reg en_filter_phase,			// Start the current filtering phase.
	output reg [1:0] system_filter,		// System filter to apply for current filter phase.
	output reg [31:0] input_address,	// Current input start address.
	output reg [31:0] output_address,	// Current output start address.
	output reg process_done				// Filtering complete.
);

	wire [1:0] cur_phase, last_phase;
	flex_counter phase_counter (.clk(clk), 
								.n_rst(n_rst), 
								.clear(en_process), 
								.count_enable(changing_phase), 
								.rollover_val(2'd4), 
								.count_out(cur_phase),
								.rollover_flag(packet_done));
								
	parameter [1:0] FILTER_GAUSSIAN = 2'd0,
					FILTER_CANNY = 2'd1;
					
	parameter [1:0] SYS_FILTER_GAUSSIAN = 2'd0,
					SYS_FILTER_CANNY = 2'd1;

	typedef enum {IDLE, START_FILTER, FILTERING, PHASE_DONE, DONE} state_type;
	state_type state, next_state;
	
	reg next_en_filter_phase;
	reg next_process_done;
	
	assign next_en_filter_phase = next_state == START_FILTERING;
	assign next_process_done = next_state == DONE;
	
	assign changing_phase = next_state == START_FILTERING && state == PHASE_DONE;
	
	always @ (posedge clk, negedge n_rst)
	begin
		if (n_rst == 1'b0)
		begin
			state <= IDLE;
			en_filter_phase <= 1'b0;
			process_done <= 1'b0;
		end
		else 
		begin
			state <= next_state;
			en_filter_phase <= next_en_filter_phase;
			process_done <= next_process_done;
		end
	end
	
	// Set system_filter, input_address and output_address
	// based on current phase. These will be stable by the 
	// start of the FILTERING state.
	always @ (filter_type, cur_phase)
	begin
		system_filter = SYS_FILTER_GAUSSIAN;
		input_address = source_address;
		output_address = final_address;
		case (filter_type)
			FILTER_GAUSSIAN:
				last_phase = 2'd0;
				case (cur_phase)
					2'd0:
						system_filter = SYS_FILTER_GAUSSIAN;
				endcase
			FILTER_CANNY:
				last_phase = 2'd1;
				case (cur_phase)
					2'd0:
						system_filter = SYS_FILTER_GAUSSIAN;
						input_address = source_address;
						output_address = temp_address;
					2'd1:
						system_filter = SYS_FILTER_CANNY_EDGE;
						input_address = temp_address;
						output_address = final_address;
				endcase
			default:
				last_phase = 2'd0;
		endcase
	end
	
	always @ (state, en_process, filter_phase_done, cur_phase, last_phase)
	begin
		next_state = IDLE;
		case (state)
			IDLE:
			begin
				if (en_process)
					next_state = START_FILTER;
				else
					next_state = IDLE;
			end
			START_FILTER:
				next_state = FILTERING;
			FILTERING:
				if (filter_phase_done)
					next_state = PHASE_DONE;
				else
					next_state = FILTERING;
			PHASE_DONE:
				if (cur_phase != last_phase)
					next_state = START_FILTERING;
				else
					next_state = DONE;
			DONE:
				next_state = IDLE;
		endcase
	end
endmodule
