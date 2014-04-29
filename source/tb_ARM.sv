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

  	localparam W_ADDR_SIZE_BITS = 16;
  	localparam W_DATA_SIZE_WORDS = 3;
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

	
	/*SRAM ports*/	
	localparam DATA_BUS_FLOAT = 24'hz;
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
	reg read_enable, sread_enable, pread_enable;
	reg write_enable, swrite_enable, pwrite_enable;
	reg [W_ADDR_SIZE_BITS - 1:0] address, paddress, saddress;
	reg [W_ADDR_SIZE_BITS - 1:0] tb_address;
	reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] w_data, sw_data, pw_data, tb_w_data;
	wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1: 0] r_data, tb_r_data;
	wire [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1:0] bidata;
	//Testbench for SRAM IFACE
	reg tb_start;
	reg io_done;
	reg tb_writemode;

	//Testbench Control
	reg global_setup;
	assign read_enable = (global_setup == 1) ? sread_enable : pread_enable;
	assign write_enable = (global_setup == 1) ? swrite_enable : pwrite_enable;
	assign address = (global_setup == 1) ? saddress : paddress;        
	assign w_data = (global_setup == 1) ? sw_data: pw_data;	

	//Bidirectional Logic for SRAM
	assign r_data = (read_enable == 1) ? bidata : DATA_BUS_FLOAT;
        assign bidata = (write_enable == 1) ? w_data : DATA_BUS_FLOAT;

	//File Read Variables
	integer fd;
	reg [W_DATA_SIZE_WORDS * W_WORD_SIZE_BYTES * 8 - 1:0] read_in;
	integer count, code;
	reg [W_ADDR_SIZE_BITS - 1:0] current_addr;

	//Testbench for Pixel Controller
	reg tbp_enable;
	reg [19:0][7:0] tbp_data_out;
	reg [19:0][7:0] tbp_data_in;
	reg [W_ADDR_SIZE_BITS - 1:0] tbp_address_write_offset, tbp_address_read_offset;
	reg [4:0] tbp_num_pix_read, tbp_num_pix_write;
	reg tbp_n_rst;
		

	off_chip_sram_wrapper #(W_ADDR_SIZE_BITS,3,1,10,10) SRAM(.init_file_number(init_file_number), 
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
			  .rst(tb_rst),
			  .start(tb_start),
		          .writemode(tb_writemode),
			  .i_address(tb_address),
			  .i_w_data(tb_w_data),
			  .i_r_data(tb_r_data),
			  .io_done(io_done),
			  .read_enable(sread_enable),
			  .write_enable(swrite_enable),
			  .address(saddress),
			  .w_data(sw_data),
			  .r_data(r_data));


	
	pixelcontroller PIXCON(.clk(tb_clk),
	.enable(tbp_enable),
	.data_out(tbp_data_out),
	.data_in(tbp_data_in),
	.address_write_offset(tbp_address_write_offset),
	.address_read_offset(tbp_address_read_offset),
	.num_pix_read(tbp_num_pix_read),
	.num_pix_write(tbp_num_pix_write),
	.n_rst(tbp_n_rst),
	.address(paddress),
	.w_data(pw_data),
	.r_data(r_data),
	.read_enable(pread_enable),
	.write_enable(pwrite_enable));
		
   integer in_file;
   integer i;
   //Test bench process
   initial
    begin
		global_setup = 1;
				
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
		

		//Load Init File into Memory		
		mem_init = 1'b1;
		#(TIMESTEP);
		mem_init = 1'b0;
	  	current_addr = 0;		

		in_file = $fopen("hex.img", "r");
                code = 1;
		while(!$feof(in_file)) begin
			$fscanf(in_file, "%x", read_in);
			#(CLK_T*2);

			//Send some request to SRAM IFACE
			tb_rst = 1'b0;
			#(TIMESTEP);
			tb_rst = 1'b1;
			tb_address = current_addr;
			tb_w_data = read_in;
			tb_writemode = 1'b1;
			//strobe start
			tb_start = 1'b1;
			#(5*TIMESTEP);
			tb_start = 1'b0;
///			read_enable = 1'b0;
///			write_enable = 1'b1;
///			address = current_addr;
///			w_data = read_in;
			
			#(CLK_T*2);		
			$display("[DIRECT] reading file to memory %d = %x", current_addr, read_in);
			current_addr = current_addr + 1;
		end		
	 
		

		for(i = 0; i < current_addr; i = i+1) begin
			//read_enable = 1'b1;
			//write_enable = 1'b0;
			//address = i;
			tb_rst = 1'b0;
                	#(TIMESTEP);
	                tb_rst = 1'b1;
        	        tb_address = i;
               	 	tb_writemode = 0;
                	tb_start = 1'b1;
                	#(5*TIMESTEP);
               	 	tb_start = 1'b0;

			#(CLK_T*10);
			$display("[DIRECT] content at memory %x is %x", address, r_data);
 			
		end 

		$display("[DIRECT] Dumping to memory");
		//DUMP MEMORY
		#(CLK_T*2);
	
	
		mem_dump = 1'b1;
		#(TIMESTEP);
		mem_dump = 1'b0;
		
		global_setup = 0;
		#(CLK_T);
		$display("Memory loaded and verified");
		$display("Testing Pixel Controller");
		
		//for(i = 0; i < current_addr; i = i+1) begin
		tbp_enable <= 1;
		tbp_address_read_offset <= 0;
			
		//$display("[PXCTL] PX %x is RGB<%x>", tbp_address_read_offset + i, r_data);
		#(CLK_T*2);	
		
		//end
		//tbp_enable <= 0;
		//tbp_n_rst <= 0;
	end
	
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_T / 2);
		tb_clk = 1'b1;
		#(CLK_T / 2);
	end

	function void send(integer address, integer data);
		//Generic Method for sending data
		$display ("Sending Data over AHB...");
		AHB_HADDR = address;
	endfunction : send

endmodule
