// $Id: mg79$
// File name:   anchor_controller.sv
// Created:     3/17/2014
// Author:      Sidharth Mudgal Sunil Kumar

module anchor_controller
(
  input wire clk,
  input wire n_rst,
  input wire en_filter,             // Start the filtering phase.
  input wire io_final,              // SRAM I/O complete in next cycle.
  input wire blur_final,            // Blur complete in next cycle.
  input wire gradient_final,        // Gradient complete in next cycle.
  input wire nms_final,             // Non-maximal suppression complete in
                                    // next cycle.
  input wire hyst_final,            // Hysterysis complete in next cycle.
  input wire [31:0] width,          // Width of Image.
  input wire [31:0] height,         // Height of Image.
  
  output wire read_enable,
  output wire write_enable,

  output wire anchor_moving,
  output wire [31:0] anchor_y,
  output wire [31:0] anchor_x,
  
  output reg process_done           // Filter phase completed for all pixels.
);

  param x_OFFSET = 5;
  typedef enum {IDLE, PROCESSING, DONE} state_type;
  state_type state, next_state;

  wire x_end;
  wire y_end;

  wire clear;
  wire all_final;
  wire at_x_end;
  wire at_y_end;
  wire y_increment;
  wire on_last_block;

  assign x_end = height + x_OFFSET;
  assign y_end = width;

  assign clear = state == IDLE;
  assign all_final = io_final && blur_final && gradient_final && nms_final &&
      hyst_final;
  assign on_last_block = at_x_end && at_y_end;
  assign anchor_moving = all_final && ~on_last_block;

  fley_counter #(
      .NUM_CNT_BITS(32),
      .ZERO_RESET(1)) 
    x_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(clear),
      .count_enable(anchor_moving),
      .rollover_val(x_end),
      .count_out(anchor_x),
      .rollover_flag(at_x_end));

  fley_counter #(
      .NUM_CNT_BITS(32),
      .FIRST_INCREMENT(15),
      .INCREMENT(20),
      .ZERO_RESET(1)) 
    y_counter(
      .clk(clk),
      .n_rst(n_rst),
      .clear(clear),
      .count_enable(at_x_end),
      .rollover_val(y_end),
      .count_out(anchor_y),
      .rollover_flag(at_y_end));

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 1'b0)
    begin
      state <= IDLE;
      process_done <= 1'b0;
    end
    else 
    begin
      state <= next_state;
      process_done <= next_state == DONE;
    end
  end

  always @ (*)
  begin
    next_state = IDLE;
    case (state)
      IDLE:
      begin
        if (en_filter)
          next_state = PROCESSING;
        else
          next_state = IDLE;
      end
      PROCESSING:
      begin
        if (~anchor_moving)
          next_state = DONE;
        else
          next_state = PROCESSING;
      end
      DONE:
      begin
        next_state = IDLE;
      end
    endcase
  end
endmodule
