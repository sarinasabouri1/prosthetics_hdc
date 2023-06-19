`include "const.vh"

module hdc_top
(
	// global ports
	input Clk_CI, Reset_RI, 

	// handshaking
	input ValidIn_SI, ReadyIn_SI,
	output ReadyOut_SO, ValidOut_SO,

	// inputs
    input [0:`RAW_WIDTH*`INPUT_CHANNELS-1] Raw_DI,
	

	// outputs
	output [`LABEL_WIDTH-1:0] LabelOut_DO,
	output [`ADL_WIDTH-1:0] ADLOut_DO
);

// feature -> spatial
wire Ready_FS, Valid_FS;
wire [0:`CHANNEL_WIDTH*`INPUT_CHANNELS-1] Channels_FS;

// spatial -> temporal
wire Ready_ST, Valid_ST;

wire [0:`HV_DIMENSION-1] Hypervector_ST;

// temporal -> AM
wire Ready_TA, Valid_TA;
wire [0:`HV_DIMENSION-1] Hypervector_TA;

feature_encoder feature_encoder(
	.Clk_CI        (Clk_CI),
	.Reset_RI      (~Reset_RI),

	.ValidIn_SI    (ValidIn_SI),
	.ReadyOut_SO   (ReadyOut_SO),

	.ValidOut_SO   (Valid_FS),
	.ReadyIn_SI    (Ready_FS),

	.Raw_DI        (Raw_DI),

	.ChannelsOut_DO(Channels_FS)
	);

//spatial_encoder spatial_encoder(
//	.Clk_CI           (Clk_CI),
//	.Reset_RI         (~Reset_RI),

//	.ValidIn_SI    	  (Valid_FS),
//	.ReadyOut_SO   	  (Ready_FS),

//	.ValidOut_SO      (Valid_ST),
//	.ReadyIn_SI       (Ready_ST),

//	.ChannelsIn_DI    (Channels_FS),

//	.HypervectorOut_DO(Hypervector_ST)
//	);

spatial_encoder_ping_pong spatial_encoder(
	.Clk_CI           (Clk_CI),
	.Reset_RI         (~Reset_RI),

	.ValidIn_SI    	  (Valid_FS),
	.ReadyOut_SO   	  (Ready_FS),

	.ValidOut_SO      (Valid_ST),
	.ReadyIn_SI       (Ready_ST),

	.ChannelsIn_DI    (Channels_FS),

	.HypervectorOut_DO(Hypervector_ST)
	);

temporal_encoder temporal_encoder(
	.Clk_CI           (Clk_CI),
	.Reset_RI         (~Reset_RI),

	.ValidIn_SI    	  (Valid_ST),
	.ReadyOut_SO   	  (Ready_ST),

	.ValidOut_SO      (Valid_TA),
	.ReadyIn_SI       (Ready_TA),

	.HypervectorIn_DI (Hypervector_ST),

	.HypervectorOut_DO(Hypervector_TA)
	);

associative_memory associative_memory(
	.Clk_CI          (Clk_CI),
	.Reset_RI        (~Reset_RI),

	.ValidIn_SI      (Valid_TA),
	.ReadyOut_SO     (Ready_TA),

	.ValidOut_SO     (ValidOut_SO),
	.ReadyIn_SI      (ReadyIn_SI),

	.HypervectorIn_DI(Hypervector_TA),

	.LabelOut_DO     (LabelOut_DO),
	.ADLOut_DO  (ADLOut_DO)
	);

endmodule











