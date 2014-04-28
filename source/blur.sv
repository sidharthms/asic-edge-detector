// $Id: $
// File name:   blur.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module blur
(
  input wire clk,
  input wire n_rst,
	input wire en,
	input wire [4:0][7:0] in_pixels,
	output reg [7:0] out_pixel,
	output wire final_stage
);
  typedef enum {PHASE1, PHASE2, PHASE3} state_type;
  state_type state, next_state;

  reg [12:0] addend1;
  reg [12:0] addend2;
  reg [12:0] addend3;
  wire [12:0] sum;

  reg [12:0] temp1;
  reg [12:0] temp2;

  assign final_stage = state == PHASE3;
  assign out_pixel = sum[7:0];

  adder_3 #(.BITS(13)) adder(
    .addend1(addend1),
    .addend2(addend2),
    .addend3(addend3),
    .sum(sum));

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
      state <= PHASE1;
    else
      state <= next_state;

    if (state == PHASE1)
      temp1 <= sum;
    if (state == PHASE2)
      temp2 <= sum;
  end

  always @ (*)
  begin
    case (state)
      PHASE1:
      begin
        if (en)
          next_state = PHASE2;
        else
          next_state = PHASE1;
      end
      PHASE2:
        next_state = PHASE3;
      PHASE3:
        next_state = PHASE1;
    endcase
  end

  always @ (*)
  begin
    case (state)
      PHASE1:
      begin
        addend1 = { 5'd0, in_pixels[0] };
        addend2 = { 3'd0, in_pixels[1], 2'd0 }; // << 2
        addend3 = { 2'd0, in_pixels[2], 3'd0 }; // << 3
      end
      PHASE2:
      begin
        addend1 = temp1;
        addend2 = { 3'd0, in_pixels[3], 2'd0 }; // << 2
        addend3 = { 5'd0, in_pixels[4] };
      end
      PHASE3:
      begin
        addend1 = temp2 >> 5;
        addend2 = temp2 >> 6;
        addend3 = temp2 >> 7;
      end
    endcase
  end
endmodule
