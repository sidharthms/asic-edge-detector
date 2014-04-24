// $Id: $
// File name:   tb_ARM.sv
// Created:     4/24/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Simulates ARM processor, that talks to the bus, write things to SRAM and so on and so forth
`timescale 1ns / 100ps

module tb_ARM
();
        // Define local parameters used by the test bench
        localparam BUS_WIDTH = 32;
	localparam SRAM_ADDR = 32'b11111001;	
	localparam DUT_ADDR = 32'b000001111;

	//Bus Signals
	//Bus Clock
	wire AHB_HCLK;
	//Transfer kind (out)
	wire [1:0] AHB_HTRANS;
	//Burst kind (out)
	wire [2:0] AHB_HBURST;
	//Transfer size (out)
	wire [2:0] AHB_HSIZE;
	//Transfer direction (out)
	wire AHB_HWRITE;
	//Protection control (out)
	wire [3:0] AHB_HPROT;
	//Address bus (out)
	wire [BUS_WIDTH-1:0] AHB_HADDR;
	//Write data bus (out)
	wire [BUS_WIDTH-1:0] AHB_HWDATA;
	//Read data bus (in)
	wire [BUS_WIDTH-1:0] AHB_HRDATA;
	//Bus grant (in)
	wire AHB_HGRANT;
	//Slave is ready (in)
	wire AHB_HREADY;
	//Locked transfer request (out)
	wire AHB_HLOCK;
	//Bus request (out)
	wire AHB_HBUSREQ;
	//Reset (in)
	wire AHB_HRESET;
	//Transfer response (in)
	wire [1:0] AHB_RESP;

	//BMP Structures
	localparam BMP_HEADER_SIZE = 50;
	integer in_file; //file handle
	reg [BMP_HEADER_SIZE:0][7:0] bmp_header;

        // DUT port map
        //Connect to Interface DUT

        // Test bench process
        initial
        begin
		//Send stuff to DUT
		send(DUT_ADDR, BUS_WIDTH);
		//Wait for DUT's response
	end

	function void gen_hclock();
		//Generate CLOCK here
	endfunction : gen_hclock

	function void getImageFile();
		//Generic Method for reading file (ex. image file unpacked by python)
		in_file = $fopen("image.bmp", "rb");
		$fscanf(in_file,"%c" , bmp_header[0]);
	endfunction : getImageFile

	function void send(integer address, integer data);
		//Generic Method for sending data
		$display ("Sending Data...");
	endfunction : send

endmodule
