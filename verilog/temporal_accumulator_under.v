`include "const.vh"

module temporal_accumulator_under
(
	// global ports
	input Clk_CI, Reset_RI, 

	// control signals
	input FirstHypervector_SI, Enable_SI,

	// input values
	input [0:`HV_DIMENSION-1] BindNGramIn_DI,

	// output value
	output [0:`HV_DIMENSION-1] HypervectorOut_DO
);
	// accumulator register
    reg [`ceilLog2(`TEMP_ACCUM_THRESH)+1:0] Accumulator_DP [0:`HV_DIMENSION-1];
    reg [`ceilLog2(`TEMP_ACCUM_THRESH)+1:0] Accumulator_DN [0:`HV_DIMENSION-1];
	reg [`ceilLog2(`NGRAM_ACCUM_CYCLE):0] cycle_counter;
	wire clear_counter_accumulator;

    
	integer i,k;
	always @(*) begin
	    for (k=0; k<`HV_DIMENSION; k=k+1) begin
	       if (FirstHypervector_SI) begin
	           Accumulator_DN[k] <= `TEMP_ACCUM_THRESH - BindNGramIn_DI[k];
	       end else begin
	           Accumulator_DN[k] <= Accumulator_DP[k] - BindNGramIn_DI[k];
	       end
	    end
	end



	//take majority as output
	genvar j;
	for (j=0; j<`HV_DIMENSION; j=j+1) begin
	   assign HypervectorOut_DO[j] = Accumulator_DP[j][`ceilLog2(`TEMP_ACCUM_THRESH)];
	end
	
	// update accumulator reg
	always @(posedge Clk_CI) begin
		if (Reset_RI)
			for (i=0; i<`HV_DIMENSION; i=i+1) Accumulator_DP[i] = {`HV_DIMENSION{1'b0}};
		else if (Enable_SI)
			for (i=0; i<`HV_DIMENSION; i=i+1) Accumulator_DP[i] = Accumulator_DN[i];
	end


endmodule
