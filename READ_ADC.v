`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:32:42 04/13/2019 
// Design Name: 
// Module Name:    READ_ADC 
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
module READ_ADC

#(
parameter  DATA_WIDTH = 9,//data[9:0]
  SAMPLING_NUM = 10'd1023
)

(
    input RST,
    input CLK,
	input SART_TURN,
	input [10:0]DIVIDER,//4+1= 5 divider
    input [11:0]ADC_BIT,
    input ADC_OTR,
    output ADC_CLK,
    output ADC_OE,	
	input [DATA_WIDTH :0]RAM_RD_ADDR,// max address = 1023
	output [15:0]RAM_DATA_OUT,//tow byte
	
	output TURN_DONE //output one clock pulse
    );
	
localparam [1:0]
 IDLE  = 2'b00,
 TURN  = 2'b01,
 ENDD  = 2'b10;


reg [1:0] TurnStatus,TurnStatus_next; // status machine
reg TurnDone_Reg, TurnDone_Reg_next; 
	
reg ADC_OE_REG;	



reg [DATA_WIDTH :0]ReadCounter;// the counter of reading ADC Value
reg [DATA_WIDTH :0]ReadCounter_next;
reg [15:0]ADC_Value;
reg RamEnable;

reg WriteRead,WriteRead_next;// 1:Write ; 0:read

wire ADC_CLK_RSING; // a single to  ADC output update. in this single could change ram address to save last ADC data. 
wire ADC_CLK_FALLING;// 


Divider READ_CLK( .RST(RST),
                  .CLK(CLK),
				  .DIV_FACTOR(DIVIDER), 
				  .DIV_CLK(ADC_CLK),
				  .RISING_EDGE(ADC_CLK_RSING),
				  .FALLING_EDGE(ADC_CLK_FALLING)
				  );
ADC_RAM uut (		
		.clka(CLK), // input 
		.wea(WriteRead), // input [0 : 0]
		.addra(ReadCounter), // input [9 : 0] 

		.dina(ADC_Value), // input [15 : 0] 
		.clkb(CLK), // input 
		.addrb(RAM_RD_ADDR), // input [9 : 0] 
		.doutb(RAM_DATA_OUT) // output [15 : 0] 
		
	);
	

always@(posedge CLK, negedge RST)
begin
	if(!RST)
		begin
//		DiverReg <= 11'd0;
		RamEnable <=  1'd1;
		WriteRead <=  1'd1;
		ReadCounter <= 10'd0;
		TurnStatus	<= IDLE;
		end
	else
		begin

		ReadCounter <= ReadCounter_next;
        TurnStatus  <= TurnStatus_next;
		TurnDone_Reg <= TurnDone_Reg_next;
		WriteRead <= WriteRead_next;
		end

		

end	


always@*
begin
  ReadCounter_next = ReadCounter;

  TurnStatus_next = TurnStatus;
  WriteRead_next = WriteRead;
  
  TurnDone_Reg_next = 1'd0;//only one pulse

  ADC_Value[11:0] = ADC_BIT;// ADC_CLK_FALLING  read ADC should in clock falling edge
  ADC_Value[15:12] = 0;//ReadCounter[3:0];
   case(TurnStatus)
	IDLE:
		begin

		if(SART_TURN)// if coming  a clock pulse
			begin
			TurnStatus_next = TURN;
			WriteRead_next = 1'd1;//Write
			ADC_OE_REG = 1'd0;//ADC output enable
 			end
		else
		 ADC_OE_REG = 1'd1;//ADC output disable
		
		end
		
		
		
	TURN:
		begin
		  ADC_OE_REG = 1'd0;
		
//		  if(ADC_CLK_FALLING)//store data
//		  begin
//			ADC_Value[11:0] = ADC_BIT;// ADC_CLK_FALLING  read ADC should in clock falling edge
//			ADC_Value[15:12] = 0;//ReadCounter[3:0];
//		  end
		  
		  if(ADC_CLK_RSING) //update address
		  begin
			  if(ReadCounter == SAMPLING_NUM)
				begin
				
				TurnStatus_next = ENDD; //data has already been written into ram
				end
			  else
				begin
				ReadCounter_next  = ReadCounter_next + 10'd1;
				end
		   end
		end
	
	ENDD:
		begin
			TurnDone_Reg_next = 1'b1;//out single of TurnDone
			TurnStatus_next = IDLE;
			WriteRead_next = 1'd0;//read
			ADC_OE_REG = 1'd1; //disable read ADC
		    ReadCounter_next =  10'd0;
		end
		
	default:
		begin
			ADC_OE_REG = 1'd1;
		end
	endcase

end


assign ADC_OE = ADC_OE_REG;
assign TURN_DONE = TurnDone_Reg;

endmodule
