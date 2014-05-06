// $Id: $
// File name:   gradient_mag_angle.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module gradient_mag_angle
#(
	parameter BITS = 9,
  parameter PRECISION = 8
)
(
	input  wire signed [BITS-1:0] in_x,
	input  wire signed [BITS-1:0] in_y,
	output reg [1:0] out_angle,
	output reg [PRECISION-1:0] out_mag
);
  wire [BITS-1:0] unsigned_x;
  wire [BITS-1:0] unsigned_y;

  // 2 extra bits for intermediate arithmetic to not overflow.
  wire [PRECISION+1:0] g_y;
  wire [PRECISION+1:0] g_x;
  wire [PRECISION+1:0] sum;

  wire is_negative;

  assign is_negative = in_x[BITS-1] || in_y[BITS-1];

  assign unsigned_x = in_x < 0 ? in_x * (-1) : in_x;
  assign unsigned_y = in_y < 0 ? in_y * (-1) : in_y;

  assign g_y = { 2'd0, unsigned_y[BITS-2 : (BITS-1)-PRECISION] };
  assign g_x = { 2'd0, unsigned_x[BITS-2 : (BITS-1)-PRECISION] };

  assign sum = (g_y + g_x) >> 1;
  assign out_mag = sum[PRECISION-1:0];

  always @ (*)
  begin
    if ( ((g_y << 1) + (g_y >> 1)) <= g_x )
      out_angle = 0;
    else if ( g_y <= (g_x << 1) + (g_x >> 1) )
    begin
      if (is_negative)
        out_angle = 3;
      else out_angle = 1;
    end
    else
      out_angle = 2;
  end
endmodule
