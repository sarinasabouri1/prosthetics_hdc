// NEW VERSION OF TEMPORAL ENCODER
`include "const.vh"

module temporal_encoder
(
	// global ports
	input Clk_CI, Reset_RI,

	// handshaking
	input ValidIn_SI, ReadyIn_SI,
	output reg ReadyOut_SO, 
	output wire ValidOut_SO,

	// inputs
	input [0:`HV_DIMENSION-1] HypervectorIn_DI,
	
	output [0:`HV_DIMENSION-1] HypervectorOut_DO
);

  reg [0:`HV_DIMENSION-1] ngram [0:`NGRAM_SIZE-1];
  reg [0:`HV_DIMENSION-1] BindNGramOut_D, result;
  reg [1:0] CS, NS;
  wire temp_accum_valid;
  reg Enable_newAccum;
  reg Enable_bundle;

  localparam idle = 2'd0;
  localparam wait_one_cycle = 2'd1;
  localparam bundle = 2'd2;


  temporal_accumulator TemporalAccum (Clk_CI, Reset_RI, Enable_newAccum, Enable_bundle, BindNGramOut_D, temp_accum_valid, HypervectorOut_DO);

  assign ValidOut_SO = temp_accum_valid; // output is valid when outuput of temporal accumulator is valid


  // update NGrams
  integer i;
  always @(posedge Clk_CI) begin
    if (Reset_RI)
      for (i = 0; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= {`HV_DIMENSION{1'b0}};
//    else if (ValidIn_SI) begin
    else begin
      // ONLY COMPUTE NGRAMS WITH VALID INPUTS
      if (ValidIn_SI == 1'b1) begin
        ngram[0] <= HypervectorIn_DI;
        ngram[1] <= {ngram[0][`HV_DIMENSION-1], ngram[0][0:`HV_DIMENSION-2]};
         //ngram[1] <= {result[`HV_DIMENSION-1], result[0:`HV_DIMENSION-2]};
      end else begin // IF NOT VALID KEEP NGRAMS THE SAME
        ngram[0] <= ngram[0];
        ngram[1] <= ngram[1];
      end
      
    end
  end


// NGram binding --> weird way that SW version does where we initialize with all 1's before xor
  always @ (*) begin
    result = {`HV_DIMENSION{1'b1}}; // initialize with all 1's
    for (i=0; i<`NGRAM_SIZE; i=i+1) begin
      result = result ^ ngram[i];
    end
    BindNGramOut_D = result;
  end

  // FSM: handles transition between accumulations
  always @(posedge Clk_CI) begin
    if (Reset_RI) CS <= idle;
    else CS <= NS;
  end

  always @(*) begin
    NS = CS;
    Enable_newAccum = 0;
    ReadyOut_SO = 1; // we should always be ready to take in new inputs from spatial encoder?
    Enable_bundle = 0;

    case (CS)
      idle: begin
        if (ValidIn_SI == 1'b0) begin // if not input valid, keep spinning in idle
          NS = idle;
        end
        else begin // input is valid
          // want to wait one cycle to exclude this ngram bc it overlapped
          NS = wait_one_cycle;
        end
      end
      wait_one_cycle: begin
       
//        NS = bundle;
//        Enable_newAccum = 1'b1;
//        Enable_bundle = 1'b1;
        
        if (ValidIn_SI == 1'b1) begin  // can move onto bundle since we waited one cycle
            NS = bundle;
            Enable_newAccum = 1'b1;
            //Enable_bundle = 1'b1;
        end else begin // stay in this state until we get the next valid input
            NS = wait_one_cycle;
        end
      end

      bundle: begin
        if (temp_accum_valid == 1'b0) begin // temporal accumulator not done yet
//          NS = bundle;
//          Enable_bundle = 1'b1; // keep bundling
          // bundle in only if input is valid
          NS = bundle;
          if (ValidIn_SI == 1'b1) begin
            NS = bundle;
            Enable_bundle = 1'b1; // keep bundling
          end 
        end
        else begin // output is valid, next state we want to start new bundle
          if (ValidIn_SI == 1'b1) begin // if inpit valid, back to wait one cycle state
            NS = wait_one_cycle;
          end else begin
            NS = idle; // input not valid, go to idle
          end
           
        end
      end

    endcase

  end
    
endmodule












