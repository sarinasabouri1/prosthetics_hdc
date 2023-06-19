`include "const.vh"

module temporal_accumulator
(
	// global ports
	input Clk_CI, Reset_RI, 

	// control signals
	input Enable_newAccum, Enable_bundle,

	// input values
	input [0:`HV_DIMENSION-1] BindNGramIn_DI,

	// output value
	output hvout_valid,
	output reg [0:`HV_DIMENSION-1] HypervectorOut_DO
);
	// accumulator register
//	reg [`TEMP_ACCUM_WIDTH-1:0] Accumulator [0:`HV_DIMENSION-1];
    //reg [`TEMP_ACCUM_WIDTH_2-1:0] Accumulator [0:`HV_DIMENSION-1];
    reg [`ceilLog2(`TEMP_ACCUM_THRESH)+1:0] Accumulator [0:`HV_DIMENSION-1];
	reg [`ceilLog2(`NGRAM_ACCUM_CYCLE):0] cycle_counter;
	wire clear_counter_accumulator;

	assign hvout_valid = (cycle_counter == `NGRAM_ACCUM_CYCLE-1); // output is ready when we've bundled over 99 cycles
	assign clear_counter_accumulator = (Reset_RI || Enable_newAccum || hvout_valid);
    
	integer i,k;
	always @(posedge Clk_CI) begin
	    for (k=0; k<`HV_DIMENSION; k=k+1) begin
	       if (clear_counter_accumulator) begin
	           Accumulator[k] <= `TEMP_ACCUM_THRESH;
	       end else if (Enable_bundle) begin
	           Accumulator[k] <= Accumulator[k] - BindNGramIn_DI[k];
	       end
	    end
	end

    always @(*) begin
	    for (k=0; k<`HV_DIMENSION; k=k+1) begin
	       if (Reset_RI) begin
	           HypervectorOut_DO[k] = 1'b0;
	       end else if (hvout_valid) begin
	           HypervectorOut_DO[k] = Accumulator[k][`ceilLog2(`TEMP_ACCUM_THRESH)];
	       end
	    end
	end

	// take majority as output
//	genvar j;
//	for (j=0; j<`HV_DIMENSION; j=j+1) begin
//	   assign HypervectorOut_DO[j] = Accumulator[j][`ceilLog2(`TEMP_ACCUM_THRESH)];
//	end

//	integer k;
	always @(posedge Clk_CI) begin
		if (clear_counter_accumulator) begin // reset or starting a new bundle
			cycle_counter <= 0;
		end
		else if (Enable_bundle) begin
			cycle_counter <= cycle_counter + 1;
		end
	end
endmodule
