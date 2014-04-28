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
	localparam BMP_HEADER_SIZE = 50;
  	localparam W_ADDR_SIZE_BITS = 16;
  	localparam W_DATA_SIZE_WORDS = 4;
  	localparam W_WORD_SIZE_BYTES = 1;	
	//Simulation Timestep
	localparam TIMESTEP = 5;
	localparam CLK_T = 12; 
	
	reg tb_clk;
	reg tb_rst;

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
	reg [BUS_WIDTH-1:0] AHB_HADDR;
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

	/*BMP Structures*/

	integer in_file; //file handle
	reg [BMP_HEADER_SIZE:0][7:0] bmp_header;
	
	/*SRAM ports*/	
	localparam DATA_BUS_FLOAT = 32'hz;
	//The number of the initialization file name to use during the next requested memory init
	//Only use values from 0 thru (2^31 - 1) 
	int unsigned init_file_number;
	//The number of the dump file name to use during the next requested memory dump
	int unsigned dump_file_number;
	//Strobe this for at least 1 simulation timestep to zero all memory contents
	reg mem_clr;
	//Strobe this for at least 1 simulation timestep to set the values for addresses
	//currently selected init file to their corresponding values precribed in the file
	reg mem_init;
	//Strobe this for at least 1 simulation timestep to dump all values modified since
	//the most recent mem_clr activation
	//Only the locations between the "start_address" and "last_address" (inclusive) will be printed
	reg mem_dump;
	//Active high enable for more verbose debugging information
	reg verbose;
	//The first address to start dumping memory contents from
	int unsigned start_address;
	//The last address to dump memory contents from
	int unsigned last_address;
	//Memory interface signals
	reg read_enable;
	reg write_enable;
	reg [W_ADDR_SIZE_BITS - 1:0] address, tb_address;
	reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data, tb_w_data;
	wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data, tb_r_data;
	wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1:0] bidata;
	//Testbench for SRAM IFACE
	reg tb_start;
	reg io_done;
	reg tb_writemode;

	//Bidirectional Logic for SRAM
	assign r_data = (read_enable == 1) ? bidata : DATA_BUS_FLOAT;
        assign bidata = (write_enable == 1) ? w_data : DATA_BUS_FLOAT;

	off_chip_sram_wrapper SRAM(.init_file_number(init_file_number), 
                                    .dump_file_number(dump_file_number), 
                                    .mem_clr(mem_clr), 
                                    .mem_init(mem_init),
                                    .mem_dump(mem_dump), 
                                    .start_address(start_address), 
                                    .last_address(last_address), 
                                    .verbose(verbose),
                                    .read_enable(read_enable), 
                                    .write_enable(write_enable), 
                                    .address(address), 
                                    .data(bidata));


	sram_iface SRAMIF(.clk(tb_clk),
			  .n_rst(tb_rst),
			  .start(tb_start),
		          .writemode(tb_writemode),
			  .i_address(tb_address),
			  .i_w_data(tb_w_data),
			  .i_r_data(tb_r_data),
			  .io_done(io_done),
			  .read_enable(read_enable),
			  .write_enable(write_enable),
			  .address(address),
			  .w_data(w_data),
			  .r_data(r_data));

   //Test bench process
   initial
    begin
		//rest
		mem_clr = 1'b0;
		//write_enable = 1'b0;
		//read_enable = 1'b0;
		tb_address = 0;
		tb_w_data = 0;
		tb_writemode = 0;
		mem_init = 1'b0;
		mem_dump = 1'b0;
		
		#(TIMESTEP*5);	
		//Initialzie SRAM
		mem_clr = 1'b1;
		#(TIMESTEP);
		mem_clr = 1'b0;

		init_file_number = 0;
		dump_file_number = 0;
		start_address = 0;
		last_address = 65535;
		
		//address <= 0;
		//read_enable <= 0;

		//Load Init File into Memory		
		mem_init = 1'b1;
		#(TIMESTEP);
		mem_init = 1'b0;
		
		#(CLK_T*10);

		//Modify some memory
		//address <= 16'b00000001;
		//write_enable <= 1;
		//w_data <= 32'hAAAAAAAA;
		//#(CLK_T);
		//write_enable <= 1'b0;

		//#(TIMESTEP);

		//write_enable <= 0;		

		//Send some request to SRAM IFACE
		tb_rst = 1'b0;
		#(TIMESTEP);
		tb_rst = 1'b1;
		tb_address = 16'b0000001;
		tb_w_data = 32'hAF;
		tb_writemode = 1'b1;
		//strobe start
		tb_start = 1'b1;
		#(5*TIMESTEP);
		tb_start = 1'b0;
		
		#(CLK_T);		

		tb_rst = 1'b0;		
		#(TIMESTEP);
		tb_rst = 1'b1;
	        #(CLK_T*2);
		//LOAD MEMORY
		tb_writemode = 1'b0;
		tb_address = 16'b00000001;
		//strobe start
		tb_start = 1'b1;
		#(5*TIMESTEP);
		tb_start = 1'b0;

		//DUMP MEMORY
		#(CLK_T*2);
	
                mem_dump = 1'b1;
                #(TIMESTEP);
         	mem_dump = 1'b0;
	
		
   end
	
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_T / 2);
		tb_clk = 1'b1;
		#(CLK_T / 2);
	end

	function void putImageInSRAM();
		//read image file unpacked by python
		//and dump to SRAM
		in_file = $fopen("image.bmp", "rb");
		$fscanf(in_file,"%c" , bmp_header[0]);
	endfunction : putImageInSRAM

	function void send(integer address, integer data);
		//Generic Method for sending data
		$display ("Sending Data over AHB...");
		AHB_HADDR = address;
	endfunction : send

endmodule
