module axi_xbar_aw_decerr #(
	parameter int ID_WIDTH = 4,
	parameter int NUM_MASTERS = 2,
	parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
	parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
)(
	input logic aclk,
	input logic arst_n,
	
	input logic [EXT_ID_WIDTH-1:0] awid,
	input logic awvalid,
	output logic awready,

	input logic wvalid,
	input logic wlast,
	output logic wready,

	input logic bready,
	output logic [EXT_ID_WIDTH-1:0] bid,
	output logic [1:0] bresp,
	output logic bvalid
);

	typedef enum logic [1:0] {IDLE, SINK, RESP} decerr_states;
	decerr_states state;

	logic [EXT_ID_WIDTH-1:0] captured_awid;

	always_ff @(posedge aclk or negedge arst_n) begin
		if(!arst_n) begin
			state <= IDLE;
			captured_awid <= '0;
		end
		else begin
			case(state)
				IDLE: if(awvalid && awready) begin
						  captured_awid <= awid;
						  state <= SINK;
					  end

				SINK: if(wvalid && wready && wlast)
						  state <= RESP;

				RESP: if(bvalid && bready)
						  state <= IDLE;

				default: state <= IDLE;
			endcase
		end
	end

	assign awready = (state == IDLE);
	assign wready = (state == SINK);
	assign bvalid = (state == RESP);
	assign bid = captured_awid;
	assign bresp = 2'b11;

endmodule
