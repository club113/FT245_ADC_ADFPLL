`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:40:17 05/27/2019 
// Design Name: 
// Module Name:    Countor 
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
module COUNTER
#(
parameter THRESHOLD = 8'd79,
QUADRATURE_START = 8'd20 // 1/4
)
(
    input RST,
    input CLK,
    output [7:0] SIN_COUNTER,
	output [7:0] COS_COUNTER
    );
	
reg [7:0] SinCountorReg;
reg [7:0] CosCountorReg;	
always@(posedge CLK,negedge RST)
begin
	if(!RST)
		begin
			SinCountorReg = 0;
			CosCountorReg = QUADRATURE_START;
		end
	else
		begin
		   if(SinCountorReg == THRESHOLD)
				begin 
					SinCountorReg = 0;
				end
			else
				begin
					SinCountorReg =  SinCountorReg + 8'd1;
				end
			
		   if(CosCountorReg == THRESHOLD)
				begin
				   CosCountorReg =0;
				end
			else
				begin
				  CosCountorReg =  CosCountorReg + 8'd1;
				end
				
		end		



end
assign SIN_COUNTER = SinCountorReg;
assign COS_COUNTER = CosCountorReg;
endmodule
