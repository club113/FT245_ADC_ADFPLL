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
  SAMPLING_NUM = 10'd1023
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
wire [15:0] RamReadData;
(* KEEP="TRUE"*) wire  TurnDone;// it could output one clock time pulse, to trigger reading event
READ_ADC  ReadADCValue(
    .RST(RST),
    .CLK(CLK),
	.SART_TURN(StartTurn),
	.DIVIDER(Divider),//ADC CLK Divider
    .ADC_BIT(ADC_BIT),
    .ADC_OTR(ADC_OTR),
    .ADC_CLK(ADC_CLK),
    .ADC_OE(ADC_OE),
	
	.RAM_RD_ADDR( RamReadAddr ),// max address = 1023
	.RAM_DATA_OUT( RamReadData ),//tow byte
	
	.TURN_DONE(TurnDone)//output one clock pulse
    );

	
//UART Section
localparam [2:0] //
IDLE_STATUS = 3'd0,
STAR_STATUS = 3'd1,
WAIT_STATUS = 3'd2, //wait read numbers of value data
FFT_INPUT_STATUS  = 3'd3,
START_FFT_STATUS= 3'd4,
WAIT_FFT_STATUS = 3'd5,
READ_STATUS = 3'd7,
ENDD_STATUS = 3'd7;

localparam  [2:0]
DATA_READ = 3'd0,//read data from RAM
DATA_PROCESS_START = 3'd1,//en calculate
DATA_PROCESS_WAIT = 3'd2,//wait calculate completed
DATA_START = 3'd3,
DATA_LL8 = 3'd4,   //  UART send  bit[0:7]
DATA_LH8 = 3'd5,   //  UART send  bit[8:15]
DATA_HL8 = 3'd6,   //  UART send  bit[16:23]
DATA_HH8 = 3'd7;   //  UART send  bit[24:31]

//UART signal
wire BaudTick_Rx,BaudTickTx;
wire [7:0]DataRx;
reg  [7:0]DataTx;
(* KEEP="TRUE"*) reg  UartTxEn,UartTxEn_next;
(* KEEP="TRUE"*)  wire RxDone;
(* KEEP="TRUE"*)  wire TxDone;

//UArt Send Data parameter
//(* KEEP="TRUE"*) reg [15:0]RamReadDataStore;// save the data 16bits
(* KEEP="TRUE"*) reg [2:0]UartSendStaus,UartSendStaus_next;// DATA_L8 or DATA_H8


//UART CMD parse parameter
//reg [7:0] UartRxDataStore;
//reg UartCmdParseStatus,UartCmdParseStatus_next;
(* KEEP="TRUE"*) reg  UserEnADC,UserEnADC_next; //UAERT CMD 


	
FT245RL UART1(
			   .CLK(CLK),
               .RST(RST),
	
	.TXEN(UartTxEn_next), // to enable tx_data
	.TX_VALID(TX_VALID),// if tx_valid is high the, the IC is sending busy or buffer being full 
	.TX_DONE(TxDone),
	.TX_DATA(DataTx), //245 send data

	.RX_DONE(RxDone), //if have received a bytes, it will give a high pulse 
	.RX_DATA(DataRx),// 245 received data

	
		.TXE(TXE),  //hard ware interface 
		.RXF(RXF),
		.WR(WR),
		.RD(WR),			
		.DATA_IO(DATA_IO)
    );
	
reg Divider_InValid,Divider_InValid_next;// enable or disable input
reg FFT_OutReady,FFT_OutReady_next;//clear flag
wire FFT_OUT_VALID; // if calculate is completed, it will become high
reg  [15:0]SubAdd_InData,SubAdd_InData_next;//int16
wire DividerNextInput; //if  NextInput, could input next 16bits data. gave SubAdd_InValid a signal

reg  FFT_Start,FFT_Start_next;// a clock pulse to enable the FFT
wire [63:0]FFT_OutData;//single float
wire FFT_OutData_Last;//a flag of reading  the last FFT data out

 MathProcess DataProcess(
			   .CLK(CLK),
               .RST(RST),
			   .IN_VALID(Divider_InValid),// input a clock high signal to enable calculate.
				.DATA_IN(SubAdd_InData),
				
				.DIVIDER_INPUT_VALID( DividerNextInput ),//should in put next data
				
				.FFT_OUT_VALID(FFT_OUT_VALID), // if this single is high, read the DATA_OUT
				.RESUALT_READY(FFT_OutReady),//clear  "SubAdd_OutValid" flag 
				
				.START_FFT( FFT_Start ), //start FFT
				.FFT_DATA_OUT(FFT_OutData),// reg = [31:0], imaginary = [63:32]
				.FFT_DATA_OUT_TLAST(FFT_OutData_Last)
	);

//UART CMD parse
reg [2:0]ReadRamStatus;
reg [2:0]ReadRamStatus_next;

always@(posedge CLK, negedge RST)
begin
	if(!RST)
		begin
			ReadRamStatus <= IDLE_STATUS;
			//UartTxEn <= 0;
			UartSendStaus <= IDLE_STATUS;
			UserEnADC <= 1'd0;
			RamReadAddr<= 10'd0;
			
			Divider <= 1;//ADC CLK Divider
			
			Divider_InValid <= 0;
			SubAdd_InData <= 16'd0;
			
			FFT_OutReady <= 1'b0;
			

			FFT_Start <= 0;
	
		end
	else
		begin
			ReadRamStatus <= ReadRamStatus_next;
			UartSendStaus <= UartSendStaus_next;
			//UartTxEn <= UartTxEn_next;
			UserEnADC <= UserEnADC_next; // UART-CMD to EN ADC
			RamReadAddr <= RamReadAddr_next; // read address ++
			StartTurn <= StartTurn_next; // enable ADC 
			
			Divider <= Divider_next;//ADC CLK Divider
			
			Divider_InValid <= Divider_InValid_next;
	
			FFT_OutReady <= FFT_OutReady_next;	

			FFT_Start <= FFT_Start_next;
		end
	
end


always@*
begin
	ReadRamStatus_next = ReadRamStatus;
	UartSendStaus_next = UartSendStaus;
	RamReadAddr_next   = RamReadAddr;
	SubAdd_InData_next = SubAdd_InData;
	
	StartTurn_next = 1'd0; // rest	
	UartTxEn_next = 1'd0;
	Divider_InValid_next = 1'b0;//disable input of SubAdd
	FFT_OutReady_next = 1'b0;//clear math_process_out flag
	
	FFT_Start_next = 0;
	
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
			ReadRamStatus_next = FFT_INPUT_STATUS;
			RamReadAddr_next = 10'd0;
			Divider_InValid_next = 1'd1;

			end
		end

	FFT_INPUT_STATUS:
		begin //wait FFT completed
		
		if(DividerNextInput)
			begin

			if(RamReadAddr == SAMPLING_NUM)//reach the max numbers
				begin
				ReadRamStatus_next = START_FFT_STATUS;
				
				
				end
			Divider_InValid_next = 1'd1;	
			RamReadAddr_next = RamReadAddr_next + 10'd1;//update  address of RAM
			end

			
		end
		
	START_FFT_STATUS:
		begin
		   if(DividerNextInput)
			begin
				//start the FFT
				FFT_Start_next = 1;
			end
		end	
	WAIT_FFT_STATUS:
		begin
		if(FFT_OUT_VALID)
			begin
			ReadRamStatus_next = READ_STATUS;
			UartSendStaus_next = DATA_READ; // read 16bits data
			end
		end
	READ_STATUS:
		begin
			case(UartSendStaus)
			
				DATA_READ:
					begin

					UartSendStaus_next = DATA_START;

					end
					
					
				DATA_START:
					begin
						DataTx[7:0] = FFT_OutData[7:0];
						UartTxEn_next = 1'd1;						
						UartSendStaus_next = DATA_LL8;
					end
					
				DATA_LL8:
					begin
					if(TxDone)
						begin
						DataTx[7:0] = FFT_OutData[15:8];
						UartTxEn_next = 1'd1;
						UartSendStaus_next = DATA_LH8;
						end
					end
				DATA_LH8:
					begin
					if(TxDone)
						begin
						DataTx[7:0] = FFT_OutData[23:16];
						UartTxEn_next = 1'd1;
						UartSendStaus_next = DATA_HL8;
						end
					end
				DATA_HL8:
					begin
					if(TxDone)
						begin
						DataTx[7:0] = FFT_OutData[31:24];
						UartTxEn_next = 1'd1;
						UartSendStaus_next = DATA_HH8;
						end
					end
				DATA_HH8:
					begin

						if(TxDone)
							begin
							UartSendStaus_next = DATA_READ;
							FFT_OutReady_next = 1'b1; //update FFT data out
							
							end
						if(FFT_OutData_Last)
							begin
							ReadRamStatus_next = ENDD_STATUS;
							end
				
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
			  Divider_next[3:0] =  1;
			  end
			endcase 
		end

end
		
endmodule
