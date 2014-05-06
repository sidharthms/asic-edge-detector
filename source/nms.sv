// $Id: $
// File name:   nms.sv
// Created:     5/1/2014
// Author:      Sidharth Mudgal, Akansha Sharma

module nms
#(
	parameter BITS = 8
)
(
	input  wire [1:0] in_angle,
  input  wire [8:0][7:0] in_mag,
	output reg [7:0] out_pixel
);
  reg [1:0][7:0] mag_pair;

  always @ (*)
  begin
    mag_pair[0] = in_mag[3-in_angle];
    mag_pair[1] = in_mag[5+in_angle];

    if (mag_pair[0] > in_mag[4] || mag_pair[1] > in_mag[4])
      out_pixel = 0;
    else
      out_pixel = in_mag[4];
  end
endmodule
