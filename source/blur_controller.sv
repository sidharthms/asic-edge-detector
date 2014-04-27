// $Id: $
// File name:   blur_controller.sv
// Created:     4/22/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Filter Controller

module blur_controller
(
  input  wire clk,
  input  wire n_rst,
  input  wire anchor_moving,         // Start filtering when anchor moves.
  input  wire [31:0] anchor_x;
  input  wire [31:0] anchor_y;
  input  wire type,                  // Type of filtering to apply.

  input  wire [7:0] blur_in [20];
  output wire [7:0] blur_out [16];
  output reg blur_final;             // Filter phase completed for all pixels.
);
  
  wire anchor_on_first_row;

  reg  [7:0] blur_data [5][16];
  reg  [7:0] blur_data_new [20];
  wire [2:0] first_row;
  wire [2:0] stale_row;
  wire move_first_row;

  typedef enum {IDLE, COPY, PROCESS, FINAL} state_type;
  state_type state, next_state;

  wire clear;
  wire [3:0] index;
  wire on_last;
  reg stage;

  wire unit_en;
  wire [7:0] in_pixels [5];
  wire [7:0] out_pixel;
  wire unit_final;

  assign anchor_on_first_row = anchor_y == 0;
  assign clear = next_state == IDLE;
  assign unit_en = next_state == PROCESSING;
  assign move_first_row = state == PROCESSING && next_state == COPY;

  flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(clear),
      .count_enable(unit_final),
      .rollover_val(15),
      .count_out(index),
      .rollover_flag(on_last));

  flex_counter #(.NUM_CNT_BITS(3)) first_col_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(0),
      .count_enable(move_first_row),
      .rollover_val(4),
      .count_out(first_row),
      .rollover_flag());

  blur filter(
      .en(unit_en),
      .in_pixels(in_pixels),
      .out_pixel(out_pixel),
      .final(unit_final));

  row_shift #(
      .BITS(8),
      .WIDTH(5),
      .SHIFT_BITS(3))
    data_shift(
      .rows(blur_data[index]),
      .shift(first_row),
      .shifted_rows(shifted_blur_data));

  cyclic_adder #(.BITS(3)) subtract_one(
      .left(first_row),
      .right(1),
      .subtract(1),
      .limit(5),
      .result(stale_row));

  assign blur_final = stage == 1 && on_last;

  integer i;
  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
      state <= IDLE;
    else
      state <= next_state;

    if (next_state == COPY)
      stage <= 0;
    else if (on_last)
      stage <= 1;

    // Copy in fresh data at the beginning.
    if (next_state == COPY)
      blur_data_new <= blur_in;

    // Perform X blur along fresh data in stage 0 and Y blur along cached rows
    // in stage 1.
    if (stage == 0)

      // If on the first row initialize row cache to results of first row to
      // prevent "glow" around image edge.
      if (anchor_on_first_row)
      begin
        for (i = 0; i < 5; ++i)
          blur_data[index][i] <= out_pixel;
      end
      else
        blur_data[index][stale_row] <= out_pixel;
    else
      blur_out[index] <= out_pixel;
  end

  always @ (state, anchor_moving, blur_final)
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
        if (blur_final)
        begin
          if (anchor_moving)
            next_state = COPY;
          else
            next_state = IDLE;
        end
        else
          next_state = PROCESSING;
      end
    end
  end

  always @ (stage, index)
  begin
    if (stage == 0)
      in_pixels = blur_data_new[index +: 5];
    else
      in_pixels = shifted_blur_data;
  end
endmodule
