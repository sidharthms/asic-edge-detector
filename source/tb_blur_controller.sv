// $Id: $
// File name:   tb_blur_controller.sv
// Created:     4/26/2014
// Author:      Akanksha Sharma

`timescale 1ns / 10ps

module tb_blur_controller();

  // Define parameters
  parameter CLK_PERIOD        = 10;
  localparam NUM_TEST_CASES = 10;
  
  integer tb_test_case;
  
  reg tb_clk;
  reg tb_n_rst;
  reg tb_anchor_moving;
  reg [31:0] tb_anchor_x;
  reg [31:0] tb_anchor_y;
  reg [19:0][7:0] tb_blur_in;
  reg [15:0][7:0] tb_blur_out;
  reg tb_blur_final;
  
  reg [31:0] test_cases_anchor_x [NUM_TEST_CASES];
  reg [31:0] test_cases_anchor_y [NUM_TEST_CASES];
  reg [19:0][7:0] test_cases_blur_in  [NUM_TEST_CASES+4];
  reg [15:0][7:0] test_cases_blur_out [NUM_TEST_CASES];
 
  reg signed [15:0][19:0] expected;
  reg signed [15:0][19:0] result;
  int unsigned sum;
  bit found_error;

  // Test vector population
  initial
  begin
    static byte unsigned mask [5][5]= '{
        '{ 1,  4,  8,  4, 1 },
        '{ 4, 16, 32, 16, 4 },
        '{ 8, 32, 64, 32, 8 },
        '{ 4, 16, 32, 16, 4 },
        '{ 1,  4,  8,  4, 1 }};
      
    for (int i = 0; i < NUM_TEST_CASES; i=i+1)
    begin
      test_cases_anchor_x[i] = i;
      test_cases_anchor_y[i] = 0;
      for (int j = 0; j < 20; j=j+1)
        test_cases_blur_in[i+4][j] = $urandom_range(255);
    end
    for (int i = 0; i < 4; i=i+1)
      test_cases_blur_in[i] = test_cases_blur_in[4];

    // Find 2D Gaussian Blur.
    for (int r = 2; r < NUM_TEST_CASES+4; r=r+1)
      for (int c = 2; c < 18; c=c+1)
      begin
        sum = 0;
        for (int mr = 0; mr < 5; mr=mr+1)
          for (int mc = 0; mc < 5; mc=mc+1)
            sum = sum + mask[mr][mc] * test_cases_blur_in[r+mr-2][c+mc-2];
        test_cases_blur_out[r-2][c-2] = sum/324;
      end
  end

  blur_controller DUT(
    tb_clk,
    tb_n_rst,
    tb_anchor_moving,
    tb_anchor_x,
    tb_blur_in,
    tb_blur_out,
    tb_blur_final);
  
  always
  begin : CLK_GEN
    tb_clk = 1'b0;
    #(CLK_PERIOD / 2);
    tb_clk = 1'b1;
    #(CLK_PERIOD / 2);
  end

  task perform_blur;
    input [31:0] anchor_x;
    input [31:0] anchor_y;
    input [19:0][7:0] blur_in;

    bit done;
  begin
    
    @(negedge tb_clk);
    tb_anchor_moving = 1;
    tb_anchor_x = anchor_x;
    tb_anchor_y = anchor_y;
    tb_blur_in = blur_in;

    @(negedge tb_clk);
    tb_anchor_moving = 0;

    done = 0;
    while (~done)
    begin
      @(negedge tb_clk);
      done = tb_blur_final;
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
    tb_anchor_moving = 0;
    found_error = 0;
    
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
    for(tb_test_case = 0; tb_test_case < NUM_TEST_CASES; tb_test_case++)
    begin
      perform_blur(test_cases_anchor_x[tb_test_case],
          test_cases_anchor_y[tb_test_case],
          test_cases_blur_in[tb_test_case + 4]);

      for (int c = 0; c < 16; c++)
      begin
        expected[c] = test_cases_blur_out[tb_test_case][c];
        result[c] = tb_blur_out[c];
        assert(result[c] >= expected[c] - 9 && result[c] <= expected[c])
        else
        begin
          found_error = 1;
          $error("Test case %0d: ---INCORRECT--- column %0d, exp=%0d, res=%0d",
              tb_test_case, c, expected[c], result[c]);
        end
      end
    end 
    if (!found_error)
      $info("%0d Test cases completed without any errors :)", NUM_TEST_CASES);
  end
endmodule
