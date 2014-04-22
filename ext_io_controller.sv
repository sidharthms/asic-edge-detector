// $Id: $
// File name:   filter_controller.sv
// Created:     3/19/2014
// Author:      Sidharth Mudgal Sunil Kumar
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Filter Controller

module filter_controller
(
  input wire clk,
  input wire n_rst,
  input wire anchor_moving,         // Start filtering when anchor moves.
  input wire type,                  // Type of filtering to apply.
  output reg [3:0] block,           // Combinational block to apply.
  output reg filter_done            // Filter phase completed for all pixels.
);

  typedef enum {IDLE, PROCESSING, DONE} state_type;
  state_type state, next_state;

