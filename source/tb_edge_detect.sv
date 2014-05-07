// $Id: $
// File name:   tb_blur_controller.sv
// Created:     4/26/2014
// Author:      Akanksha Sharma

`timescale 1ns / 10ps

module tb_edge_detect;

  // Define parameters
  parameter CLK_PERIOD        = 10;
  localparam NUM_TEST_CASES = 10;
  
  integer tb_test_case;
  integer error_count;
  
  reg tb_clk;
  reg tb_n_rst;
  reg tb_en_filter;
  reg [15:0] tb_width;
  reg [15:0] tb_height;
  reg [31:0] tb_in_start_address;
  reg [31:0] tb_out_start_address;
  reg tb_filter_type;
  reg [15:0] tb_anchor_x;
  reg [15:0] tb_anchor_y;
  reg tb_anchor_moving;
  reg [31:0] tb_read_start_address;
  reg [4:0] tb_read_length;
  reg [19:0][7:0] tb_read_data;
  reg [31:0] tb_write_start_address;
  reg [4:0] tb_write_length;
  reg [9:0][7:0] tb_write_data;
  reg tb_io_final;
  reg tb_system_done;
  reg [9:0][7:0] tb_write_blur;
  reg [9:0][7:0] tb_write_grad_mag;
  reg [9:0][1:0] tb_write_grad_ang;
  
  reg [7:0]  test_cases_image [65095];
  reg [7:0]  test_cases_out [65095];
  reg [7:0]  test_cases_out_blur [65095];
  reg [7:0]  test_cases_out_grad_mag [65095];
  reg [1:0]  test_cases_out_grad_ang [65095];
  reg [7:0]  test_cases_exp_out [65095];
  reg [15:0] width;
  reg [15:0] height;
  integer cntx, rstat;
  bit found_error;
  integer fh; //file Handler  
  integer fo; //file out
  reg [31:0]  read_in;
  integer tb_totalpx;  
// Test vector population
  initial
  begin
    cntx = 0;
    tb_totalpx = 2;
    fo = $fopen("edgeoutput.mem","w");
    fh = $fopen("ainputs.img","r");
    $fwrite(fo,"<addr>:<data>;\n0:000080;\n1:000080;\n"); //write mem header
    #(1000); 
    $display("%d",fh);
    while(!$feof(fh)) begin
	rstat = $fscanf(fh, "%x", read_in);
	$display("%x",read_in);
	test_cases_image[cntx] = read_in;	
	cntx = cntx + 1;
	$display("X");
    end
    $display("deione");    
    width = 255;
    height = 255;
  end

  edge_detect DUT(
    tb_clk,
    tb_n_rst,
    tb_en_filter,
    tb_width,
    tb_height,
    tb_in_start_address,
    tb_out_start_address,
    tb_filter_type,
    tb_anchor_x,
    tb_anchor_y,
    tb_anchor_moving,
    tb_read_start_address,
    tb_read_length,
    tb_read_data,
    tb_write_start_address,
    tb_write_length,
    tb_write_data,
    tb_io_final,
    tb_system_done,
    tb_write_blur,
    tb_write_grad_mag,
    tb_write_grad_ang);

  always
  begin : CLK_GEN
    tb_clk = 1'b0;
    #(CLK_PERIOD / 2);
    tb_clk = 1'b1;
    #(CLK_PERIOD / 2);
  end

  task perform_edge_detect;
    bit done;
  begin
    #(50000); 
    @(negedge tb_clk);
    tb_en_filter = 1;
    tb_width = width;
    tb_height = width;
    tb_in_start_address = 0;
    tb_out_start_address = 0;
    tb_filter_type = 0;
    tb_io_final = 0;

    @(negedge tb_clk);
    tb_en_filter = 0;
    
    tb_io_final = 1;
    done = 0;
    $display("before while"); 
   while (~done)
    begin
      if (tb_read_length < 20 && tb_anchor_x == 0)
      begin
        for (int p = 0; p < tb_read_length; p++)
          tb_read_data[p + 20 - tb_read_length] = 
              test_cases_image[tb_read_start_address + p];
        for (int p = 0; p < 20 - tb_read_length; ++p)
          tb_read_data[p] = tb_read_data[20 - tb_read_length];
      end
      else if (tb_read_length < 20)
      begin
        for (int p = 0; p < tb_read_length; p++)
          tb_read_data[p] = test_cases_image[tb_read_start_address + p];
        for (int p = tb_read_length; p < 20; ++p)
          tb_read_data[p] = tb_read_data[tb_read_length - 1];
      end
      else
        for (int p = 0; p < tb_read_length; p++)
          tb_read_data[p] = test_cases_image[tb_read_start_address + p];

      for (int p = 0; p < tb_write_length; p++)
      begin
        test_cases_out[tb_write_start_address + p] = tb_write_data[p];
        test_cases_out_blur[tb_write_start_address + p] = tb_write_blur[p];
        test_cases_out_grad_mag[tb_write_start_address + p] = tb_write_grad_mag[p];
        test_cases_out_grad_ang[tb_write_start_address + p] = tb_write_grad_ang[p];
      end

      @(negedge tb_clk);
      done = tb_system_done;
    end

    // Wait for output to stabilize.
    @(negedge tb_clk);
    $display("fffrferdone");

  end
  endtask
  
  // Actual test bench process
  initial
  begin : TEST_PROC
    // Initilize all inputs
    tb_n_rst       = 1; // Initially inactive
    tb_en_filter = 0;
    
    // Get away from Time = 0
    #0.1; 
    
    // Chip reset
    // Activate reset
    tb_n_rst = 1'b0; 
    // wait for a few clock cycles
    @(posedge tb_clk);
    @(posedge tb_clk);
    // Release on falling edge to prevent hold time violation
    @(negedge tb_clk);
    // Release reset
    tb_n_rst = 1'b1; 
    // Add some space before starting the test case
    @(posedge tb_clk);
    @(posedge tb_clk);
    
    $info("Starting");
    perform_edge_detect();

    $display("Inputs");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++)
        $write("%3d ", test_cases_image[r*width+c]);
      $write("\n");
    end

    $display("Outputs");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++) begin
        $write("%3d ", test_cases_out[r*width+c]);
        $fwrite(fo, "%x:%x;\n", tb_totalpx, (test_cases_out[r*width+c] << 8) + (test_cases_out[r*width+c] << 16) + (test_cases_out[r*width+c] & 24'h0000FF));
	tb_totalpx = tb_totalpx + 1;
      end
      $write("\n");
    end
/*
    $display("Expected Outputs");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++)
        $write("%3d ", test_cases_exp_out[r*width+c]);
      $write("\n");
    end
*/
    /*$display("Blur");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++)
        $write("%3d ", test_cases_out_blur[r*width+c]);
      $write("\n");
    end

    $display("Gradient_Mag");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++)
        $write("%3d ", test_cases_out_grad_mag[r*width+c]);
      $write("\n");
    end

    $display("Gradient_Ang");
    for (int r = 0; r < width; r++)
    begin
      for (int c = 0; c < width; c++)
        case (test_cases_out_grad_ang[r*width+c])
          0: $write("  - ");
          1: $write("  / ");
          2: $write("  | ");
          3: $write("  \\ ");
        endcase

      $write("\n");
    end*/

    error_count = 0;
    for (int c = 0; c < width*height; c++)
    begin
      assert(test_cases_out[c] == test_cases_exp_out[c])
      else
      begin
        error_count = error_count + 1;
      end
    end 
   // $info("Test case completed with %0d mismatched pixels out of %0d total \
   //   pixels", error_count, width * height);
	$info("Done");   
    #(300000);
   // $display("reconstrucnting");
    $system("bash reconstructX.sh");    
      $fclose(fo);

  end
endmodule
