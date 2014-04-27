// $Id: $
// File name:   bus_iface
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Bus Interface - read data from AHB BUS

parameter BUSWIDTH = 32;

module initializer
(
    	input wire ahb_hclk, //bus clock
   	input wire [1:0] ahb_htrans, //transfer kind
	input wire [2:0] ahb_hburst, //burst kind
	input wire ahb_hwrite, //transfer direction
	input wire ahb_hprot, //protection control
	input wire [BUSWIDTH-1:0] ahb_haddr, //address bus
	input wire [BUSWIDTH-1:0] ahb_hwdata, //write data bus
	input wire [BUSWIDTH-1:0] ahb_hrdata, //read data bus
	input wire ahb_hgrant, //bus grant
	output wire ahb_hready, //slave is ready
	input wire ahb_hlock, //locked transfer request
	input wire ahb_hbusreq, //bus request
	output wire ahb_hresp //transfer response
);

endmodule
