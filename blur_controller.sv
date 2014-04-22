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
  output reg filter_final            // Filter phase completed for all pixels.
);

  reg [7:0][5] blur_data [16];
  reg [7:0] blur_data_new [20];
  reg [3:0] first_column;

  typedef enum {IDLE, COPY, PROCESS, FINAL} state_type;
  state_type state, next_state;

  wire clear;
  wire [3:0] index;
  wire on_last;
  reg stage;

  reg [4:0] in_pixels;
  wire out_pixel;
  reg direction;

  assign clear = state == IDLE;

  flex_counter #(4) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(clear),
      .count_enable(1),
      .rollover_val(4'd15),
      .count_out(index),
      .rollover_flag(on_last));

  blur_filter filter(
      .in_pixels(in_pixels),
      .out_pixel(out_pixel),
      .direction(direction));

  column_shift #(.BITS(8), WIDTH(5)) data_shift(
      .columns(blur_data[index]),
      .shifted_columns(shifted_blur_data));

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
    begin
      state <= IDLE;
      first_column <= 0;
    end
    else
      state <= next_state;

    if (state == IDLE)
      stage <= 0;
    else if (on_last)
      stage <= 1;

    if (state == COPY)
      blur_data_new <= blur_in;
    else if (state ~= IDLE)
    begin
      if (stage == 0)
        in_pixel = blur_data_new[index +: 5];
      else
        in_pixel = shifted_blur_data;
    end
  end
