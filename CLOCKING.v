`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:22:42 04/20/2019 
// Design Name: 
// Module Name:    CLOCKING 
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
module CLOCKING(

    input RST,
    input CLK,
	input ADC_OTR,
	
	input [11:0]ADC_BIT,
	
    output ADC_CLK,
    output ADC_OE,
	
	input TXE,   
    input RXF,
    output WR,
    output RD,
	inout [7:0]DATA_IO
   
    );
	
//CLK generator
wire CLK_100MHZ;//100MHz
reg RST_P;

PLL  CLK_Generator (
  // Clock in ports
    .CLK_IN1(CLK),      // IN
    // Clock out ports
    .CLK_OUT1(CLK_100MHZ),   // OUT 100Mhz
    // Status and control signals
    .RESET(RST_P)// IN
	
);      // OUT



UART_ADC_ARM ReadADCarm(
		.RST(RST),
		.CLK(CLK_100MHZ),
		.ADC_OTR(ADC_OTR),

	    .ADC_BIT(ADC_BIT),

		.ADC_CLK(ADC_CLK),
		.ADC_OE(ADC_OE),

		.TXE(TXE),  //hard ware interface 
		.RXF(RXF),
		.WR(WR),
		.RD(RD),			
		.DATA_IO(DATA_IO)
    );
	
always@*
begin
RST_P = !RST;
end


endmodule
