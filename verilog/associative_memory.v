`include "const.vh"

module associative_memory
(
	// global inputs
	input Clk_CI, Reset_RI, 

	// handshaking
	input ValidIn_SI, 
	input ReadyIn_SI, 
	output reg ValidOut_SO,
	output ReadyOut_SO,

	// inputs
	input [0:`HV_DIMENSION-1] HypervectorIn_DI,
	
	// outputs
	output reg [`LABEL_WIDTH-1:0] LabelOut_DO,
	//output [`DISTANCE_WIDTH-1:0] DistanceOut_DO,
	output reg [`ADL_WIDTH-1:0] ADLOut_DO
);
	reg [`ceilLog2(`HV_DIMENSION)-1:0] distances [0:`NUM_LABELS-1];
	reg [`LABEL_WIDTH-1:0] best_label_idx;
	reg [`ceilLog2(`HV_DIMENSION)-1:0] best_distance;
	
	reg [0:`HV_DIMENSION-1] similarity [0:`NUM_LABELS-1];
	localparam [0:`AM_MATRIX_WIDTH-1] AM_MATRIX = `AM_MATRIX;
	wire [0:`HV_DIMENSION-1] LABEL_SUBGESTURE_HVS [0:`NUM_LABELS-1];
	
	
	generate
	   genvar k;
	   for (k=0; k < `NUM_LABELS; k=k+1) begin
	       assign LABEL_SUBGESTURE_HVS[k] = AM_MATRIX[k*`HV_DIMENSION:(k+1)*`HV_DIMENSION-1];
	   end
	endgenerate
	
//    reg [1:0] CS, NS;
//    localparam idle = 2'd0;
//    localparam compute_distance = 2'd1;
//    localparam assign_label = 2'd2;
    
//	always @(posedge Clk_CI) begin
//        if (Reset_RI) begin
//         CS <= idle;
//        end else CS <= NS;
//    end
    
//    integer i,j,n;
//    always @(*) begin
//        NS = CS;        
//        best_label_idx = 0;
//        best_distance = 0;
//        LabelOut_DO = 0;
//        ADLOut_DO = 0;
//        ValidOut_SO = 1'b0;
        
//        case (CS)
//          idle: begin
//            for (i=0; i<`NUM_LABELS; i=i+1) begin
//                distances[i] = `DISTANCE_WIDTH'b0;
//                similarity[i] = `HV_DIMENSION'b0;
//            end
//            if (ValidIn_SI) begin
//                NS = compute_distance;
//            end else begin
//                NS = idle;
//            end
//          end
//          compute_distance: begin
//            for (i=0; i<`NUM_LABELS; i=i+1) begin
//                for (n = 0; n < `HV_DIMENSION; n = n+1) similarity[i][n] = LABEL_SUBGESTURE_HVS[i][n] ^ HypervectorIn_DI[n];
//                for (j=0; j<`HV_DIMENSION; j=j+1) begin
//                  distances[i] = distances[i] + similarity[i][j];
//                end
//            end
//            NS = assign_label;
//          end
    
//          assign_label: begin
//            // now compute min distances and find best label
//            best_label_idx = 0;
//            best_distance = distances[0];
          
//            for (i=1; i<`NUM_LABELS; i=i+1) begin
//                if (distances[i] < best_distance) begin
//                    best_distance = distances[i];
//                    best_label_idx = i;
//                end
//            end
//            LabelOut_DO = best_label_idx;
            
//            // return best ADL
//            if ((best_label_idx >= `LABEL_WIDTH'd0) && (best_label_idx <= `LABEL_WIDTH'd7)) begin
//                ADLOut_DO = `ADL_WIDTH'd0;
//            end else if ((best_label_idx >= `LABEL_WIDTH'd8) && (best_label_idx <= `LABEL_WIDTH'd22)) begin
//                 ADLOut_DO = `ADL_WIDTH'd1;
//            end else if (best_label_idx >= `LABEL_WIDTH'd23 && best_label_idx <= `LABEL_WIDTH'd36) begin
//                 ADLOut_DO = `ADL_WIDTH'd2;
//            end else if (best_label_idx >= `LABEL_WIDTH'd37 && best_label_idx <= `LABEL_WIDTH'd49) begin
//                 ADLOut_DO = `ADL_WIDTH'd3;
//            end else if (best_label_idx >= `LABEL_WIDTH'd50 && best_label_idx <= `LABEL_WIDTH'd65) begin
//                 ADLOut_DO = `ADL_WIDTH'd4;
//            end else begin
//                ADLOut_DO = `ADL_WIDTH'd5;
//            end
            
//            ValidOut_SO = 1'b1;
//            // clear distances
//            for (i=0; i<`NUM_LABELS; i=i+1) distances[i] = `DISTANCE_WIDTH'b0;
//            if (ValidIn_SI) begin
//                NS = compute_distance;
//            end else begin
//                NS = idle;
//            end 
//          end
    
//        endcase
//    end

    
    // IDK HOW TO ASSIGN VALID RN --> ALWAYS VALID?
	assign ReadyOut_SO = 1'b1; // idk??
	
	integer i,j,n;
    always @(posedge Clk_CI) begin
        if (ValidIn_SI) begin
            // first compute hamming distances
            for (i=0; i<`NUM_LABELS; i=i+1) begin
                // ADD IN DOUBLE FOR LOOP HERE FOR THE BIT WISE ASSIGNMENT!
                for (n = 0; n < `HV_DIMENSION; n = n+1) similarity[i][n] = LABEL_SUBGESTURE_HVS[i][n] ^ HypervectorIn_DI[n];
                for (j=0; j<`HV_DIMENSION; j=j+1) begin
                  distances[i] = distances[i] + similarity[i][j];
                end
            end
            // now compute min distances and find best label
            best_label_idx = 0;
            best_distance = distances[0];
          
            for (i=1; i<`NUM_LABELS; i=i+1) begin
                if (distances[i] < best_distance) begin
                    best_distance = distances[i];
                    best_label_idx = i;
                end
            end
            LabelOut_DO = best_label_idx;
            
            // return best ADL
            if ((best_label_idx >= `LABEL_WIDTH'd0) && (best_label_idx <= `LABEL_WIDTH'd7)) begin
                ADLOut_DO = `ADL_WIDTH'd0;
            end else if ((best_label_idx >= `LABEL_WIDTH'd8) && (best_label_idx <= `LABEL_WIDTH'd22)) begin
                 ADLOut_DO = `ADL_WIDTH'd1;
            end else if (best_label_idx >= `LABEL_WIDTH'd23 && best_label_idx <= `LABEL_WIDTH'd36) begin
                 ADLOut_DO = `ADL_WIDTH'd2;
            end else if (best_label_idx >= `LABEL_WIDTH'd37 && best_label_idx <= `LABEL_WIDTH'd49) begin
                 ADLOut_DO = `ADL_WIDTH'd3;
            end else if (best_label_idx >= `LABEL_WIDTH'd50 && best_label_idx <= `LABEL_WIDTH'd65) begin
                 ADLOut_DO = `ADL_WIDTH'd4;
            end else begin
                ADLOut_DO = `ADL_WIDTH'd5;
            end
            
            ValidOut_SO = 1'b1;     
        end 
        else begin
            for (i=0; i<`NUM_LABELS; i=i+1) begin
                distances[i] = `DISTANCE_WIDTH'b0;
                similarity[i] = `HV_DIMENSION'b0;
            end
            best_label_idx = 0;
            best_distance = 0;
            LabelOut_DO = 0;
            ADLOut_DO = 0;
            ValidOut_SO = 1'b0;
               
        end
    end

	

endmodule












