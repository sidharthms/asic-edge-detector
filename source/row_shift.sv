// $Id: $
// File name:   cyclic_adder.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module cyclic_adder
#(
	parameter BITS = 8
)
(
	input wire [BITS-1:0] left,
	input wire [BITS-1:0] right,
	input wire subtact,
	input wire [BITS-1:0] rollover_val,
	output wire [BITS-1:0] result,
);
  wire [BITS:0] sum;
  wire [BITS:0] corrected_sum;

  assign result = corrected_sum[BITS-1:0];

  always @ (left, right, subtract, rollover_val)
  begin
    if (~subtract)
    begin
      sum = left + right

      // Check for oveflow.
      if (sum[BITS]) 
        corrected_sum = sum - rollover_val;
      else
        corrected_sum = sum;
    end
    else
    begin
      sum = left - right;

      // Check for underflow.
      if (sum[BITS])
        corrected_sum = sum + rollover_val;
      else
        corrected_sum = sum;
    end
  end
endmodule
