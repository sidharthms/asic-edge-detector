// $Id: $
// File name:   hysteresis_one.sv
// Created:     4/30/2014
// Author:      Ryan Beasley, Sidharth Mudgal

module hyst
#(
	parameter BITS = 8,
  parameter LOW_THRESH = 70,
  parameter HIGH_THRESH = 140
)
(
	input  wire [1:0] in_angle,
  input  wire [4:0][7:0] in_mag,
	output reg  [7:0] out_pixel
);
  reg [1:0][7:0] mag_pair;

  always @ (*)
  begin
    if ((in_mag[in_angle] >= HIGH_THRESH && in_mag[4] >= LOW_THRESH) ||
        (in_mag[4] >= HIGH_THRESH))
    begin
        out_pixel = 255;
    end
    else 
      out_pixel = 0;
  end
endmodule
