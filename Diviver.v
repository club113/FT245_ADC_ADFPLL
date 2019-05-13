`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:57:10 04/13/2019 
// Design Name: 
// Module Name:    Divider 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Divider(
    input RST,
    input CLK,
    input [10:0]DIV_FACTOR, //最大分频 2048, 分频数  N+1
    output DIV_CLK,
	output RISING_EDGE,      //
	output FALLING_EDGE
    );
	
reg DIV_CLK_REG,RISING_EDGE_REG,FALLING_EDGE_REG;
reg [10:0]Counter;

	
always@(posedge CLK ,negedge RST)
begin
  if(!RST)
	 begin
	 DIV_CLK_REG <= 1'b0;
	 Counter <= 11'd0;
	 RISING_EDGE_REG <= 1'b0;
	 FALLING_EDGE_REG <= 1'b0;
	 end
  else
    begin
	if(Counter == DIV_FACTOR)
		begin
		Counter <= 11'd0; 
		DIV_CLK_REG <=~DIV_CLK_REG;
		RISING_EDGE_REG <= (1'b1 & DIV_CLK_REG);
		FALLING_EDGE_REG <= ~(1'b1 & DIV_CLK_REG);
		end
	else
		begin
		Counter <= Counter + 11'd1;
		RISING_EDGE_REG <= 1'b0;
		FALLING_EDGE_REG <= 1'b0;
		end
	
	end

end
assign DIV_CLK = DIV_CLK_REG; 
assign RISING_EDGE = RISING_EDGE_REG;
assign FALLING_EDGE = FALLING_EDGE_REG;

endmodule
