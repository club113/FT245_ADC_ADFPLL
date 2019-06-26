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
parameter  DATA_WIDTH = 11 - 1,//data[10:0]
  SAMPLING_NUM = 11'd2047,
  ADDRESS_INIT_VALUE = 11'd0,
  ADDRESS_ONE = 11'd1 
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
wire [31:0]RamReadData;
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

localparam  [3:0]
DARA_R16 = 4'd0,
DATA_START = 4'd1,
DATA_L8 = 4'd2,   //  UART send  bit[0:7]
DATA_L8_WAIT = 4'd3, 
DATA_H8 = 4'd4,   //  UART send  bit[8:15]
DATA_H8_WAIT = 4'd5,
DATA_HL8 = 4'd6,
DATA_HL8_WAIT = 4'd7,
DATA_HH8 = 4'd8,
DATA_HH8_WAIT= 4'd9;
//UART signal
wire BaudTick_Rx,BaudTickTx;
wire [7:0]DataRx;
reg  [7:0]DataTx,DataTx_next;
(* KEEP="TRUE"*) reg  UartTxEn,UartTxEn_next;
(* KEEP="TRUE"*)  wire RxDone;
(* KEEP="TRUE"*)  wire TxDone;

//UArt Send Data parameter
//(* KEEP="TRUE"*) reg [15:0]RamReadDataStore;// save the data 16bits

(* KEEP="TRUE"*) reg [3:0]UartSendStaus,UartSendStaus_next;// DATA_L8 or DATA_H8

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
		
//ADF4350 PLL setting interface	
wire ADF_CFG_DONE;
reg ADF_FreqCfgEnable,ADF_FreqCfgEnableNext;
reg [23:0]ADF_RF_FREQ,ADF_RF_FREQ_next; //units KHz
ADF_APP RF_LO_CFG(

    .CLK(CLK_50MHZ),
    .RST(RST),
	.CFG_EN(ADF_FreqCfgEnable),     //Config enable       
	.FREQ(ADF_RF_FREQ), //target frequency  unit = KHz
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
	.RF_SW_CTL(RF_SW_CTL),
	.CFG_DONE_FLAG(ADF_CFG_DONE)  //if done is high, the ADF4351 has  been set

);
		
		

//UART CMD parse
(* KEEP="TRUE"*) reg [2:0]ReadRamStatus;
reg [2:0]ReadRamStatus_next;

always@(posedge CLK, negedge RST)
begin
	if(!RST)
		begin
			ReadRamStatus <= IDLE_STATUS;
			UartTxEn <= 0;
			UartSendStaus <= IDLE_STATUS;
			UserEnADC <= 1'd0;
			RamReadAddr<= ADDRESS_INIT_VALUE;
			
			Divider <= 0;
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
			RamReadAddr_next = ADDRESS_INIT_VALUE;
			UartSendStaus_next = DARA_R16; // read 16bits data
			end
		end
	READ_STATUS:
		begin
			case(UartSendStaus)
			
				DARA_R16:
					begin
					UartSendStaus_next = DATA_START;
					end
				DATA_START:
					begin					
					UartSendStaus_next = DATA_L8_WAIT;
					end
					
				DATA_L8_WAIT:
					begin
						if(!TxValid)
							begin
							DataTx_next[7:0] = RamReadData[7:0];
							UartTxEn_next = 1'd1;
							UartSendStaus_next = DATA_L8;
							end
					end				

				
				DATA_L8:
					begin
					if(TxDone)
						begin
						UartSendStaus_next = DATA_H8_WAIT;
						end
					end
				DATA_H8_WAIT:
					begin
					if(!TxValid)
						begin
						DataTx_next[7:0] = RamReadData[15:8];
						UartTxEn_next = 1'd1;
						UartSendStaus_next = DATA_H8;
						end
					end 	
				DATA_H8:
					begin

						if(TxDone)
							begin
							UartSendStaus_next = DATA_HL8_WAIT;								
							end
					end
				DATA_HL8_WAIT:
					begin
							if(!TxValid)
							begin
							DataTx_next[7:0] = RamReadData[23:16];
							UartTxEn_next = 1'd1;
							UartSendStaus_next = DATA_HL8;
							end
					end
				DATA_HL8:
					begin
							if(TxDone)
							begin
							UartSendStaus_next = DATA_HH8_WAIT;								
							end
					end
				DATA_HH8_WAIT:
					begin
						if(!TxValid)
							begin
							DataTx_next[7:0] = RamReadData[31:24];
							UartTxEn_next = 1'd1;
							UartSendStaus_next = DATA_HH8;
							end
					
					end
				DATA_HH8:					
					begin
						if(TxDone)
							begin

							UartSendStaus_next = DARA_R16;
							
							if(RamReadAddr == SAMPLING_NUM)
								begin
								ReadRamStatus_next = ENDD_STATUS;
								end
							else	
								begin
								RamReadAddr_next = RamReadAddr_next + ADDRESS_ONE;
								end
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

/**** parse UART CMD ******/
reg [39:0]RxFrameReg,RxFrameRegNext;
reg [3:0]UartRxStatusReg,UartRxStatusRegNext; //define the status register
localparam [3:0] //define UART FRAME format
UART_RX_STATUS_IDLE =  4'd0, //start of frame
UART_RX_STATUS_START = 4'd1, //start of frame
UART_RX_STATUS_CMD   = 4'd2,  // command of frame
UART_RX_STATUS_DATA0 = 4'd3,  //if set CLK only DATA0 is value.
UART_RX_STATUS_DATA1 = 4'd4,  //if set frequency data[2:0] is value.
UART_RX_STATUS_DATA2 = 4'd5,
UART_RX_STATUS_DATA3 = 4'd6,
UART_RX_STATUS_END = 4'd7,    // set PLL and start ADC
UART_RX_STATUS_PLL_WAIT = 4'd10; // if CMD if set_freq, it should wait ADF writing completed

localparam [3:0] // define UART RX CMD 
CMD_START_ADC    = 4'd1,
CMD_POLL_STATUS  = 4'd2,
CMD_SET_ADF_FREQ = 4'd3,
CMD_SIMPING_CLK  = 4'd4;
always@(posedge CLK, negedge RST)
begin
	if(!RST)
		begin
		UartRxStatusReg <= UART_RX_STATUS_IDLE; 
		
		ADF_FreqCfgEnable <= 1'd0;
	    end
	else
		begin
		UartRxStatusReg <= UartRxStatusRegNext;
		
		RxFrameReg  <= RxFrameRegNext;// for UART RX DATA store
		
		ADF_FreqCfgEnable <= ADF_FreqCfgEnableNext;
		end
end //always

always@*
begin
Divider_next = Divider; // F_div = CLK/ 2(n+1):  n= 0  50Mhz, n = 1, 

UserEnADC_next = 1'd0;
ADF_FreqCfgEnableNext = 1'd0; //used to enable CFG_ADF 

RxFrameRegNext = RxFrameReg;
UartRxStatusRegNext  = UartRxStatusReg; 
ADF_RF_FREQ_next = ADF_RF_FREQ; //used for setting ADF4350 frequency
	
	case(UartRxStatusReg)
	UART_RX_STATUS_IDLE:
	    begin
		if(RxDone)
			begin
			UartRxStatusRegNext = UART_RX_STATUS_START;
			end
		else
			begin
			UartRxStatusRegNext = UART_RX_STATUS_IDLE;
			end
		end
	UART_RX_STATUS_START:
		begin
			if(DataRx == 8'HFE)// start of frame
				begin
				UartRxStatusRegNext	= UART_RX_STATUS_CMD;
				end
			else
				begin
				UartRxStatusRegNext = UART_RX_STATUS_IDLE;
				end
		end
	UART_RX_STATUS_CMD:
		begin
			if(RxDone)
				begin
				RxFrameRegNext[7:0] = DataRx;
				UartRxStatusRegNext = UART_RX_STATUS_DATA0;
				end
		end
		UART_RX_STATUS_DATA0:
		begin
			if(RxDone)
				begin
				RxFrameRegNext[15:8] = DataRx;
				UartRxStatusRegNext = UART_RX_STATUS_DATA1;
				end
		end
		UART_RX_STATUS_DATA1:
		begin
			if(RxDone)
				begin
				RxFrameRegNext[23:16] = DataRx;
				UartRxStatusRegNext = UART_RX_STATUS_DATA2;
				end
		end
		UART_RX_STATUS_DATA2:
		begin
			if(RxDone)
				begin
				RxFrameRegNext[31:24] = DataRx;
				UartRxStatusRegNext = UART_RX_STATUS_DATA3;
				end
		end
		UART_RX_STATUS_DATA3:
		begin
			if(RxDone)
				begin
				RxFrameRegNext[39:32] = DataRx;
				UartRxStatusRegNext = UART_RX_STATUS_END;
				end
		end
		
		UART_RX_STATUS_END: //set PLL and start ADC 		
			begin
			/* CMD parsed */
				case(RxFrameReg[3:0])
				 CMD_START_ADC:
					begin
						if(ReadRamStatus == IDLE_STATUS)
							begin
							UserEnADC_next = 1'd1;
							end
						UartRxStatusRegNext = UART_RX_STATUS_IDLE;
					end
					
				 //CMD_POLL_STATUS:
				 CMD_SIMPING_CLK:
				  begin
					Divider_next[3:0] = RxFrameReg[7:4];
					
					UartRxStatusRegNext = UART_RX_STATUS_IDLE;

				  end
				  
				 CMD_SET_ADF_FREQ:
					begin
					ADF_RF_FREQ_next =  RxFrameReg[31:8];
					ADF_FreqCfgEnableNext = 1;
					
					/* should wait */
					UartRxStatusRegNext = UART_RX_STATUS_PLL_WAIT;
					end
					
				default:
				  begin
				    Divider_next[3:0] =  0;
					UartRxStatusRegNext = UART_RX_STATUS_IDLE;
				  end
				endcase //RxFrameReg[3:0] parse CMD 
			end
			
			UART_RX_STATUS_PLL_WAIT:
			begin
				if(ADF_CFG_DONE )//wait ADF setting done
				begin
				UartRxStatusRegNext = UART_RX_STATUS_IDLE;
				end
		
			end
			
			default:
				begin
				UartRxStatusRegNext = UART_RX_STATUS_IDLE;
				end
			
	endcase
end
		
endmodule
