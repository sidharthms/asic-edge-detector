// $Id: $
// File name:   filter_controller.sv
// Created:     3/19/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Filter Controller

module filter
(
  input wire clk,
  input wire n_rst,
  input wire anchor_moving,         // Start filtering when anchor moves.
  input wire [31:0] anchor_x;
  input wire [31:0] anchor_y;
  input wire type,                  // Type of filtering to apply.

  input wire [7:0] read_buffer [20];
  output wire 
  output reg filter_done            // Filter phase completed for all pixels.
);

  reg [7:0] blur_in [20];
  reg [7:0] blur_data [16][5];
  reg [7:0] blur_out [16]
  typedef enum {IDLE, PROCESSING, DONE} state_type;
  state_type state, next_state;

