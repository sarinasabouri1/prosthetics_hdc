`include "const.vh"

module im_gen_rule_90 #
(	
	parameter WIDTH = `HV_DIMENSION
)
(
	// global ports
	input Clk_CI, Reset_RI, 

	// control signals
	input Enable_SI, Clear_SI,

	// output value
	output reg [0:WIDTH-1] CellValueOut_DO
);

always @(posedge Clk_CI) begin
	if (Reset_RI || Clear_SI) 
		CellValueOut_DO <= `CELLULAR_AUTOMATON_SEED;
	else if (Enable_SI)
		// XOR of right shift and left shift
		CellValueOut_DO <= {CellValueOut_DO[WIDTH-1], CellValueOut_DO[0:WIDTH-2]} ^ {CellValueOut_DO[1:WIDTH-1], CellValueOut_DO[0]};
end

endmodule