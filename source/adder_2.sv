// $Id: $
// File name:   adder_2.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module adder_2
#(
	parameter BITS = 8
)
(
	input  wire [BITS-1:0] addend1,
	input  wire [BITS-1:0] addend2,
	output wire [BITS-1:0] sum
);
  assign sum = addend1 + addend2; 
endmodule
