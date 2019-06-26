`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:58:22 06/25/2019 
// Design Name: 
// Module Name:    ADF4351_FREQ 
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
module ADF4351_FREQ(
    input RST,
    input CLK,
	input CFG_EN,     //Config enable
    input LO_SET,     //LO_SET is high 
	input  [23:0]FREQ, //target frequency  unit = KHz
	output [31:0]ADF_R0,
	output [31:0]ADF_R4,
	output  DONE
    );
	
reg [23:0]FreqReg,FreqRegNext;	
//calculate R0 and R4
reg [31:0]FreqintReg,FreqintReg_next;
reg [31:0]FreqfracReg,FreqfracReg_next;
reg [31:0]LO_FreqintReg,LO_FreqintReg_next;
reg [31:0]LO_FreqfracReg,LO_FreqfracReg_next;

reg [2:0]FreqCalStatus,FreqCalStatus_next;
localparam [2:0]
CAL_STATUS_IDLE = 3'd0,
CAL_STATUS_R0_STEP_0 = 3'd1,
CAL_STATUS_R0_STEP_1 = 3'd2,
CAL_STATUS_R0_STEP_2 = 3'd3;

reg [31:0]ADF_R0_reg,ADF_R0_regNext;
reg [31:0]ADF_R4_reg,ADF_R4_regNext;
reg Done_reg,Done_regNext;
always@( negedge RST,posedge CLK)
begin

	if(!RST)
		begin
		ADF_R0_reg <= 32'H00501f40;
		ADF_R4_reg <= 32'h00AC803C;
		FreqCalStatus <= CAL_STATUS_IDLE;
		end
	else
		begin
		ADF_R0_reg <= ADF_R0_regNext;
		ADF_R4_reg <= ADF_R4_regNext;
		FreqCalStatus <= FreqCalStatus_next;
		
		FreqReg <= FreqRegNext;
		end

end
assign ADF_R0 = ADF_R0_reg;
assign ADF_R4 = ADF_R4_reg;
assign DONE = Done_reg;

always@*
begin
ADF_R0_regNext = ADF_R0_reg;
ADF_R4_regNext = ADF_R4_reg;
FreqintReg_next = FreqintReg;
FreqfracReg_next = FreqfracReg;

FreqCalStatus_next = FreqCalStatus;

FreqRegNext = FreqReg;


Done_regNext = 0;
    case(FreqCalStatus)
	
	CAL_STATUS_IDLE: 
		if(CFG_EN)
		begin
		FreqCalStatus_next = CAL_STATUS_R0_STEP_0;
		if(LO_SET)
			begin
			FreqRegNext = FREQ - 2000; // IF = 2MHZ 
			end
		else
			begin
			FreqRegNext = FREQ;
			end
		end
	
	CAL_STATUS_R0_STEP_0:
		begin
		FreqCalStatus_next = CAL_STATUS_R0_STEP_1;
		
		// < 68.75MHZ
		if( (FreqReg > 24'd31999)&&( FreqReg < 24'd68750)) 
			begin
				ADF_R4_regNext = 32'H00EC803C;
				FreqintReg_next = FreqReg << 6;
				FreqfracReg_next =  FreqReg << 3;
			end
			
		//>=68.75mHz &  <137.5mHz
		else if( (FreqReg > 24'd68749)&&( FreqReg < 24'd137500))
		    begin
				ADF_R4_regNext = 32'H00DC803C;
				FreqintReg_next = FreqReg << 5;
				FreqfracReg_next =  FreqReg << 2;
			end
			
		//>=137.5mHz &  <275mHz
		else if( (FreqReg > 24'd137499)&&( FreqReg < 24'd275000))
		    begin
			ADF_R4_regNext = 32'H00CC803C;
			FreqintReg_next = FreqReg << 4;
			FreqfracReg_next =  FreqReg << 1;
			end
			
		//>=275mHz   &  <550mHz
		else if( (FreqReg > 24'd274999)&&( FreqReg < 24'd550000))
		    begin
			ADF_R4_regNext = 32'H00BC803C;
			FreqintReg_next = FreqReg << 3;
			FreqfracReg_next =  FreqReg;
			end
		
		//>=550mHz   &  <1100mHz
		else if( (FreqReg > 24'd549999)&&( FreqReg < 24'd1100000))
		    begin
			ADF_R4_regNext = 32'H00AC803C;
			FreqintReg_next = FreqReg << 2;
			FreqfracReg_next =  FreqReg >> 1;
			end
			
		//>=1100mHz  &  <2200mHz
		else if( (FreqReg > 24'd1099999)&&( FreqReg < 24'd2200000))
		    begin
			ADF_R4_regNext = 32'H009C803C;
			FreqintReg_next = FreqReg << 1;
			FreqfracReg_next =  FreqReg >> 2;
			end
			
		 //>=2200mHz 
		else if( FreqReg > 24'd2199999)
		    begin
			ADF_R4_regNext = 32'H008C803C;
			FreqintReg_next = FreqReg;
			FreqfracReg_next =  FreqReg >> 3;
			end
		else
		    begin
			ADF_R4_regNext = 32'H008C803C;
			FreqintReg_next = FreqReg;
			FreqfracReg_next =  FreqReg >> 3;
			
			end
		end
		
	CAL_STATUS_R0_STEP_1:
		begin
			FreqCalStatus_next = CAL_STATUS_R0_STEP_2;
			FreqintReg_next = FreqintReg_next << 15;
			FreqfracReg_next = FreqfracReg_next << 3;
		end
		
	CAL_STATUS_R0_STEP_2:
		begin
			FreqCalStatus_next = CAL_STATUS_IDLE;
			ADF_R0_regNext = FreqintReg_next | FreqfracReg_next;
			Done_regNext = 1;
		end
	
	default:
		begin
			FreqCalStatus_next = CAL_STATUS_IDLE;
		end
	
	
	endcase

end

endmodule
