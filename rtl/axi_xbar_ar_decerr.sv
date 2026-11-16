module axi_xbar_ar_decerr #(
	parameter int ID_WIDTH = 4,
	parameter int DATA_WIDTH = 64,
	parameter int NUM_MASTERS = 2,
	parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
	parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
)(
	input logic aclk,
	input logic arst_n,

	input logic [EXT_ID_WIDTH-1:0] arid,
	input logic [7:0] arlen,
	input logic arvalid,
	output logic arready,

	input logic rready,
	output logic [EXT_ID_WIDTH-1:0] rid,
	output logic [DATA_WIDTH-1:0] rdata,
	output logic [1:0] rresp,
	output logic rvalid,
	output logic rlast
);
	typedef enum logic {IDLE, RESP} decerr_states;
	decerr_states state;

	logic [EXT_ID_WIDTH-1:0] captured_rid;
	logic [7:0] captured_len;

	always_ff @(posedge aclk or negedge arst_n) begin
		if(!arst_n) begin
			state <= IDLE;
			captured_len <= '0;
		end

		else begin
			case(state)
				IDLE: if(arvalid && arready) begin
						  state <= RESP;
						  captured_rid <= rid;
						  captured_len <= arlen;
					  end

				RESP: if(rvalid && rready) begin
						  if(captured_len == 0)
						  	  state <= IDLE;
						  else
						  	  captured_len <= captured_len - 1;
					  end

				default: state <= IDLE:
			endcase
		end
	end

	assign arready = (state == IDLE);
	assign rvalid = (state == RESP);
	assign rdata = '0;
	assign rid = captured_id;
	assign rresp = 2'11;
	assign rlast = (state == RESP) && (captured_len == 0);

endmodule

