// $Id: $
// File name:   gradient_weight.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module gradient_weight
#(
	parameter BITS = 8
)
(
	input  wire signed [2:0][BITS-1:0] in_pixels,
	output wire signed [BITS-1:0] out_pixel,
);
  assign out_pixel = in_pixels[0] + 2*in_pixels[1] + in_pixels[2];
endmodule
