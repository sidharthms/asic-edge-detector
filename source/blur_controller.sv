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
  input  wire [31:0] anchor_x,
  input  wire [31:0] anchor_y,

  input  wire [19:0][7:0] blur_in,
  output reg  [15:0][7:0] blur_out,
  output reg blur_final             // Filter phase completed for all pixels.
);
  
  wire anchor_on_init_pos;

  reg  [4:0][15:0][7:0] blur_data;
  reg  [19:0][7:0] blur_data_new;

  typedef enum {IDLE, COPY, PROCESSING} state_type;
  state_type state, next_state;

  wire index_clear;
  wire [3:0] index;
  wire [3:0] index_x1;
  wire [3:0] index_x2;
  wire [3:0] index_y1;
  wire [3:0] index_y2;

  wire unit_en_x;
  wire unit_en_y;
  reg  [4:0][7:0] in_pixels_x1;
  reg  [4:0][7:0] in_pixels_x2;
  reg  [4:0][7:0] in_pixels_y1;
  reg  [4:0][7:0] in_pixels_y2;
  wire [7:0] out_pixel_x1;
  wire [7:0] out_pixel_x2;
  wire [7:0] out_pixel_y1;
  wire [7:0] out_pixel_y2;
  wire unit_final;
  wire unit_final_x;
  wire unit_final_y;

  assign anchor_on_init_pos = anchor_x == 0;
  assign index_clear = next_state != PROCESSING;

  assign index_x1 = 2*index;
  assign index_x2 = 2*index + 1;
  assign index_y1 = 2*(index-1);
  assign index_y2 = 2*(index-1) + 1;

  // Blur filter should be enabled only when all inputs are stable.
  assign unit_en_x = index != 8 && state == PROCESSING; 
  assign unit_en_y = index != 0; 
  assign unit_final = unit_final_x || unit_final_y;

  flex_counter #(.NUM_CNT_BITS(4)) index_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(index_clear),
      .count_enable(unit_final),
      .rollover_val(4'd8),
      .count_out(index));

  blur filter_x1(
      .clk(clk),
      .n_rst(n_rst),
      .en(unit_en_x),
      .in_pixels(in_pixels_x1),
      .out_pixel(out_pixel_x1),
      .final_stage(unit_final_x));

  blur filter_x2(
      .clk(clk),
      .n_rst(n_rst),
      .en(unit_en_x),
      .in_pixels(in_pixels_x2),
      .out_pixel(out_pixel_x2));

  blur filter_y1(
      .clk(clk),
      .n_rst(n_rst),
      .en(unit_en_y),
      .in_pixels(in_pixels_y1),
      .out_pixel(out_pixel_y1),
      .final_stage(unit_final_y));

  blur filter_y2(
      .clk(clk),
      .n_rst(n_rst),
      .en(unit_en_y),
      .in_pixels(in_pixels_y2),
      .out_pixel(out_pixel_y2));

  assign blur_final = (index == 8 && unit_final_y) || state == IDLE;

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
        blur_data_new <= blur_in;
        blur_data[4:1] <= blur_data[3:0];
      end

      if (unit_en_x)
      begin
        if (anchor_on_init_pos)
        begin
          for (int i = 0; i < 5; i=i+1)
          begin
            blur_data[i][index_x1] <= out_pixel_x1;
            blur_data[i][index_x2] <= out_pixel_x2;
          end
        end
        else
        begin
          blur_data[0][index_x1] <= out_pixel_x1;
          blur_data[0][index_x2] <= out_pixel_x2;
        end
      end

      if (unit_en_y && unit_final_y)
      begin
        blur_out[index_y1] <= out_pixel_y1;
        blur_out[index_y2] <= out_pixel_y2;
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
    endcase
  end

  always @ (*)
  begin
    for (int i = 0; i < 5; i=i+1)
    begin
      in_pixels_x1[i] = blur_data_new[index_x1 + i];
      in_pixels_x2[i] = blur_data_new[index_x2 + i];
    end

    for (int i = 0; i < 5; i=i+1)
    begin
      in_pixels_y1[i] = blur_data[i][index_y1];
      in_pixels_y2[i] = blur_data[i][index_y2];
    end
  end
endmodule
