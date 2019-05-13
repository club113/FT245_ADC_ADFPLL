`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:44:17 04/20/2019
// Design Name:   CLOCKING
// Module Name:   H:/ISE/ISE_PRJ/005 ADC/ADC_PARALLEL/ClockingTest.v
// Project Name:  ADC_PARALLEL
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: CLOCKING
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ClockingTest;

	// Inputs
	reg RST;
	reg CLK;
	reg ADC_OTR;
	reg [11:0] ADC_BIT;
	reg UART_RX;

	// Outputs
	wire ADC_CLK;
	wire ADC_OE;
	wire UART_TX;

	// Instantiate the Unit Under Test (UUT)
	CLOCKING uut (
		.RST(RST), 
		.CLK(CLK), 
		.ADC_OTR(ADC_OTR), 
		.ADC_BIT(ADC_BIT), 
		.ADC_CLK(ADC_CLK), 
		.ADC_OE(ADC_OE), 
		.UART_RX(UART_RX), 
		.UART_TX(UART_TX)
	);

	initial begin
		// Initialize Inputs
		RST = 0;
		CLK = 0;
		ADC_OTR = 0;
		ADC_BIT = 2019;
		UART_RX = 1;

		// Wait 100 ns for global reset to finish
		#100;
        RST = 1;
		// Add stimulus here
		forever begin
		#10;
		CLK =!CLK;
		end
		
end	
	
initial
begin

//模拟串口输入0x01
	#300;
	
	UART_RX = 0;
	#1000;
	
	UART_RX = 1;
	#1000;
	
		
	UART_RX = 0;
	#7000;
	
	UART_RX = 1;
	
	#2000;
	
	
end


	

      
endmodule

