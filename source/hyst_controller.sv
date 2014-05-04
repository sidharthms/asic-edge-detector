// $Id: $
// File name:   hyst_controller.sv
// Created:     5/1/2014
// Author:      Akanksha Sharma, Sidharth Mudgal

module hyst_controller
(
  input  wire clk,
  input  wire n_rst,
  input  wire anchor_moving,         // Start filtering when anchor moves.

  input  wire [11:0][1:0] gradient_angle,
  input  wire [11:0][7:0] hyst_in,
  output reg  [9:0][7:0] hyst_out,
  output reg  hyst_final               // Filter phase completed for all pixels.
);
  
  reg  [11:0][1:0] grad_angle_data;
  reg  [1:0][11:0][7:0] nms_data;
  reg  [9:0][7:0] hyst_previous;

  typedef enum {IDLE, COPY, PROCESSING, COPY_RESULT} state_type;
  state_type state, next_state;

  wire index_clear;
  wire index_en;
  wire [3:0] index;

  reg  [1:0] in_angle;
  reg  [4:0][7:0] in_mag;
  wire [7:0] out_pixel;

  assign index_clear = next_state != PROCESSING;
  assign index_en = state == PROCESSING;

  // Hyst filter should be enabled only when all inputs are stable.

  flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(index_clear),
      .count_enable(index_en),
      .rollover_val(4'd9),
      .count_out(index));

  hyst filter(
      .in_angle(in_angle),
      .in_mag(in_mag),
      .out_pixel(out_pixel));

  assign hyst_final = state == COPY_RESULT || state == IDLE;

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
      state <= IDLE;
    else
    begin
      state <= next_state;

      // Copy in fresh data at the beginning.
      if (state == COPY)
      begin
        grad_angle_data <= gradient_angle;
        nms_data[0] <= hyst_in;
        nms_data[1] <= nms_data[0];
      end

      // Copy result for next stage.
      if (state == COPY_RESULT)
        hyst_previous <= hyst_out;
      if (index_en)
        hyst_out[index] <= out_pixel;
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
        if (index == 9)
          next_state = COPY_RESULT;
        else
          next_state = PROCESSING;
      end
      COPY_RESULT:
      begin
        if (anchor_moving)
          next_state = COPY;
        else
          next_state = IDLE;
      end
    endcase
  end

  always @ (*)
  begin
    in_angle = grad_angle_data[index];
    in_mag[4] = nms_data[0][index+1];

    if (index == 0)
    begin
      in_mag[0] = nms_data[0][0];
      in_mag[3] = nms_data[1][0];
    end
    else
    begin
      in_mag[0] = hyst_out[index-1];
      in_mag[3] = hyst_previous[index-1];
    end

    in_mag[2] = hyst_previous[index];

    if (index == 9)
      in_mag[1] = nms_data[1][11];
    else
      in_mag[1] = hyst_previous[index+1];
  end
endmodule
