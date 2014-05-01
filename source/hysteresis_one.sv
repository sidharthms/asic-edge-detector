// $Id: $
// File name:   hysteresis_one.sv
// Created:     4/30/2014
// Author:      Ryan Beasley
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Hysteresis Function Block

module hysteresis_one
#(
	parameter lowthresh=10,
	parameter upthresh=50
)
(	input wire [1:0] grad_in_angle,
	input wire [4:0] [7:0]  grad_in_mag,
	output reg [7:0] out_pixel
);


always_comb begin
//ANGLE 1
  if(grad_in_angle==0)begin
    if(grad_in_mag[3]==8'b11111111)begin
      if(grad_in_mag[4]>=lowthresh)begin
	grad_in_mag[4] = 8'b11111111;
      end //lowthresh if
      else begin
	grad_in_mag[4] = 8'b00000000;
      end //else lowthresh
    end   //compare if mag
    else begin
      if(grad_in_mag[4]>=upthresh)begin
	grad_in_mag[4]=8'b11111111;
      end //upthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else upthresh
    end   //else compare mag
  end
//ANGLE 1
  else if(grad_in_angle==1)begin
    if(grad_in_mag[2]==8'b11111111)begin
      if(grad_in_mag[4]>=lowthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //lowthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else lowthresh
    end   //compare if mag
    else begin
      if(grad_in_mag[4]>=upthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //upthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else upthresh
    end   //else compare mag
  end
//ANGLE 2 
  else if(grad_in_angle==2)begin
    if(grad_in_mag[1]==8'b11111111)begin
      if(grad_in_mag[4]>=lowthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //lowthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else lowthresh
    end   //compare if mag
    else begin
      if(grad_in_mag[4]>=upthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //upthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else upthresh
    end   //else compare mag
  end
//ANGLE 3
  else if(grad_in_angle==3)begin
    if(grad_in_mag[0]==8'b11111111)begin
      if(grad_in_mag[4]>=lowthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //lowthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else lowthresh
    end   //compare if mag
    else begin
      if(grad_in_mag[4]>=upthresh)begin
        grad_in_mag[4]=8'b11111111;
      end //upthresh if
      else begin
        grad_in_mag[4]=8'b00000000;
      end //else upthresh
    end   //else compare mag
  end//always block
end
endmodule//module 
