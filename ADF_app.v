`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:03:32 06/12/2019 
// Design Name: 
// Module Name:    ADF_APP 
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
module ADF_APP(
    input CLK,
    input RST,
	input CFG_EN,     //Config enable       
	input [23:0]FREQ, //target frequency  unit = KHz
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
	output RF_SW_CTL,
	
	output CFG_DONE  //if done is high, the ADF4351 has  been set
    );
	
wire CLK_40MZH;
wire FREQ_CAL_DONE;  //calculate done
reg [5:0]SW_V_reg;
reg CfgDoneReg,CfgDoneRegNext;

reg RF_SW_EN_reg;
reg RF_SW_CTL_reg;

reg REF_CLK_reg;
wire ADF_RF_Done,ADF_LO_Done;
reg ADF_RF_WriteEn,ADF_RF_WriteEn_next; //RF write register enable
reg [31:0]ADF_RF_Data,ADF_RF_DataNext;
reg [31:0]ADF_LO_Data,ADF_LO_DataNext;

wire [31:0]ADF_LO_R0;
wire [31:0]ADF_RF_R0;
wire [31:0]ADF_LO_R4;
wire [31:0]ADF_RF_R4;

localparam [31:0]
LO_ADF_REG0 = 32'H00501f40, //1002MHZ
ADF_REG0 = 32'H00500000,  // 1000MZH
ADF_REG1 = 32'h0800E1A9,//32'H08008051,
ADF_REG2 = 32'h00004E42,//32'H04005FC2,
ADF_REG3 = 32'h000004B3,//32'H000004B3,
ADF_REG4 = 32'h00AC803C,//32'H00AA003C,
ADF_REG5 = 32'H00400005;

reg [2:0]ADF_RF_CFG_Status,ADF_RF_CFG_StatusNext;
localparam [2:0]
CFG_IDLE = 3'd0,
CFG_REG0 = 3'd1,
CFG_REG1 = 3'd2,
CFG_REG2 = 3'd3,
CFG_REG3 = 3'd4,
CFG_REG4 = 3'd5,
CFG_REG5 = 3'd6,
CFG_DONE = 3'd7;


   
 ADF4351 RF_PLL_TRANS(
     .CLK(CLK),
     .RST(RST),
	 .ADF_WEN(ADF_RF_WriteEn), //write enable
	 .WDATA(ADF_RF_Data), //write register
     .ADF_CLK(D_CLK), // SPI data clock
     .ADF_DATA(D_OUT), //data
     .ADF_LE(D_LE),
	 .ADF_WRITE_DONE(ADF_RF_Done)
    );
	
 ADF4351 LO_PLL_TRANS(
     .CLK(CLK),
     .RST(RST),
	 .ADF_WEN(ADF_RF_WriteEn), //write enable
	 .WDATA(ADF_LO_Data), //write register
     .ADF_CLK(LO_D_CLK), // SPI data clock
     .ADF_DATA(LO_D_OUT), //data
     .ADF_LE(LO_D_LE),
	 .ADF_WRITE_DONE(LO_ADF_RF_Done)
    );
	
	
 ADF4351_FREQ RF_FREQ_CAL(
     .RST(RST),
     .CLK(CLK),
	 .CFG_EN(CFG_EN),     //Config enable
     .LO_SET(0),     //LO_SET is high 
	 .FREQ(FREQ), //target frequency  unit = KHz
	 .ADF_R0(ADF_RF_R0),
	 .ADF_R4(ADF_RF_R4),
	 .DONE(FREQ_CAL_DONE)
    );
 ADF4351_FREQ LO_FREQ_CAL(
     .RST(RST),
     .CLK(CLK),
	 .CFG_EN(CFG_EN),     //Config enable
     .LO_SET(1),     //LO_SET is high 
	 .FREQ(FREQ), //target frequency  unit = KHz
	 .ADF_R0(ADF_LO_R0),
	 .ADF_R4(ADF_LO_R4),
	 .DONE(DONE)
    );	
	
	
always@( negedge RST,posedge CLK)
begin

	if(!RST)
		begin
		ADF_RF_Data <= 0;
		ADF_LO_Data <= 0;
		
		ADF_RF_CFG_Status <= CFG_IDLE;
		
		ADF_RF_WriteEn <= 0;
		
		REF_CLK_reg <= 0;
		
		SW_V_reg <= 0;
		
		RF_SW_EN_reg <= 0;
		RF_SW_CTL_reg <= 0;
		
		CfgDoneReg <= 0;
		end
	else
		begin
		ADF_RF_Data <= ADF_RF_DataNext;
		ADF_LO_Data <= ADF_LO_DataNext;
		
		ADF_RF_CFG_Status <= ADF_RF_CFG_StatusNext;
		ADF_RF_WriteEn <= ADF_RF_WriteEn_next;
		
		REF_CLK_reg <= ~REF_CLK_reg; //ADF reference clock
		
		SW_V_reg <= 6'b000001;
		
		RF_SW_EN_reg <= 0;
		RF_SW_CTL_reg <= 0;
		
		CfgDoneReg <= CfgDoneRegNext;
		end
	
end
assign REF_CLK = REF_CLK_reg;
assign SW_V = SW_V_reg;
assign LO_REF_CLK = REF_CLK_reg;
assign RF_SW_EN = RF_SW_EN_reg;
assign RF_SW_CTL = RF_SW_CTL_reg;
assign CFG_DONE = CfgDoneReg; 

always@*
begin
ADF_RF_CFG_StatusNext = ADF_RF_CFG_Status;
ADF_RF_WriteEn_next = 0;
CfgDoneRegNext = 0; // out put flag,ad4351 sot completely
ADF_RF_DataNext = ADF_RF_Data;
ADF_LO_DataNext = ADF_LO_Data;
	case(ADF_RF_CFG_Status)
	
		CFG_IDLE:
			begin
				if(FREQ_CAL_DONE)
				begin
					ADF_RF_CFG_StatusNext = CFG_REG5;
					ADF_RF_DataNext = ADF_REG5;
					ADF_LO_DataNext = ADF_REG5;
					ADF_RF_WriteEn_next = 1;   // enable Write SPI
				end
			end
		CFG_REG5:
			begin
				
				if(ADF_RF_Done)//wait reg5 written over
				begin
				ADF_RF_CFG_StatusNext = CFG_REG4;
				
				ADF_RF_DataNext = ADF_RF_R4; // update setting value
				ADF_LO_DataNext = ADF_LO_R4;
				
				ADF_RF_WriteEn_next = 1;    
				end
			end
		CFG_REG4:
			begin
				if(ADF_RF_Done)
				begin
				ADF_RF_CFG_StatusNext = CFG_REG3;
				ADF_RF_DataNext = ADF_REG3;
				ADF_LO_DataNext = ADF_REG3;
				ADF_RF_WriteEn_next = 1;
				end
			end
		CFG_REG3:
			begin
				if(ADF_RF_Done)
				begin
				ADF_RF_CFG_StatusNext = CFG_REG2;
				ADF_RF_DataNext = ADF_REG2;
				ADF_LO_DataNext = ADF_REG2;
				ADF_RF_WriteEn_next = 1;
				end
			end
		CFG_REG2:
			begin
				if(ADF_RF_Done)
				begin
				ADF_RF_CFG_StatusNext = CFG_REG1;
				ADF_RF_DataNext = ADF_REG1;
				ADF_LO_DataNext = ADF_REG1;
				ADF_RF_WriteEn_next = 1;
				end
			end
		CFG_REG1:
			begin
				if(ADF_RF_Done)
				begin
				ADF_RF_CFG_StatusNext = CFG_REG0;
				ADF_RF_DataNext = ADF_RF_R0;
				ADF_LO_DataNext = ADF_LO_R0;
				ADF_RF_WriteEn_next = 1;
				end
			end
		CFG_REG0:
			begin
				if(ADF_RF_Done)
				begin
				ADF_RF_CFG_StatusNext = CFG_DONE;
				ADF_RF_WriteEn_next = 0;
				end
			end
			
		CFG_DONE:
			begin
			ADF_RF_CFG_StatusNext = CFG_IDLE;
			CfgDoneRegNext = 1;
			end
	endcase


end

endmodule
