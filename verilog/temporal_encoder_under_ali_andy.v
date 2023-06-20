// NEW VERSION OF TEMPORAL ENCODER
`include "const.vh"

module temporal_encoder_under
(
	// global ports
	input Clk_CI, Reset_RI,

	// handshaking
	input ValidIn_SI, ReadyIn_SI,
	output reg ReadyOut_SO, 
	output reg ValidOut_SO,

	// inputs
	input [0:`HV_DIMENSION-1] HypervectorIn_DI,
	
	output [0:`HV_DIMENSION-1] HypervectorOut_DO
);

  reg [0:`HV_DIMENSION-1] ngram [0:`NGRAM_SIZE-1];
  reg [0:`HV_DIMENSION-1] BindNGramOut_D, result;
  reg [1:0] CS, NS;
  
  reg CycleCntrEN_S, CycleCntrCLR_S, AccumulatorEN_S;
  
  reg FirstHypervector_S;
  wire LastChannel_S;

  
  // Cycle (channel) counter
  reg [`ceilLog2(`NGRAM_ACCUM_CYCLE):0] CycleCntr_SP;
  wire [`ceilLog2(`NGRAM_ACCUM_CYCLE):0] CycleCntr_SN;
  
  // FSM state definitions
  localparam IDLE = 0;
  localparam DATA_RECEIVED = 1;
  localparam ACCUM_FED = 2;
  localparam CHANNELS_MAPPED = 3;

  temporal_accumulator_under temporal_accumulator_under(
    .Clk_CI(Clk_CI),
    .Reset_RI(Reset_RI),
    .FirstHypervector_SI(FirstHypervector_S),
    .Enable_SI(AccumulatorEN_S),
    .BindNGramIn_DI(BindNGramOut_D),
    .HypervectorOut_DO(HypervectorOut_DO)
  );
  
  // update NGrams
  integer i;
  always @(posedge Clk_CI) begin
    if (Reset_RI)
      for (i = 0; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= {`HV_DIMENSION{1'b0}};
    else begin
      // ONLY COMPUTE NGRAMS WITH VALID INPUTS
      if (ValidIn_SI == 1'b1) begin
        ngram[0] <= HypervectorIn_DI;
        ngram[1] <= {ngram[0][`HV_DIMENSION-1], ngram[0][0:`HV_DIMENSION-2]};
      end else begin // IF NOT VALID KEEP NGRAMS THE SAME
        ngram[0] <= ngram[0];
        ngram[1] <= ngram[1];
      end
      
    end
  end
  
  // signals for looping through channels
  assign LastChannel_S = (CycleCntr_SP == `NGRAM_ACCUM_CYCLE-1);
  assign CycleCntr_SN = CycleCntr_SP + 1;
  always @(*) begin
    NS = IDLE;
	
	ReadyOut_SO = 1'b0;
	ValidOut_SO = 1'b0;

	AccumulatorEN_S = 1'b0;
	CycleCntrEN_S = 1'b0;
	CycleCntrCLR_S = 1'b0;

	FirstHypervector_S = 1'b0;
	
	case (CS)
	   IDLE: begin
	       NS = ValidIn_SI ? DATA_RECEIVED : IDLE;
	       ReadyOut_SO = 1;
	   end
	   
	   DATA_RECEIVED: begin
	       NS = ACCUM_FED;
	       AccumulatorEN_S = 1'b1;
		   CycleCntrEN_S = 1'b1;
		   FirstHypervector_S = 1'b1;
	   end
	   
	   ACCUM_FED: begin
	       NS = LastChannel_S ? CHANNELS_MAPPED : ACCUM_FED;
		   AccumulatorEN_S = 1'b1;
	       if (LastChannel_S) begin
			 CycleCntrCLR_S  = 1'b1;
		   end else begin
		     CycleCntrEN_S = 1'b1;
		   end
	   end
	   
	   CHANNELS_MAPPED: begin
	     NS = ReadyIn_SI ? IDLE : CHANNELS_MAPPED;
	     ValidOut_SO = 1'b1;
	   end
	   default: ;
	endcase
  end
  
  // FSM state transitions
  always @(posedge Clk_CI) begin
	if (Reset_RI)
		CS <= IDLE;
	else
		CS <= NS;
  end
  
   // Cycle (channel) counter
  always @(posedge Clk_CI) begin
      if (Reset_RI || CycleCntrCLR_S) 
          CycleCntr_SP <= {`ceilLog2(`INPUT_CHANNELS){1'b0}};
      else if (CycleCntrEN_S)
          CycleCntr_SP <= CycleCntr_SN;
  end

    
endmodule












