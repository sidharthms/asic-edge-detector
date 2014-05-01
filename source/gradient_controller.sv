// $Id: $
// File name:   gradient_controller.sv
// Created:     4/22/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry

module gradient_controller
(
  input  wire clk,
  input  wire n_rst,
  input  wire anchor_moving,         // Start filtering when anchor moves.
  input  wire [31:0] anchor_x,
  input  wire [31:0] anchor_y,

  input  wire [15:0][7:0] gradient_in,
  output reg signed [13:0][1:0] gradient_angle,
  output reg signed [13:0][5:0] gradient_mag,
  output reg gradient_final             // Filter phase completed for all pixels.
);
  
  wire anchor_on_init_pos;

  reg  [2:0][15:0][7:0] gradient_data;

  typedef enum {IDLE, COPY, PROCESSING} state_type;
  state_type state, next_state;

  wire index_clear;
  wire [3:0] index;
  wire [3:0] index_1;
  wire [3:0] index_2;
  wire [3:0] index_3;

  wire unit_en_1;
  wire unit_en_2;
  wire unit_en_3;

  reg  signed [2:0][2:0][10:0] in_pixels_x1;
  reg  signed [2:0][2:0][10:0] in_pixels_y1;
  wire signed [2:0][10:0] out_pixels_x1;
  wire signed [2:0][10:0] out_pixels_y1;

  reg  [2:0][10:0] in_pixels_x2;
  reg  [2:0][10:0] in_pixels_y2;
  wire [10:0] out_pixel_x2;
  wire [10:0] out_pixel_y2;

  wire [1:0] out_angle;
  wire [7:0] out_mag;

  assign anchor_on_init_pos = anchor_x == 1;
  assign index_clear = next_state != PROCESSING;

  assign index_1 = index;
  assign index_2 = index-1;
  assign index_3 = index-2;

  // Filter should be enabled only when all inputs are stable.
  assign unit_en_1 = index != 14 && index != 15 && state == PROCESSING; 
  assign unit_en_2 = index != 0 && index != 15; 
  assign unit_en_2 = index != 0 && index != 1; 

  flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(index_clear),
      .count_enable(unit_final),
      .rollover_val(4'd15),
      .count_out(index));

  generate
    for (genvar i = 0; i < 3; i++)
    begin
      gradient_sub #(.BITS(11)) filter_x1(
          .in_pixels(in_pixels_x1[i]),
          .out_pixel(out_pixels_x1[i]));

      gradient_weight #(.BITS(11)) filter_y1(
          .in_pixels(in_pixels_y1[i]),
          .out_pixel(out_pixels_y1[i]));
    end
  endgenerate

  gradient_weight #(.BITS(11)) filter_x2(
      .in_pixels(in_pixels_x2),
      .out_pixel(out_pixel_x2));

  gradient_sub #(.BITS(11)) filter_y2(
      .in_pixels(in_pixels_y2),
      .out_pixel(out_pixel_y2));

  gradient_angle filter_angle(
      .in_x(in_x),
      .in_y(in_y),
      .out_angle);

  gradient_mag filter_mag(
      .in_x(in_x),
      .in_y(in_y),
      .out_mag);

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
      state <= IDLE;
    else
    begin
      state <= next_state;

      // Copy in fresh data at the beginning.
      if (next_state == COPY)
      begin
        gradient_data[0] <= gradient_in;

        if (!anchor_on_init_pos)
          gradient_data[2:1] <= gradient_data[1:0];
        else
        begin
          gradient_data[1] <= gradient_in;
          gradient_data[2] <= gradient_in;
        end
      end

      if (unit_en_1)
      begin
        in_pixels_x2 <= out_pixels_x1;
        in_pixels_y2 <= out_pixels_y1;
      end

      if (unit_en_2)
      begin
        in_x <= out_pixel_x2;
        in_y <= out_pixel_y2;
      end

      if (unit_en_3)
      begin
        gradient_angle[index_3] <= out_angle;
        gradient_mag[index_3] <= out_mag;
      end
    end
  end

  always @ (*)
  begin
    case (state)
      IDLE:
      begin
        if (anchor_moving)
          next_state = COPY;
        else
          next_state = IDLE;
      end
      COPY:
        next_state = PROCESSING;
      PROCESSING:
      begin
        if (gradient_final)
        begin
          if (anchor_moving)
            next_state = COPY;
          else
            next_state = IDLE;
        end
        else
          next_state = PROCESSING;
      end
    endcase
  end

  always @ (*)
  begin
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++)
      begin
        in_pixels_x1[r][c] = { 3'd0, gradient_data[r][index_1 + c] };
        in_pixels_y1[r][c] = { 3'd0, gradient_data[r][index_1 + c] };
      end
  end
endmodule
