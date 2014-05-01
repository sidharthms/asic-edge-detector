// $Id: $
// File name:   tb_ARM.sv
// Created:     4/24/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Simulates ARM processor, that talks to the bus, write things to SRAM and so on and so forth
`timescale 1ns / 100ps

module tb_pixelcontroller
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

	wire AHB_HCLK;
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
	reg [24:0] tbp_num_pix_read, tbp_num_pix_write;
	reg tbp_n_rst;
	reg tbp_read_now;
		

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
			  	
	pixelcontroller PIXCON(.clk(tb_clk),
	.enable(tbp_enable),
	.data_out(tbp_data_out),
	.data_in(tbp_data_in),
	.address_write_offset(tbp_address_write_offset),
	.address_read_offset(tbp_address_read_offset),
	.num_pix_read(tbp_num_pix_read),
	.num_pix_write(tbp_num_pix_write),
	.n_rst(tbp_n_rst),
	.read_now(tbp_read_now),
	.address(paddress),
	.w_data(pw_data),
	.r_data(r_data),
	.read_enable(pread_enable),
	.write_enable(pwrite_enable));
		
   integer in_file, out_file; //file handles
   integer i,J; //counter variable
   integer r; //result code for file operation
   //Test bench process
   initial
    begin
		out_file = $fopen("aoutputs.mem");
		global_setup = 1;
				
		//initializes
		mem_clr = 1'b0;
		swrite_enable = 1'b0;
		sread_enable = 1'b0;
		saddress = 0;
		sw_data = 0;
	
		mem_init = 1'b0;
		mem_dump = 1'b0;
		
		#(TIMESTEP*5);	
		//Initializes SRAM
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
		 
		//Toggle Setup Mode Off
		global_setup = 0;
		#(CLK_T);
		
	        $fwrite(out_file,"<loc>:<data>;\n%x:%x;\n%x:%x\n;",0,24'h80,1,24'h80);	
	
		for(J=0;J<=820;J=J+1) begin
			$display("Testing Pixel Controller");
			//Test Parameters for Pixel Controller
			tbp_n_rst <= 1'b0;
			#(CLK_T);
			tbp_n_rst <= 1'b1;
			tbp_num_pix_write <= 00;	
			tbp_num_pix_read <= 20;
			tbp_enable <= 1'b1;
			tbp_address_write_offset <= 16'h00;
			tbp_address_read_offset <= J*20;
			
			//tbp_data_in[0] = 8'hBB;
			//tbp_data_in[1] = 8'hBF;
			
			#(12*CLK_T);
			$display("========== Progress: %.3f %% ==============",J*100/820.00);			
			//Check Output in Data Out Registers
			for(i = 0; i < tbp_num_pix_read; i = i+1) begin		
			    //TODO: negedge seem to not be safe enough
			    @(posedge tbp_read_now);
			   
			//   $display("[PXCTL] PX %d is RGB <%d,%d,%d>", tbp_address_read_offset + i, (r_data >> 16) & 24'h0000FF, (r_data >> 8) & 24'h0000FF, r_data & 24'h0000FF);
			 //  $display("------------ accessible via reg as <%d>",  tbp_data_out[i]);			
			 //  $display("%x",tbp_data_out);			 
			   $fwrite(out_file,"%x:%x;\n",tbp_address_read_offset + i + 2,tbp_data_out[i] & 24'hFF);
			end
		end

		#(CLK_T*2);
		
		//DUMP MEMORY
/*		#(CLK_T*2);	
		mem_dump = 1'b1;
		#(TIMESTEP);
		mem_dump = 1'b0;
*/

		$fclose(out_file);
		#(30000);
		//Double Check Memory	
		$display("RECONSTRUCTING IMAGE!");
		$system("bash source/reconstruct.sh");

		$display("Grayscale Test Complete!");
		
			
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
		//AHB_HADDR = address;
	endfunction : send

endmodule
