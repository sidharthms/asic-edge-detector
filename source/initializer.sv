// $Id: $
// File name:   initializer
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// $Id: $
// File name:   initializer
// Created:     4/23/2014
// Author:      Suppatach Sabpisal
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Listens for request on AHB BUS
//		and starts controllers when start sequence is found


module initializer
#
(
 parameter BUSWIDTH=32,
 parameter SLAVEADDRESS=3337
)
(
	input wire 		  n_rst,
	input wire 		  ahb_hclk, //bus clock
	input wire [1:0] 	  ahb_htrans, //transfer kind
	input wire [2:0] 	  ahb_hburst, //burst kind
	input wire 		  ahb_hwrite, //transfer direction
	input wire 		  ahb_hprot, //protection control
	input wire [BUSWIDTH-1:0] ahb_haddr, //address bus 
  input wire [BUSWIDTH-1:0] ahb_hwdata, //write data bus
	input wire [BUSWIDTH-1:0] ahb_hrdata, //read data bus
	input wire 		  ahb_hgrant, //bus grant
	input wire 		  ahb_hlock, //locked transfer request
	input wire 		  ahb_hbusreq, //bus request  
	output reg                ahb_hready, //slave is ready
  output reg [1:0]                ahb_hresp, //transfer response
	output reg [BUSWIDTH-1:0] 	  width,
	output reg [BUSWIDTH-1:0] 	  height,
	output reg [BUSWIDTH-1:0] 	  readStartAddress,
	output reg [BUSWIDTH-1:0] 	  writeStartAddress,
	output reg 		  filterType,
  output reg                final_enable 
);

   
   //READ_ADDR1: state that verify the address sent from the bus to match slave address, if true, go read width
   //READ_ADDR2: state that verify the address sent from the bus to match slave address, if true, go read height
   typedef enum bit[4:0] {IDLE, READ_ADD1,READ_WIDTH,READ_ADD2,READ_HEIGHT,READ_ADD3,READ_RSTADD, READ_ADD4,READ_WSTADD,READ_ADD5,READ_FILTER,KICKSTART} state_type;
   state_type state, nextstate;
         
  // reg 		flex_clear, flex_en;   
   //reg [3:0] 	flex_out;
   //reg 		flex_done;
   
/*    flex_counter #(.NUM_CNT_BITS(4)) cycle_counter(
      .clk(ahb_clk),
      .n_rst(n_rst),
      .clear(flex_clear),
      .count_enable(flex_en),
      .rollover_val(15),
      .count_out(flex_out),
      .rollover_flag(flex_done));
 */

   always @ (posedge ahb_hclk, negedge n_rst) 
   begin
      //$display("n_rst out is: %d",n_rst);
      if(~n_rst) begin
	 state = IDLE;
         $display("n_rst is: %d",n_rst);
      end else begin
         state = nextstate;
         $display("n_rst here is : %d",n_rst);
      end
   end 

   always @ (ahb_hclk, n_rst, ahb_haddr, ahb_hrdata) begin: next_state
      ahb_hready='1;
      //ahb_hresp='0;
      //nextstate=state;
      //final_enable='0;
      case(state)
	IDLE: begin
	   ahb_hready='1;
	   ahb_hresp='0;
           filterType='0;
           final_enable='0;
	   nextstate=READ_ADD1;
           $display("ahb_haddr in IDLE is:%h",ahb_haddr);
	   
	end

	READ_ADD1: begin
	   ahb_hready='1;
           $display("ahb_haddr is:%h",ahb_haddr);
           $display("slaveadd is:%h",SLAVEADDRESS);

           if (ahb_haddr == SLAVEADDRESS) begin
	      nextstate = READ_WIDTH;
	   end
           else begin
               nextstate = IDLE;
           end
	end // case: READ_ADD1
	

	READ_WIDTH: begin
	   ahb_hready='1;
           if (~ahb_hrdata[31] && ahb_hrdata[29] && ~ahb_hrdata[30])begin   // 01 of the MSB for width
               width={3'b000,ahb_hrdata[28:0]};
               nextstate=READ_ADD2;
               ahb_hresp='0;
           end else begin
               ahb_hresp=2'b10;
               nextstate=IDLE;
           end 
	end


	READ_ADD2: begin
	   ahb_hready='1;

           if (ahb_haddr == SLAVEADDRESS) begin
	      nextstate = READ_HEIGHT;
	   end else begin
	      nextstate = READ_ADD2;
	   end
	end

        READ_HEIGHT: begin
	   ahb_hready='1;

           if (~ahb_hrdata[31] && ~ahb_hrdata[29] && ahb_hrdata[30]) begin // 10 of the MSB for height 
               height={3'b000,ahb_hrdata[28:0]};
               nextstate=READ_ADD3;
               ahb_hresp='0;
           end else begin
               nextstate=IDLE;
               ahb_hresp =2'b10;
           end
	end


        READ_ADD3: begin
	   ahb_hready='1;

           if (ahb_haddr == SLAVEADDRESS) begin
	      nextstate = READ_RSTADD;
	   end else begin
	      nextstate = READ_ADD3;
	   end
	end


        READ_RSTADD: begin
	   ahb_hready='1;
           if (~ahb_hrdata[31] && ahb_hrdata[29] && ahb_hrdata[30]) begin // 11 of the MSB for read readstartaddress 
               readStartAddress={3'b000,ahb_hrdata[28:0]};
               nextstate=READ_ADD4;
               ahb_hresp='0;
           end else begin
               nextstate=IDLE;
               ahb_hresp =2'b10;
           end
	end


        READ_ADD4: begin
	   ahb_hready='1;

           if (ahb_haddr == SLAVEADDRESS) begin
	      nextstate = READ_WSTADD;
	   end else begin
	      nextstate = READ_ADD4;
	   end
	end

        READ_WSTADD: begin
	   ahb_hready='1;
           if (ahb_hrdata[31] && ~ahb_hrdata[29] && ~ahb_hrdata[30]) begin // 100 of the MSB for read readwriteaddress 
               writeStartAddress ={3'b000,ahb_hrdata[28:0]};
               nextstate=READ_ADD5;
               ahb_hresp='0;
           end else begin
               nextstate=IDLE;
               ahb_hresp =2'b10;
           end
	end


        READ_ADD5: begin
	   ahb_hready='1;
 
           if (ahb_haddr == SLAVEADDRESS) begin
	      nextstate = READ_FILTER;
	   end else begin
	      nextstate = READ_ADD5;
	   end
	end


	READ_FILTER: begin
	   ahb_hready=1;
           if ((ahb_hrdata[31] && ahb_hrdata[29] && ~ahb_hrdata[30]))
           begin     // 101 of the MSB for read filter 
               filterType='1;
               $display("im here");
               nextstate=KICKSTART;
           end
           else
           begin
               $display("im also here");
               nextstate= IDLE;
               ahb_hresp =2'b10;
           end
	end

	KICKSTART: begin
	   ahb_hready=0;
           final_enable = '1;
           $display("final enable is:%d",final_enable);
           nextstate = KICKSTART;
       end

   endcase // case (state)

  end // block: nextstate
 
endmodule
