`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:37:34 04/20/2019
// Design Name:   PLL
// Module Name:   H:/ISE/ISE_PRJ/005 ADC/CLK_TEST.v
// Project Name:  ADC_PARALLEL
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: PLL
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module CLK_TEST;

	// Inputs
	reg CLK_IN1;
	reg RESET;

	// Outputs
	wire CLK_OUT1;
	wire LOCKED;

	// Instantiate the Unit Under Test (UUT)
	PLL uut (
		.CLK_IN1(CLK_IN1), 
		.CLK_OUT1(CLK_OUT1), 
		.RESET(RESET), 
		.LOCKED(LOCKED)
	);

	initial begin
		// Initialize Inputs
		CLK_IN1 = 0;
		RESET = 0;

		// Wait 100 ns for global reset to finish
		#100;
		RESET = 1;
        
		// Add stimulus here
		forever begin
		# 10;
		CLK_IN1 =~CLK_IN1;
		end

	end
      
endmodule

