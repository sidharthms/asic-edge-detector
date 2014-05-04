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
  
  reg [7:0]  test_cases_image [900];
  reg [7:0]  test_cases_out [900];
  reg [7:0]  test_cases_out_blur [900];
  reg [7:0]  test_cases_out_grad_mag [900];
  reg [1:0]  test_cases_out_grad_ang [900];
  reg [7:0]  test_cases_exp_out [900];
  reg [15:0] width;
  reg [15:0] height;
 
  bit found_error;

  // Test vector population
  initial
  begin
    for (int i = 0; i < 30; i++)
      for (int j = 0; j < 30; j++)
      begin
        if ((i >= 5 && i < 25) && (j>= 10 && j < 20))
          test_cases_image[j*30+i] = 200;
        else
          test_cases_image[j*30+i] = 30;

        if ((i >= 5 && i < 25) && (j==9 || j==10 || j==19 || j==20))
          test_cases_exp_out[j*30+i] = 255;
        else if ((j >= 9 && j <= 20) && (i==5 || i==24))
          test_cases_exp_out[j*30+i] = 255;
        else
          test_cases_exp_out[j*30+i] = 0;
      end
    width = 30;
    height = 30;
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
    
    @(negedge tb_clk);
    tb_en_filter = 1;
    tb_width = 30;
    tb_height = 30;
    tb_in_start_address = 0;
    tb_out_start_address = 0;
    tb_filter_type = 0;
    tb_io_final = 0;

    @(negedge tb_clk);
    tb_en_filter = 0;

    tb_io_final = 1;
    done = 0;
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
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        $write("%3d ", test_cases_image[r*30+c]);
      $write("\n");
    end

    $display("Outputs");
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        $write("%3d ", test_cases_out[r*30+c]);
      $write("\n");
    end

    $display("Expected Outputs");
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        $write("%3d ", test_cases_exp_out[r*30+c]);
      $write("\n");
    end

    $display("Blur");
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        $write("%3d ", test_cases_out_blur[r*30+c]);
      $write("\n");
    end

    $display("Gradient_Mag");
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        $write("%3d ", test_cases_out_grad_mag[r*30+c]);
      $write("\n");
    end

    $display("Gradient_Ang");
    for (int r = 0; r < 30; r++)
    begin
      for (int c = 0; c < 30; c++)
        case (test_cases_out_grad_ang[r*30+c])
          0: $write("  - ");
          1: $write("  / ");
          2: $write("  | ");
          3: $write("  \\ ");
        endcase

      $write("\n");
    end

    error_count = 0;
    for (int c = 0; c < 900; c++)
    begin
      assert(test_cases_out[c] == test_cases_exp_out[c])
      else
      begin
        error_count = error_count + 1;
      end
    end 
    $info("Test case completed with %0d mismatched pixels out of %0d total \
      pixels", error_count, width * height);
  end
endmodule
