`include "const.vh"

module feature_encoder
(
	// global ports
	input Clk_CI, Reset_RI, 

	// handshaking
	input ValidIn_SI, ReadyIn_SI,
	output reg ReadyOut_SO, ValidOut_SO,

	// inputs
	input [0:`RAW_WIDTH*`INPUT_CHANNELS-1] Raw_DI,

	// outputs
    output [0:`CHANNEL_WIDTH*`INPUT_CHANNELS-1] ChannelsOut_DO
);

	// FSM state definitions
	localparam IDLE = 0;
	localparam FEATURE_CALC = 1;
	localparam FEATURE_READY = 2;

	// FSM and control signals
	reg [1:0] prev_state, next_state;
	reg SBuff_WE, SBuff_RE;

	// datapath internal wires
	wire [`RAW_WIDTH-1:0] Raw_DN [0:`INPUT_CHANNELS-1];
    wire [0:`RAW_WIDTH*`INPUT_CHANNELS-1] OldSample;

	reg [`RAW_WIDTH-1:0] Raw_DP [0:`INPUT_CHANNELS-1];
	reg [`RAW_WIDTH+`ceilLog2(`SBUFFER_DEPTH)-1:0] MeanVal [0:`INPUT_CHANNELS-1];
	reg [`RAW_WIDTH-1:0] RawDemean [0:`INPUT_CHANNELS-1];
    reg [`ceilLog2(`FEATWIN_SIZE):0] FeatureCntr;
	reg [`RAW_WIDTH+`FEATWIN_SIZE-1:0] FeatureVal [0:`INPUT_CHANNELS-1];
	reg [`CHANNEL_WIDTH-1:0] ChannelsOut [0:`INPUT_CHANNELS-1];

	// DATAPATH

	generate
		genvar j;
		for (j=0; j < `INPUT_CHANNELS; j=j+1) begin
			assign Raw_DN[j] = Raw_DI[j*`RAW_WIDTH:(j+1)*`RAW_WIDTH-1];
			assign ChannelsOut_DO[j*`CHANNEL_WIDTH:(j+1)*`CHANNEL_WIDTH-1] = ChannelsOut[j];
			
			
		end
	endgenerate

	integer i;
	always @(posedge Clk_CI) begin
		if (Reset_RI) begin
			for (i=0; i < `INPUT_CHANNELS; i=i+1) Raw_DP[i] <= {`RAW_WIDTH{1'b0}};
		end
		else begin
			for (i=0; i < `INPUT_CHANNELS; i=i+1) Raw_DP[i] <= Raw_DN[i];
		end
	end
	
	// instantiate sample buffer
	fifo #(.data_width(`RAW_WIDTH*`INPUT_CHANNELS), .fifo_depth(`SBUFFER_DEPTH), .addr_width(`ceilLog2(`SBUFFER_DEPTH))) SampleBuffer (
		.clk(Clk_CI),
		.rst(Reset_RI),
		.wr_en(SBuff_WE),
		.din(Raw_DI),
		.rd_en(SBuff_RE),
		.dout(OldSample)
	);

	// FSM
	always @(*) begin
		// default values
		next_state = IDLE;
		
		ReadyOut_SO = 1'b0;
		ValidOut_SO = 1'b0;

		SBuff_WE = 1'b0;
		SBuff_RE = 1'b0;
		for (i=0; i < `INPUT_CHANNELS; i=i+1) ChannelsOut[i] = {`CHANNEL_WIDTH{1'b0}};
		for (i=0; i < `INPUT_CHANNELS; i=i+1) RawDemean[i] = {`RAW_WIDTH{1'b0}};

		case (prev_state)
			IDLE: begin
				next_state = ValidIn_SI ? FEATURE_CALC : IDLE;
				ReadyOut_SO = 1'b1;
				SBuff_WE = ValidIn_SI ? 1'b1 : 1'b0;
				SBuff_RE = ValidIn_SI ? 1'b1 : 1'b0;
			end
			FEATURE_CALC: begin
				for (i=0; i < `INPUT_CHANNELS; i=i+1) begin

					RawDemean[i] = Raw_DP[i] - ((Raw_DP[i] - OldSample[i*`RAW_WIDTH+:`RAW_WIDTH] + MeanVal[i]) >> (`ceilLog2(`SBUFFER_DEPTH)));
					// absolute value:
					if (RawDemean[i][`RAW_WIDTH-1])
						RawDemean[i] = -RawDemean[i];
					else
						RawDemean[i] = RawDemean[i];	
				end
				if (FeatureCntr == `FEATWIN_SIZE-1) begin
					next_state = FEATURE_READY;
				end
				else begin
					next_state = IDLE;
				end

			end
			FEATURE_READY: begin
				next_state = ReadyIn_SI ? IDLE : FEATURE_READY;
				// Saturate the ChannelOut at max value				
				for (i=0; i < `INPUT_CHANNELS; i=i+1) ChannelsOut[i] = (FeatureVal[i][`RAW_WIDTH+`FEATWIN_SIZE-1:0] > ((1 << `CHANNEL_WIDTH)-1)) ? ((1 << `CHANNEL_WIDTH)-1) : FeatureVal[i][`RAW_WIDTH+`FEATWIN_SIZE-1:0];
				ValidOut_SO = 1'b1;
			end
			default: ;
		endcase // prev_state
	end

	// FSM state transitions
	always @(posedge Clk_CI) begin
		if (Reset_RI)
			prev_state <= IDLE;
		else
			prev_state <= next_state;
	end

	// FSM output registers
	always @(posedge Clk_CI) begin
		if (Reset_RI) begin
			for (i=0; i < `INPUT_CHANNELS; i=i+1) begin
				MeanVal[i] <= {(`RAW_WIDTH+`ceilLog2(`SBUFFER_DEPTH)){1'b0}};
				FeatureVal[i] <= {(`RAW_WIDTH+`FEATWIN_SIZE){1'b0}};
			end
			FeatureCntr <= 0;
		end
		else
		case (prev_state)
			IDLE: begin

			end
			FEATURE_CALC: begin
				for (i=0; i < `INPUT_CHANNELS; i=i+1) begin
					MeanVal[i] <= Raw_DP[i] - OldSample[i*`RAW_WIDTH+:`RAW_WIDTH] + MeanVal[i];	
				end
				if (FeatureCntr == `FEATWIN_SIZE-1) begin
					FeatureCntr <= 0;			
					// ## FINDING AVG OF RAWDEMEAN FOR 32 (FEATWIN_SIZE CHANNELS)
					for (i=0; i < `INPUT_CHANNELS; i=i+1) FeatureVal[i] <= (RawDemean[i] + FeatureVal[i]) >> (`ceilLog2(`FEATWIN_SIZE));
				end
				else if (FeatureCntr == 0) begin
					FeatureCntr <= FeatureCntr + 1;					
					for (i=0; i < `INPUT_CHANNELS; i=i+1) FeatureVal[i] <= RawDemean[i];
				end
				else begin
					FeatureCntr <= FeatureCntr + 1;
					for (i=0; i < `INPUT_CHANNELS; i=i+1) FeatureVal[i] <= RawDemean[i] + FeatureVal[i];
				end
			end
			FEATURE_READY: begin
				
			end
			default: ;
		endcase // prev_state		
	end

endmodule
