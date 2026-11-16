module axi_xbar_top #(
	parameter int NUM_MASTERS = 2,
	parameter int NUM_SLAVES = 2,
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 64,
	parameter int ID_WIDTH = 4,
	parameter int FIFO_DEPTH = 8,
	parameter int CNT_WIDTH = 4,
	parameter int MASTER_WIDTH = $clog2(NUM_MASTERS), //(NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
	parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
) (
	input logic aclk,
	input logic arst_n,

	// Master AW channel
	input logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_awid,
	input logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0] m_awaddr,
	input logic [NUM_MASTERS-1:0][7:0] m_awlen,
	input logic [NUM_MASTERS-1:0][2:0] m_awsize,
	input logic [NUM_MASTERS-1:0][1:0] m_awburst,
	input logic [NUM_MASTERS-1:0] m_awvalid,
	output logic [NUM_MASTERS-1:0] m_awready,

	// Master W channel
	input logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0] m_wdata,
	input logic [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0] m_wstrb,
	input logic [NUM_MASTERS-1:0] m_wlast,
	input logic [NUM_MASTERS-1:0] m_wvalid,
	output logic [NUM_MASTERS-1:0] m_wready,

	// Master B channel
	output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_bid,
	output logic [NUM_MASTERS-1:0][1:0] m_bresp,
	output logic [NUM_MASTERS-1:0] m_bvalid,
	input logic [NUM_MASTERS-1:0] m_bready,

	// Master AR channel
	input logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_arid,
	input logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0] m_araddr,
	input logic [NUM_MASTERS-1:0][7:0] m_arlen,
	input logic [NUM_MASTERS-1:0][2:0] m_arsize,
	input logic [NUM_MASTERS-1:0][1:0] m_arburst,
	input logic [NUM_MASTERS-1:0] m_arvalid,
	output logic [NUM_MASTERS-1:0] m_arready,

	// Master R channel
	output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_rid,
	output logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0] m_rdata,
	output logic [NUM_MASTERS-1:0][1:0] m_rresp,
	output logic [NUM_MASTERS-1:0] m_rlast,
	output logic [NUM_MASTERS-1:0] m_rvalid,
	input logic [NUM_MASTERS-1:0] m_rready,

	// External slave AW channel
	output logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_awid,
	output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] s_awaddr,
	output logic [NUM_SLAVES-1:0][7:0] s_awlen,
	output logic [NUM_SLAVES-1:0][2:0] s_awsize,
	output logic [NUM_SLAVES-1:0][1:0] s_awburst,
	output logic [NUM_SLAVES-1:0] s_awvalid,
	input logic [NUM_SLAVES-1:0] s_awready,

	// External slave W channel
	output logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] s_wdata,
	output logic [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0] s_wstrb,
	output logic [NUM_SLAVES-1:0] s_wlast,
	output logic [NUM_SLAVES-1:0] s_wvalid,
	input logic [NUM_SLAVES-1:0] s_wready,

	// External slave B channel
	input logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_bid,
	input logic [NUM_SLAVES-1:0][1:0] s_bresp,
	input logic [NUM_SLAVES-1:0] s_bvalid,
	output logic [NUM_SLAVES-1:0] s_bready,

	// External slave AR channel
	output logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_arid,
	output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] s_araddr,
	output logic [NUM_SLAVES-1:0][7:0] s_arlen,
	output logic [NUM_SLAVES-1:0][2:0] s_arsize,
	output logic [NUM_SLAVES-1:0][1:0] s_arburst,
	output logic [NUM_SLAVES-1:0] s_arvalid,
	input logic [NUM_SLAVES-1:0] s_arready,

	// External slave R channel
	input logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_rid,
	input logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] s_rdata,
	input logic [NUM_SLAVES-1:0][1:0] s_rresp,
	input logic [NUM_SLAVES-1:0] s_rlast,
	input logic [NUM_SLAVES-1:0] s_rvalid,
	output logic [NUM_SLAVES-1:0] s_rready,
	
	output logic s_arst_n
);
	`include "axi_xbar_addr_decoder.vh"
	// Target parameters and address decoding helper function
	localparam int NUM_TARGETS = NUM_SLAVES + 1;
	localparam int TARGET_WIDTH = (NUM_TARGETS > 1) ? $clog2(NUM_TARGETS) : 1;
	localparam int STRB_WIDTH = DATA_WIDTH / 8;

	typedef struct packed {
		logic [ID_WIDTH-1:0] id;
		logic [ADDR_WIDTH-1:0] addr;
		logic [7:0] len;
		logic [2:0] size;
		logic [1:0] burst;
	} addr_item;

	typedef struct packed {
		logic [DATA_WIDTH-1:0] data;
		logic [STRB_WIDTH-1:0] strb;
		logic last;
	} w_item;

	typedef struct packed {
		logic [EXT_ID_WIDTH-1:0] id;
		logic [1:0] resp;
		logic [TARGET_WIDTH-1:0] target;
	} b_item;

	typedef struct packed {
		logic [EXT_ID_WIDTH-1:0] id;
		logic [DATA_WIDTH-1:0] data;
		logic [1:0] resp;
		logic last;
		logic [TARGET_WIDTH-1:0] target;
	} r_item;

	assign s_arst_n = arst_n;
endmodule
