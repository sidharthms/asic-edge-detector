// $Id: mg79$
// File name:   edge_detect.sv
// Created:     3/17/2014
// Author:      Sidharth Mudgal Sunil Kumar

module edge_detect
#
(
  parameter BUSWIDTH=32,
	parameter W_ADDR_SIZE_BITS = 16,
	parameter W_DATA_SIZE_WORDS = 3,
	parameter W_WORD_SIZE_BYTES = 1,
	parameter DATA_BUS_FLOAT = 24'hz,
	parameter BIT_PER_PIXEL = 8
)
(
  input wire clk,
  input wire n_rst,

  //siganls that connects to the initalizer block
  input wire [1:0] 	  ahb_htrans, //transfer kind
	input wire [2:0] 	  ahb_hburst, //burst kind
	input wire 		  ahb_hwrite, //transfer direction
	input wire 		  ahb_hprot, //protection control
	input wire [BUSWIDTH-1:0] ahb_haddr, //address bus 
  input wire [BUSWIDTH-1:0] ahb_hwdata, //write data bus
	input wire [BUSWIDTH-1:0] ahb_hrdata, //read data bus
	input wire ahb_hgrant, //bus grant
	input wire ahb_hlock, //locked transfer request
	input wire ahb_hbusreq, //bus request 
  output reg ahb_hready, //slave is ready
  output reg [1:0] ahb_hresp, //transfer response

  //for the pixel controller
	output reg [W_ADDR_SIZE_BITS - 1:0] address,
	output reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data,
	input wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data,
	output reg read_enable,
	output reg write_enable 
  
);

  // signals that connects to the intializer block
  reg [BUSWIDTH-1:0] 	  width;
  reg [BUSWIDTH-1:0] 	  height;
  reg [BUSWIDTH-1:0] 	  readStartAddress;
  reg [BUSWIDTH-1:0] 	  writeStartAddress;
  reg 		  filterType;
  reg       final_enable;

  //sigs to pixel controller
  reg enable;
  reg [19:0]
  reg [19:0][BIT_PER_PIXEL - 1:0] data_out,         
	reg [19:0][BIT_PER_PIXEL - 1:0] data_in,		   
	reg [W_ADDR_SIZE_BITS - 1:0] address_write_offset,  
	reg [W_ADDR_SIZE_BITS - 1:0] address_read_offset, 
	reg [24:0] num_pix_read,		 	   //how many pixels do we need to read
	reg [24:0] num_pix_write,		   //how many pixels do we need to write
  reg read_now;
  reg end_of_operations;

  initializer INIT(
    .n_rst(n_rst),
    .ahb_hclk(clk),
    .ahb_htrans(ahb_htrans),
    .ahb_hburst(ahb_hburst),
    .ahb_hwrite(ahb_hwrite),
    .ahb_hprot(ahb_hprot),
    .ahb_haddr(ahb_haddr),
    .ahb_hwdata(ahb_hwdata),
    .ahb_hrdata(ahb_hrdata),
    .ahb_hgrant(ahb_hgrant),
    .ahb_hlock(ahb_hlock),
    .ahb_hbusreq(ahb_hbusreq),
    .ahb_hready(ahb_hready),
    .ahb_hresp(ahb_hresp),
    .width(width),
    .height(height),
    .readStartAddress(readStartAddress),
    .writeStartAddress(writeStartAddress),
    .filterType(filterType),
    .final_enable(final_enable));

  pixelcontroller PXCO(.clk(clk),
    .enable(enable),
    .data_out(),
    .data_in(),
    .address_write_offset(),
    .address_read_offset(),
    .num_pix_read(),
    .num_pix_write(),
  );

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
    .process_done(process_done));

  blur_controller controller2(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .anchor_x(anchor_x),
    .blur_in(read_buffer),
    .blur_out(blur_out),
    .blur_final(blur_final));
 
  gradient_final controller3(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .anchor_x(anchor_x),
    .gradient_in(gradient_in),
    .gradient_angle(gradient_angle_out),
    .gradient_mag(gradient_mag),
    .gradient_final(gradient_final));

  nms_controller controller4(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .gradient_angle(gradient_angle_nms),
    .gradient_mag(gradient_mag),
    .nms_angle_out(nms_angle_out),
    .nms_out(nms_out),
    .nms_final(nms_final));

  hyst_controller controller5(
    .clk(clk),
    .n_rst(n_rst),
    .anchor_moving(anchor_moving),
    .gradient_angle(gradient_angle_hyst),
    .hyst_in(hyst_in),
    .hyst_out(hyst_out),
    .hyst_final(hyst_final));

