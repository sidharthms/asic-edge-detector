// $Id: mg79$
// File name:   edge_detect.sv
// Created:     3/17/2014
// Author:      Sidharth Mudgal Sunil Kumar

module controller
(
  input wire clk,
  input wire n_rst,
  input wire en_filter,             // Start the filtering phase.

  output wire read_enable,
  output wire write_enable,

  output wire anchor_moving,
  output wire [31:0] anchor_y,
  output wire [31:0] anchor_x,
  
  output reg process_done           // Filter phase completed for all pixels.
);
  anchor_controller anchor(
    .clk(clk),
    .n_rst(n_rst),
    .en_filter(en_filter)
