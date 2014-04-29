// $Id: $
// File name:   pixelcontroller.sv
// Created:     4/28/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Obtains bunch of pixels or write bunch of pixels based on requested address offset and number of pixel wanted
//	        and also greyscalify each pixel

module pixelcontroller(
	output reg [19:0][7:0] data_out,           //requested pixels from SRAM
	input reg [19:0][7:0] data_in,		   //requested pixels to be written to SRAM
	input wire [31:0] address_write_offset,	   //starting at what address do we start writing to
	input wire [31:0] address_read_offset, 	   //starting at what address do we start reading from
	input wire [4:0] num_pix_read,		   //how many pixels do we need to read
	input wire [4:0] num_pix_write		   //how many pixels do we need to write
);



endmodule
