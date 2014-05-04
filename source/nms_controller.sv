// $Id: $
// File name:   nms_controller.sv
// Created:     5/1/2014
// Author:      Akanksha Sharma, Sidharth Mudgal

module nms_controller
(
  input  wire clk,
  input  wire n_rst,
  input  wire anchor_moving,         // Start filtering when anchor moves.

  input  wire [13:0][1:0] gradient_angle,
  input  wire [13:0][7:0] gradient_mag,
  output reg  [11:0][1:0] nms_angle_out,
  output reg  [11:0][7:0] nms_out,
  output reg  nms_final               // Filter phase completed for all pixels.
);
  
  reg  [2:0][13:0][1:0] grad_angle_data;
  reg  [2:0][13:0][7:0] grad_mag_data;

  typedef enum {IDLE, COPY, PROCESSING} state_type;
  state_type state, next_state;

  wire index_clear;
  wire index_en;
  wire [3:0] index;

  reg  [1:0] in_angle;
  reg  [8:0][7:0] in_mag;
  wire [7:0] out_pixel;

  assign index_clear = next_state != PROCESSING;
  assign index_en = state == PROCESSING;

  assign nms_angle_out = grad_angle_data[1][12:1];

  // NMS filter should be enabled only when all inputs are stable.

  flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(index_clear),
      .count_enable(index_en),
      .rollover_val(4'd11),
      .count_out(index));

  nms filter(
      .in_angle(in_angle),
      .in_mag(in_mag),
      .out_pixel(out_pixel));

  assign nms_final = index == 11 || state == IDLE;

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
        grad_angle_data[0] <= gradient_angle;
        grad_mag_data[0] <= gradient_mag;

        grad_angle_data[2:1] <= grad_angle_data[1:0];
        grad_mag_data[2:1] <= grad_mag_data[1:0];
      end

      if (index_en)
        nms_out[index] <= out_pixel;
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
        if (nms_final)
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
    in_angle = grad_angle_data[1][index+1];
    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++)
        in_mag[i*3 + j] = grad_mag_data[2-i][index + j];
  end
endmodule
