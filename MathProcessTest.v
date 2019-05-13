`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:47:13 04/27/2019
// Design Name:   MathProcess
// Module Name:   H:/ISE/ISE_PRJ/005 ADC/MathProcessTest.v
// Project Name:  ADC_PARALLEL
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: MathProcess
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module MathProcessTest;

	// Inputs
	reg CLK;
	reg RST;
	reg [15:0] DATA_IN;
	reg IN_VALID;
	reg RESUALT_READY;
	reg START_FFT;
	reg FFT_RST;
	reg wait_stat_fram;
	
	reg [15:0]InputCnt;

	// Outputs
	wire DIVIDER_INPUT_VALID;
	wire FFT_OUT_VALID;
	wire [63:0] FFT_DATA_OUT;
	wire FFT_DATA_OUT_TLAST;
	wire EVT_FRAME_STARTED;

	// Instantiate the Unit Under Test (UUT)
	MathProcess uut (
		.CLK(CLK), 
		.RST(RST), 
		.FFT_RST(FFT_RST),
		.DATA_IN(DATA_IN), 
		.IN_VALID(IN_VALID), 
		.DIVIDER_INPUT_VALID(DIVIDER_INPUT_VALID), 
		.FFT_OUT_VALID(FFT_OUT_VALID), 
		.RESUALT_READY(RESUALT_READY), 
		.START_FFT(START_FFT), 
		.FFT_DATA_OUT(FFT_DATA_OUT), 
		.FFT_DATA_OUT_TLAST(FFT_DATA_OUT_TLAST),
		.EVT_FRAME_STARTED(EVT_FRAME_STARTED)
	);

	initial begin
		// Initialize Inputs
		CLK = 0;
		RST = 0;
		DATA_IN = 0;
		IN_VALID = 0;
		RESUALT_READY = 1;
		START_FFT = 1;
		FFT_RST = 1;
		wait_stat_fram = 0;
		// Wait 100 ns for global reset to finish
		#100;
		RST = 1;
		FFT_RST = 0;
        DATA_IN = 0;
		InputCnt = 0;
		IN_VALID = 1;
		// Add stimulus here
		START_FFT = 0;
		RESUALT_READY = 0; 
		forever begin
			#5;
			CLK=~CLK;
			
			if(CLK) //posedge
			 begin

				IN_VALID = 0;// keep low
				
				if(EVT_FRAME_STARTED)
					wait_stat_fram  =1;
				
				if(DIVIDER_INPUT_VALID & wait_stat_fram)
					begin

					
					IN_VALID = 1;// give a circle high

					if(InputCnt < 16)
						begin
						DATA_IN = DATA_IN +1;//change the input data
						end
						
					InputCnt = InputCnt + 1;
					end

				

				//RESUALT_READY = 1;//keep high
				//if(FFT_OUT_VALID)//it may high all time in data valid
					//RESUALT_READY = ~RESUALT_READY; // give a high pulse the FFT will output a data
				
			 end
		end

	end
	
      
endmodule

