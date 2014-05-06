// $Id: mg79$
// File name:   edge_detect.sv
// Created:     3/17/2014
// Author:      Sidharth Mudgal Sunil Kumar

module edge_detect
(
  input wire clk,
  input wire n_rst,

  input wire en_filter,
  input wire [15:0] width,
  input wire [15:0] height,
  input wire [31:0] in_start_address,
  input wire [31:0] out_start_address,
  input wire filter_type,

  output wire [15:0] anchor_x,
  output wire [15:0] anchor_y,
  output wire anchor_moving,
  output reg  [31:0] read_start_address,
  output reg  [4:0]  read_length,
  input  wire [19:0][7:0] read_data,
  output reg  [31:0] write_start_address,
  output reg  [4:0] write_length,
  output reg  [9:0][7:0] write_data,
  input  wire io_final,

  output wire system_done,

  // Verification Outputs.
  output reg [9:0][7:0] write_blur,
  output reg [9:0][7:0] write_grad_mag,
  output reg [9:0][1:0] write_grad_ang
);

  parameter Y_OFFSET = 4;

  wire blur_final;
  wire gradient_final;
  wire nms_final;
  wire hyst_final;

  wire [15:0][7:0] blur_out;
  wire [13:0][1:0] gradient_angle_out;
  wire [13:0][7:0] gradient_mag;
  wire [11:0][1:0] nms_angle_out;
  wire [11:0][7:0] nms_out;
  wire [9:0][7:0]  hyst_out;
  
  reg [4:0]  read_block_size;
  reg [3:0]  write_block_size;
  reg [15:0] px_to_right;
  reg [15:0] write_y;
  reg [15:0] write_x;
  reg overflow;

  reg copy_state;

  always @ (posedge clk, negedge n_rst)
  begin
    if (n_rst == 0)
      copy_state <= 0;
    else
    begin
      copy_state <= anchor_moving;

      if (copy_state)
      begin
        write_data[9:0] <= hyst_out;
        write_blur <= blur_out[12:3];
        write_grad_mag <= gradient_mag[11:2];
        write_grad_ang <= gradient_angle_out[11:2];
      end
    end
  end

  always @ (*)
  begin
    // Find read start address relative to input start address.
    read_start_address = in_start_address + 
        (width*anchor_y + anchor_x);

    // Find write start address location.
    {overflow, write_y} = anchor_y - 2*Y_OFFSET;
    write_x = anchor_x == 0 ? 0 : anchor_x + 5;
    if (overflow)
    begin
      write_x = anchor_x == 5 ? 0 : anchor_x - 10;
      write_y = write_y + height + Y_OFFSET;
    end
    
    // Find write start address relative to output start address.
    write_start_address = out_start_address +
        (width * write_y) + write_x;

    read_block_size = anchor_x == 0 ? 15 : 20;
    write_block_size = 10;

    // Find number of pixels to read.
    {overflow, px_to_right} = width - anchor_x;
    if (anchor_y < height && !overflow)
      read_length = px_to_right < read_block_size ? 
          px_to_right : read_block_size;
    else
      read_length = 0;

    // Find number of pixels to write.
    {overflow, px_to_right} = width - write_x;
    if (write_y < height)
      write_length = px_to_right < write_block_size ? 
          px_to_right : write_block_size;
    else
      write_length = 0;
  end

  anchor_controller controller1(
    .clk(clk),
    .n_rst(n_rst),
    .en_filter(en_filter),
    .io_final(io_final),
    .blur_final(blur_final),
    .gradient_final(gradient_final),
    .nms_final(nms_final),
    .hyst_final(hyst_final),
    .width(width),
    .height(height),
    .anchor_moving(anchor_moving),
    .anchor_y(anchor_y),
    .anchor_x(anchor_x),
    .process_done(system_done));

  blur_controller controller2(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .anchor_y(anchor_y),
    .blur_in(read_data),
    .blur_out(blur_out),
    .blur_final(blur_final));
 
  gradient_controller controller3(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .anchor_y(anchor_y),
    .gradient_in(blur_out),
    .gradient_angle(gradient_angle_out),
    .gradient_mag(gradient_mag),
    .gradient_final(gradient_final));

  nms_controller controller4(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .gradient_angle(gradient_angle_out),
    .gradient_mag(gradient_mag),
    .nms_angle_out(nms_angle_out),
    .nms_out(nms_out),
    .nms_final(nms_final));

  hyst_controller controller5(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .gradient_angle(nms_angle_out),
    .hyst_in(nms_out),
    .hyst_out(hyst_out),
    .hyst_final(hyst_final));
endmodule
