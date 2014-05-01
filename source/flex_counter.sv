// $Id: $
// File name:   flex_counter.sv
// Created:     2/12/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Flexible counter with controlled rollover

module flex_counter
#(
	parameter NUM_CNT_BITS = 4,
  parameter FIRST_INCREMENT = 1,
  parameter INCREMENT = 1,
  parameter ZERO_RESET = 0
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
  reg [NUM_CNT_BITS:0] next_data;
	reg flag;
	reg next_flag;
  wire [NUM_CNT_BITS-1:0] increment;

  assign increment = data == 0 ? FIRST_INCREMENT : INCREMENT;
	
	always @ (posedge clk, negedge n_rst)
	begin
		if (n_rst == 1'b0)
		begin
			data <= '0;
			flag <= 1'b0;
		end
    else
    begin
      data <= next_data;
      flag <= next_flag;
    end
	end

  always @ (*)
  begin
		if (clear == 1'b1)
		begin
			next_data = '0;
			next_flag = 1'b0;
		end
		else 
    begin
			if (count_enable)
				if (rollover_val == data)
        begin
          if (ZERO_RESET)
            next_data = 0;
          else
            next_data = 1;
        end
				else
          next_data = data + increment;
			else
				next_data = data;
				
			if (next_data + increment - 1 >= rollover_val)
				next_flag = 1'b1;
			else
				next_flag = 1'b0;
		end
  end
	
	assign count_out = data;
	assign rollover_flag = flag;
endmodule
