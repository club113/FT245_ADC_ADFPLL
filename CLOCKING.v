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
	inout [7:0]DATA_IO,
	
	//ADF4350 PLL interface as  follow
	output D_CLK,
    output D_OUT,
    output D_LE,
    output REF_CLK,
	
	output LO_D_CLK,
    output LO_D_OUT,
    output LO_D_LE,
    output LO_REF_CLK,
	
	output [5:0]SW_V,
	
	output RF_SW_EN,
	output RF_SW_CTL
   
    );
	
//CLK generator
wire CLK_80MHZ;//80MHz
wire CLK_50MHZ;
reg RST_P;

PLL  CLK_Generator (
  // Clock in ports
    .CLK_IN1(CLK),      // IN
    // Clock out ports
    .CLK_OUT1(CLK_80MHZ),   // OUT 100Mhz\
	//.CLK_OUT2(CLK_50MHZ),     // OUT
    // Status and control signals
    .RESET(RST_P)// IN
	
);      // OUT



UART_ADC_ARM ReadADCarm(
		.RST(RST),
		.CLK(CLK_80MHZ),
		.ADC_OTR(ADC_OTR),

	    .ADC_BIT(ADC_BIT),

		.ADC_CLK(ADC_CLK),
		.ADC_OE(ADC_OE),

		.TXE(TXE),  //hard ware interface 
		.RXF(RXF),
		.WR(WR),
		.RD(RD),			
		.DATA_IO(DATA_IO),
		
			//ADF4350 PLL interface as  follow
		.D_CLK(D_CLK),
		.D_OUT(D_OUT),
		.D_LE(D_LE),
		.REF_CLK(REF_CLK),
	
		.LO_D_CLK(LO_D_CLK),
		.LO_D_OUT(LO_D_OUT),
		.LO_D_LE(LO_D_LE),
		.LO_REF_CLK(LO_REF_CLK),
	
		.SW_V(SW_V),
	
		.RF_SW_EN(RF_SW_EN),
		.RF_SW_CTL(RF_SW_CTL)
    );
	


	
always@*
begin
RST_P = !RST;
end


endmodule
