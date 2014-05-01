// $Id: $
// File name:   tb_initializer.sv
// Created:     4/29/2014
// Author:      Hao Xiong
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: test bench for initializer block

`timescale 1ns/100ps

module tb_initializer
();

localparam CLK_T = 10;
localparam TIMESTEP=5;
localparam BUSWIDTH=32;

reg tb_clk;
reg tb_rst;

reg tb_ahb_hclk; //bus clock
reg [1:0] tb_ahb_htrans; //transfer kind
reg [2:0] tb_ahb_hburst; //burst kind
reg tb_ahb_hwrite; //transfer direction
reg tb_ahb_hprot; //protection control
reg [BUSWIDTH-1:0] tb_ahb_haddr; //address bus
reg [BUSWIDTH-1:0] tb_ahb_hwdata; //write data bus
reg [BUSWIDTH-1:0] tb_ahb_hrdata; //read data bus
reg tb_ahb_hgrant; //bus grant
reg tb_ahb_hlock; //locked transfer request
reg tb_ahb_hbusreq; //bus request  
reg tb_ahb_hready; //slave is ready
reg [1:0] tb_ahb_hresp; //transfer response
reg [BUSWIDTH-1:0] tb_width;
reg [BUSWIDTH-1:0] tb_height;
reg [BUSWIDTH-1:0] tb_readStartAddress;
reg [BUSWIDTH-1:0] tb_writeStartAddress;
reg tb_filterType;
reg tb_final_enable;


always
begin : CLK_GEN
    tb_ahb_hclk=1'b0;
    #(CLK_T / 2);
    tb_ahb_hclk=1'b1;
    #(CLK_T / 2);
end

initializer INIT(.n_rst(tb_rst),
                 .ahb_hclk(tb_ahb_hclk),
                 .ahb_htrans(tb_ahb_htrans),
                 .ahb_hburst(tb_ahb_hburst),
                 .ahb_hwrite(tb_ahb_hwrite),
                 .ahb_hprot(tb_ahb_hprot),
                 .ahb_haddr(tb_ahb_haddr),
                 .ahb_hwdata(tb_ahb_hwdata),
                 .ahb_hrdata(tb_ahb_hrdata),
                 .ahb_hgrant(tb_ahb_hgrant),
                 .ahb_hlock(tb_ahb_hlock),
                 .ahb_hbusreq(tb_ahb_hbusreq),
                 .ahb_hready(tb_ahb_hready),
                 .ahb_hresp(tb_ahb_hresp),
                 .width(tb_width),
                 .height(tb_height),
                 .readStartAddress(tb_readStartAddress),
                 .writeStartAddress(tb_writeStartAddress),
                 .filterType(tb_filterType),
             .final_enable(tb_final_enable));

initial
begin
    //reset the design 
    tb_rst=0;
    #(TIMESTEP*3);
    
    //test case number one, sending the correct signals to finish all the state
    //feed to state IDLE 
    tb_rst=1'b1;
    #(CLK_T*2);

    //feed to readadd1
    tb_ahb_haddr=32'hD09;

    //feed to read width state
    #(CLK_T); 
    tb_ahb_hrdata=32'h20000151;    //send the width with most significant 3 bits to be 001 

    //feed to read add2
    #(CLK_T); 
    tb_ahb_haddr=32'hD09;

    //feed to read height state
    #(CLK_T); 
    tb_ahb_hrdata=32'h40000151;

    //feed to read add3
    #(CLK_T); 
    tb_ahb_haddr=32'hD09;

    //feed to read readstartaddress
    #(CLK_T); 
    tb_ahb_hrdata=32'h600001F4;   // 011


    //feed to read add4
    #(CLK_T); 
    tb_ahb_haddr=32'hD09;

    //feed to read writestartaddress
    #(CLK_T); 
    tb_ahb_hrdata=32'h8000157C;  //100


   //feed to read add5
    #(CLK_T); 
    tb_ahb_haddr=32'hD09;

    //feed to read filter 
    #(CLK_T); 
    tb_ahb_hrdata=32'hA0000001; 

    //feed to KICKSTART state
    #(CLK_T); 
    #(CLK_T/2); 
    tb_ahb_hrdata=1'b1;


end
endmodule
