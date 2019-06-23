`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:58:24 06/12/2019 
// Design Name: 
// Module Name:    ADF4351 
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
module ADF4351(
    input CLK,
    input RST,
	input  ADF_WEN, //write enable
	input  [31:0] WDATA, //write register
    output ADF_CLK, // SPI data clock
    output ADF_DATA, //data
    output ADF_LE,
	output ADF_WRITE_DONE
    );

reg  ADF_CLK_reg, ADF_CLK_reg_next;
reg  ADF_DATA_reg, ADF_DATA_reg_next;
reg  ADF_LE_reg,ADF_LE_reg_next;
reg  ADF_WRITE_DONE_reg,ADF_WRITE_DONE_reg_next;
reg [2:0]DataWriteStatus,DataWriteStatus_next;
	
localparam [2:0] 
WRITE_IDLE    = 3'd0,
WRITE_CLK_L   = 3'd1,
WRITE_CLK_DO  = 3'd2,
WRITE_CLK_H   = 3'd3,
WRITE_CLK_ADD = 3'd4,
WRITE_DONE    = 3'd5;

reg [4:0]BitsCntReg,BitsCntReg_next;// write data bits count

always@( negedge RST,posedge CLK)
begin

if(!RST)
	begin
	DataWriteStatus <= WRITE_IDLE;
	ADF_CLK_reg <= 0;
	ADF_DATA_reg <= 0;
	ADF_LE_reg <= 1;
	ADF_WRITE_DONE_reg <= 0;
	BitsCntReg <= 5'd31;
	end
else
	begin
	DataWriteStatus <= DataWriteStatus_next;
	ADF_CLK_reg <= ADF_CLK_reg_next;
	ADF_DATA_reg <= ADF_DATA_reg_next;
	ADF_LE_reg <= ADF_LE_reg_next;
	ADF_WRITE_DONE_reg <= ADF_WRITE_DONE_reg_next;
	
	BitsCntReg <= 	BitsCntReg_next; 
	end

end


always@*
begin

DataWriteStatus_next = DataWriteStatus;
ADF_LE_reg_next = ADF_LE_reg;
ADF_WRITE_DONE_reg_next = 0;
BitsCntReg_next = BitsCntReg;
ADF_DATA_reg_next = ADF_DATA_reg;
	case(DataWriteStatus)
	WRITE_IDLE:
		begin
			if(ADF_WEN)
				begin
				ADF_LE_reg_next = 0;
				DataWriteStatus_next = WRITE_CLK_L;
				end
			else
				begin
				ADF_LE_reg_next = 1;
				end
			ADF_CLK_reg_next = 0;
			
		end
	WRITE_CLK_L:
		begin

		ADF_CLK_reg_next = 0;
		DataWriteStatus_next = WRITE_CLK_DO;
		end
	WRITE_CLK_DO:
		begin
		ADF_DATA_reg_next = WDATA[BitsCntReg]; 
		DataWriteStatus_next = WRITE_CLK_H;
		end	


	WRITE_CLK_H:
		begin
			ADF_CLK_reg_next = 1;
			DataWriteStatus_next = WRITE_CLK_ADD;
		end
	WRITE_CLK_ADD:
		begin
		BitsCntReg_next = BitsCntReg_next - 5'd1;
		
		if(BitsCntReg_next ==  5'd31)
			begin
			DataWriteStatus_next = WRITE_DONE;
			end
		else
			begin
			DataWriteStatus_next = WRITE_CLK_L;
			end
		end
		

	WRITE_DONE:
		begin
		ADF_WRITE_DONE_reg_next = 1;
		DataWriteStatus_next = WRITE_IDLE;
		ADF_CLK_reg_next = 0;
		end
		
	default:
		begin
		DataWriteStatus_next = WRITE_IDLE;
		end
	endcase

end
assign ADF_CLK = ADF_CLK_reg;
assign ADF_DATA = ADF_DATA_reg;
assign ADF_LE = ADF_LE_reg;
assign ADF_WRITE_DONE = ADF_WRITE_DONE_reg; 

endmodule
