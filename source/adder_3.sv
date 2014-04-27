// $Id: $
// File name:   cyclic_adder.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module cyclic_adder
#(
	parameter BITS = 8
)
(
	input wire [BITS-1:0] addend1,
	input wire [BITS-1:0] addend2,
	input wire [BITS-1:0] addend3,
	output wire [BITS-1:0] sum,
);
  sum = addend1 + addend2 + addend3;
endmodule
