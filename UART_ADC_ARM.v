`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:20:11 04/13/2019 
// Design Name: 
// Module Name:    UART_ADC_ARM 
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
module UART_ADC_ARM
#(
parameter  DATA_WIDTH = 10 - 1,//data[9:0]
  SAMPLING_NUM = 10'd1000
)

(
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
	
//CLK = 100Mhz
/*wire CLK;
	
PLL instance_name
   (// Clock in ports
    .CLK_IN1(CLK_50M),      // IN
    // Clock out ports
    .CLK_OUT1(CLK));    // OUT*/
	
	
reg[10:0] Divider,Divider_next;
(* KEEP="TRUE"*)reg   StartTurn,StartTurn_next;
(* KEEP="TRUE"*) reg  [DATA_WIDTH:0]RamReadAddr, RamReadAddr_next;
wire [15:0]RamReadData;
(* KEEP="TRUE"*) wire  TurnDone;// it could output one clock time pulse, to trigger reading event
READ_ADC  ReadADCValue(
    .RST(RST),
    .CLK(CLK),
	.SART_TURN(StartTurn),
	.DIVIDER(Divider),
    .ADC_BIT(ADC_BIT),
    .ADC_OTR(ADC_OTR),
    .ADC_CLK(ADC_CLK),
    .ADC_OE(ADC_OE),
	
	.RAM_RD_ADDR(RamReadAddr),// max address = 1023
	.RAM_DATA_OUT(RamReadData),//tow byte
	
	.TURN_DONE(TurnDone)//output one clock pulse
    );

	
//UART Section
localparam [2:0] //
IDLE_STATUS = 3'd0,
STAR_STATUS = 3'd1,
WAIT_STATUS = 3'd2, //wait read numbers of value data
READ_STATUS = 3'd3,
ENDD_STATUS = 3'd4;

localparam  [2:0]
DARA_R16 = 3'd0,
DATA_START = 3'd1,
DATA_L8 = 3'd2,   //  UART send  bit[0:7]
DATA_L8_WAIT = 3'd3, 
DATA_H8 = 3'd4,   //  UART send  bit[8:15]
DATA_H8_WAIT = 3'd5;
//UART signal
wire BaudTick_Rx,BaudTickTx;
wire [7:0]DataRx;
reg  [7:0]DataTx,DataTx_next;
(* KEEP="TRUE"*) reg  UartTxEn,UartTxEn_next;
(* KEEP="TRUE"*)  wire RxDone;
(* KEEP="TRUE"*)  wire TxDone;

//UArt Send Data parameter
(* KEEP="TRUE"*) reg [15:0]RamReadDataStore;// save the data 16bits

(* KEEP="TRUE"*) reg [2:0]UartSendStaus,UartSendStaus_next;// DATA_L8 or DATA_H8

//UART CMD parse parameter
//reg [7:0] UartRxDataStore;
//reg UartCmdParseStatus,UartCmdParseStatus_next;
(* KEEP="TRUE"*) reg  UserEnADC,UserEnADC_next; //UAERT CMD 
(* KEEP="TRUE"*) wire TxValid;	
FT245RL UART1(
			   .CLK(CLK),
               .RST(RST),
	
	.TXEN(UartTxEn), // to enable tx_data
	.TX_VALID(TxValid),// if tx_valid is high the, the IC is sending busy or buffer being full 
	.TX_DONE(TxDone),
	.TX_DATA(DataTx), //245 send data

	.RX_DONE(RxDone), //if have received a bytes, it will give a high pulse 
	.RX_DATA(DataRx),// 245 received data

	
		.TXE(TXE),  //hard ware interface 
		.RXF(RXF),
		.WR(WR),
		.RD(RD),			
		.DATA_IO(DATA_IO)
    );
		


//UART CMD parse
reg [2:0]ReadRamStatus;
reg [2:0]ReadRamStatus_next;

always@(posedge CLK, negedge RST)
begin
	if(!RST)
		begin
			ReadRamStatus <= IDLE_STATUS;
			UartTxEn <= 0;
			UartSendStaus <= IDLE_STATUS;
			UserEnADC <= 1'd0;
			RamReadAddr<= 10'd0;
			
			Divider <= 3;
			DataTx  <= 8'd0;
		end
	else
		begin
			ReadRamStatus <= ReadRamStatus_next;
			UartSendStaus <= UartSendStaus_next;
			UartTxEn <= UartTxEn_next;
			UserEnADC <= UserEnADC_next; // UART-CMD to EN ADC
			RamReadAddr <= RamReadAddr_next; // read address ++
			StartTurn <= StartTurn_next; // enable ADC 
			
			Divider <= Divider_next;
			
			DataTx  <= DataTx_next;
		end
	
end


always@*
begin
	ReadRamStatus_next = ReadRamStatus;
	UartSendStaus_next = UartSendStaus;
	RamReadAddr_next   = RamReadAddr;
	DataTx_next = DataTx;
	
	StartTurn_next = 1'd0; // rest	
	UartTxEn_next = 1'd0;
	
	case(ReadRamStatus)
	
	IDLE_STATUS: //wait CMD of PC sending
		begin
		if(UserEnADC)//a single come from UART, triggering signal
			ReadRamStatus_next = STAR_STATUS; 
		end
	STAR_STATUS:
		begin
	    StartTurn_next = 1'd1;// a clock of plus  to enable ADC 
		ReadRamStatus_next = WAIT_STATUS;
		end
	WAIT_STATUS:
		begin
		if(TurnDone) //wait ADC turning completed
			begin
			ReadRamStatus_next = READ_STATUS;
			RamReadAddr_next = 10'd0;
			UartSendStaus_next = DARA_R16; // read 16bits data
			end
		end
	READ_STATUS:
		begin
			case(UartSendStaus)
			
				DARA_R16:
					begin
					RamReadDataStore = RamReadData;//16bits 
					RamReadAddr_next = RamReadAddr_next + 10'd1;
					UartSendStaus_next = DATA_START;
					end
				DATA_START:
					begin
					DataTx_next[7:0] = RamReadDataStore[7:0];
					UartTxEn_next = 1'd1;						
					UartSendStaus_next = DATA_L8;
					end
					
				DATA_L8:
					begin
					if(TxDone)
						begin
						DataTx_next[7:0] = RamReadDataStore[15:8];
						UartSendStaus_next = DATA_L8_WAIT;
						end
					end
				DATA_L8_WAIT:
					begin
						if(!TxValid)
							begin
							UartTxEn_next = 1'd1;
							UartSendStaus_next = DATA_H8;
							end
					end
				DATA_H8:
					begin

						if(TxDone)
							UartSendStaus_next = DATA_H8_WAIT;
					end
				DATA_H8_WAIT:
					begin
					if(!TxValid)
						begin
							UartTxEn_next = 1'd1;
							UartSendStaus_next = DARA_R16;
							if(RamReadAddr == SAMPLING_NUM)
								ReadRamStatus_next = ENDD_STATUS;
						end
					end
				default:
					begin
					ReadRamStatus_next = ENDD_STATUS;
					end
					
			
			endcase
		end	
	ENDD_STATUS:
		begin
			ReadRamStatus_next = IDLE_STATUS;
		end
	default:
		ReadRamStatus_next = IDLE_STATUS;
		
	endcase
 
end

// parse UART CMD
localparam [3:0] // define UART RX CMD 
CMD_START_ADC    = 4'd1,
CMD_POLL_STATUS  = 4'd2,
CMD_SIMPING_CLK  = 4'd4;


always@*
begin
Divider_next = Divider;

UserEnADC_next = 1'd0;
	if(RxDone)

		begin
		//UserEnADC_next = 1'd1; 
			case(DataRx[3:0])
			 CMD_START_ADC:
				begin
				UserEnADC_next = 1'd1; 
				end
				
			 //CMD_POLL_STATUS:
			 CMD_SIMPING_CLK:
			  begin
			  	Divider_next[3:0] = DataRx[7:4];

			  end
				
			default:
			  begin
			  Divider_next[3:0] =  3;
			  end
			endcase 
		end

end
		
endmodule
