// $Id: $
// File name:   tb_gradient_controller.sv
// Created:     4/26/2014
// Author:      Sidharth Mudgal, Akanksha Sharma

`timescale 1ns / 10ps

module tb_gradient_controller();

  // Define parameters
  parameter CLK_PERIOD        = 10;
  localparam NUM_TEST_CASES = 10;
  
  integer tb_test_case;
  
  reg tb_clk;
  reg tb_n_rst;
  reg tb_anchor_moving;
  reg [31:0] tb_anchor_x;
  reg [15:0][7:0] tb_gradient_in;
  reg [13:0][10:0] tb_gradient_x;
  reg [13:0][10:0] tb_gradient_y;
  reg [13:0][1:0] tb_gradient_angle;
  reg [13:0][7:0] tb_gradient_mag;
  reg tb_gradient_final;
  
  reg [31:0] test_cases_anchor_x [NUM_TEST_CASES];
  reg [15:0][7:0] test_cases_gradient_in  [NUM_TEST_CASES+2];
  reg [13:0][10:0] test_cases_gradient_y  [NUM_TEST_CASES];
  reg [13:0][10:0] test_cases_gradient_x  [NUM_TEST_CASES];
  reg unsigned [13:0][7:0] test_cases_gradient_mag [NUM_TEST_CASES];
 
  int expected;
  int result;
  int signed y_sum;
  int signed x_sum;
  int unsigned x;
  int unsigned y;
  bit found_error;

  // Test vector population
  initial
  begin
    static byte signed x_mask [3][3]= '{
        '{ -1, 0, 1 },
        '{ -2, 0, 2 },
        '{ -1, 0, 1 }};
      
    static byte signed y_mask [3][3]= '{
        '{  1,  2,  1 },
        '{  0,  0,  0 },
        '{ -1, -2, -1 }};
      
    for (int i = 0; i < NUM_TEST_CASES; i=i+1)
    begin
      test_cases_anchor_x[i] = i+1;
      for (int j = 0; j < 16; j=j+1)
        test_cases_gradient_in[i+2][j] = $urandom_range(255);
    end
    for (int i = 0; i < 2; i=i+1)
      test_cases_gradient_in[i] = test_cases_gradient_in[2];

    // Find 2D Gradient
    for (int r = 1; r < NUM_TEST_CASES+2; r++)
      for (int c = 1; c < 15; c++)
      begin
        test_cases_gradient_mag[r-1][c-1] = '0;
        x_sum = 0;
        y_sum = 0;
        for (int mr = 0; mr < 3; mr++)
          for (int mc = 0; mc < 3; mc++)
          begin
            x_sum = x_sum + x_mask[mr][mc] * $signed({1'b0,test_cases_gradient_in[r+mr-1][c+mc-1]});
            y_sum = y_sum + y_mask[mr][mc] * $signed({1'b0,test_cases_gradient_in[r+mr-1][c+mc-1]});
          end
        test_cases_gradient_x[r-1][c-1] = x_sum;
        test_cases_gradient_y[r-1][c-1] = y_sum;
        x = x_sum < 0 ? x_sum * (-1) : x_sum;
        y = y_sum < 0 ? y_sum * (-1) : y_sum;
        test_cases_gradient_mag[r-1][c-1] = (x + y) >> 3;
      end
  end

  gradient_controller DUT(
    tb_clk,
    tb_n_rst,
    tb_anchor_moving,
    tb_anchor_x,
    tb_gradient_in,
    tb_gradient_angle,
    tb_gradient_mag,
    tb_gradient_x,
    tb_gradient_y,
    tb_gradient_final);
  
  always
  begin : CLK_GEN
    tb_clk = 1'b0;
    #(CLK_PERIOD / 2);
    tb_clk = 1'b1;
    #(CLK_PERIOD / 2);
  end

  task perform_gradient;
    input [31:0] anchor_x;
    input [15:0][7:0] gradient_in;

    bit done;
  begin
    
    @(negedge tb_clk);
    tb_anchor_moving = 1;
    tb_anchor_x = anchor_x;
    tb_gradient_in = gradient_in;

    @(negedge tb_clk);
    tb_anchor_moving = 0;

    done = 0;
    while (~done)
    begin
      @(negedge tb_clk);
      done = tb_gradient_final;
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
      perform_gradient(test_cases_anchor_x[tb_test_case],
          test_cases_gradient_in[tb_test_case + 2]);

      for (int c = 0; c < 14; c++)
      begin
        expected = test_cases_gradient_mag[tb_test_case][c];
        result = tb_gradient_mag[c];
        assert(result >= expected - 10 && result <= expected + 10)
        else
        begin
          found_error = 1;
          $error("Test case %0d: MAGNITUDE---INCORRECT--- column %0d, exp=%0b, res=%0b, res_o=%0b",
              tb_test_case, c, expected, result, test_cases_gradient_mag[tb_test_case][c]);
        end

        expected = test_cases_gradient_x[tb_test_case][c];
        result = tb_gradient_x[c];
        assert(result >= expected - 10 && result <= expected + 10)
        else
        begin
          found_error = 1;
          $error("Test case %0d: XXXXXX---INCORRECT--- column %0d, exp=%0d, res=%0d",
              tb_test_case, c, expected, result);
        end

        expected = test_cases_gradient_y[tb_test_case][c];
        result = tb_gradient_y[c];
        assert(result >= expected - 10 && result <= expected + 10)
        else
        begin
          found_error = 1;
          $error("Test case %0d: YYYYY---INCORRECT--- column %0d, exp=%0d, res=%0d",
              tb_test_case, c, expected, result);
        end
      end
    end 
    if (!found_error)
      $info("%0d Test cases completed without any errors :)", NUM_TEST_CASES);
  end
endmodule
