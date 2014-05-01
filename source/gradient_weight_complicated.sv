// $Id: $
// File name:   gradient_weight.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module gradient_weight
#(
	parameter BITS = 8
)
(
  input  wire clk;
  input  wire n_rst;
  input  wire en;
	input  wire signed [2:0][BITS-1:0] in_pixels,
	output wire signed [BITS-1:0] out_pixel,
  output wire final_stage
);
  
  typedef enum { PHASE1, PHASE2 } state_type;
  state_type state, next_state;

  reg  [BITS-1:0] addend1;
  reg  [BITS-1:0] addend2;
  wire [BITS-1:0] sum;

  reg [BITS-1:0] temp;

  assign final_stage = state == PHASE2;
  assign out_pixel = sum;

  adder_2 #(.BITS(BITS)) adder(
    .addend1(addend1),
    .addend2(addend2),
    .sum(sum));

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
      state <= PHASE1;
    else
    begin
      state <= next_state;

      if (state == PHASE1)
        temp <= sum;
    end
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
        next_state = PHASE1;
    endcase
  end

  always @ (*)
  begin
    case (state)
      PHASE1:
      begin
        addend1 = in_pixels[0];
        addend2 = in_pixels[1] <<< 1;   // Signed shift.
      end
      PHASE2:
      begin
        addend1 = temp;
        addend2 = in_pixels[2];
      end
    endcase
  end
endmodule
