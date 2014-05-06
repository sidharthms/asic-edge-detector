// $Id: $
// File name:   tb_blur_controller.sv
// Created:     4/26/2014
// Author:      Sidharth Mudgal, Akanksha Sharma

`timescale 1ns / 10ps

module tb_nms_controller();

  // Define parameters
  parameter CLK_PERIOD        = 10;
  localparam NUM_TEST_CASES = 10;
  
  integer tb_test_case;
  
  reg tb_clk;
  reg tb_n_rst;
  reg tb_anchor_moving;
  reg [13:0][1:0] tb_gradient_angle;
  reg [13:0][7:0] tb_gradient_mag;
  reg [11:0][7:0] tb_nms_grad_angle;
  reg [11:0][7:0] tb_nms_out;
  reg tb_nms_final;
  
  reg [13:0][1:0] test_cases_angle [NUM_TEST_CASES];
  reg [13:0][7:0] test_cases_mag [NUM_TEST_CASES];
  reg [11:0][7:0] test_cases_nms [NUM_TEST_CASES+1];
 
  bit found_error;

  // Test vector population
  initial
  begin
    for (int i = 0; i < NUM_TEST_CASES/2; i=i+1)
    begin
      for (int j = 0; j < 14; j=j+1)
        test_cases_mag[i][j] = (255*2*i)/NUM_TEST_CASES;
      for (int j = 0; j < 14; j=j+1)
        test_cases_mag[NUM_TEST_CASES/2 + i][j] = (255*2*(NUM_TEST_CASES/2 - i))/NUM_TEST_CASES;
      for (int j = 0; j < 12; j=j+1)
      begin
        test_cases_nms[i + 1][j] = 0;
        test_cases_nms[NUM_TEST_CASES/2 + i + 1][j] = 255 * (i == 0);
      end

      for (int j = 0; j < 14; j=j+1)
      begin
        test_cases_angle[i][j] = 2;
        test_cases_angle[NUM_TEST_CASES/2 + i][j] = 2;
      end
    end
  end

  nms_controller DUT(
    tb_clk,
    tb_n_rst,
    tb_anchor_moving,
    tb_gradient_angle,
    tb_gradient_mag,
    tb_nms_grad_angle,
    tb_nms_out,
    tb_nms_final);
  
  always
  begin : CLK_GEN
    tb_clk = 1'b0;
    #(CLK_PERIOD / 2);
    tb_clk = 1'b1;
    #(CLK_PERIOD / 2);
  end

  task perform_nms;
    input [13:0][1:0] gradient_angle;
    input [13:0][7:0] gradient_mag;

    bit done;
  begin
    
    @(negedge tb_clk);
    tb_anchor_moving = 1;
    tb_gradient_angle = gradient_angle;
    tb_gradient_mag = gradient_mag;

    @(negedge tb_clk);
    tb_anchor_moving = 0;

    done = 0;
    while (~done)
    begin
      @(negedge tb_clk);
      done = tb_nms_final;
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
      perform_nms(test_cases_angle[tb_test_case],
          test_cases_mag[tb_test_case]);

      if (tb_test_case != 0)
      begin
        assert(tb_nms_out == test_cases_nms[tb_test_case])
        else
        begin
          found_error = 1;
          $error("Test case %0d: ---INCORRECT--- exp=%0d, res=%0d",
              tb_test_case, test_cases_nms[tb_test_case], tb_nms_out);
        end
      end
    end 
    if (!found_error)
      $info("%0d Test cases completed without any errors :)", NUM_TEST_CASES);
  end
endmodule
