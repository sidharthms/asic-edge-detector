// $Id: $
// File name:   flex_counter.sv
// Created:     2/12/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Flexible counter with controlled rollover

module flex_counter
#(
	parameter NUM_CNT_BITS = 4
)
(
	input wire clk,
	input wire n_rst,
	input wire clear,
	input wire count_enable,
	input wire [NUM_CNT_BITS-1:0] rollover_val,
	output reg [NUM_CNT_BITS-1:0] count_out,
	output wire rollover_flag
);
	reg [NUM_CNT_BITS-1:0] data;
	reg flag;
	
	always @ (posedge clk, negedge n_rst)
	begin
		if (n_rst == 1'b0)
		begin
			data <= '0;
			flag <= 1'b0;
		end
		else if (clear == 1'b1)
		begin
			data <= '0;
			flag <= 1'b0;
		end
		else begin
			if (count_enable)
				if (rollover_val == data)
					data <= 1;
				else
					data <= data + 1;
			else
				data <= data;
				
			if ((data == rollover_val - 1) && count_enable)
				flag <= 1'b1;
			else
				flag <= 1'b0;
		end
	end
	
	assign count_out = data;
	assign rollover_flag = flag;
endmodule
