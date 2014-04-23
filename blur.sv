// $Id: $
// File name:   blur.sv
// Created:     4/23/2014
// Author:      Sidharth Mudgal Sunil Kumar

module blur
(
	input wire en,
	input wire [7:0] in_pixels [5],
	input wire [7:0] out_pixel,
	output wire final,
);
  
