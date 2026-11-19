module axi_xbar_top #(
	parameter int NUM_MASTERS = 2,
	parameter int NUM_SLAVES = 2,
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 64,
	parameter int ID_WIDTH = 4,
	parameter int FIFO_DEPTH = 8,
	parameter int CNT_WIDTH = 4,
	parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
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
	//`include "axi_xbar_addr_decoder.vh"
	localparam int STRB_WIDTH = DATA_WIDTH / 8;
	localparam int SLAVE_WIDTH = (NUM_SLAVES > 1) ? $clog2(NUM_SLAVES) : 1;
	localparam int TARGET_WIDTH = $clog2(NUM_SLAVES+1);

	`include "axi_xbar_addr_decoder.sv"

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
	} b_item;

	typedef struct packed {
		logic [EXT_ID_WIDTH-1:0] id;
		logic [DATA_WIDTH-1:0] data;
		logic [1:0] resp;
		logic last;
	} r_item;

	assign s_arst_n = arst_n;

	// AW CHANNEL SIGNALS
	addr_item aw_in[NUM_MASTERS];
	addr_item aw_out[NUM_MASTERS];
	logic aw_full[NUM_MASTERS];
	logic aw_empty[NUM_MASTERS];
	logic aw_push[NUM_MASTERS];
	logic aw_pop[NUM_MASTERS];

	logic [EXT_ID_WIDTH-1:0] ext_awid[NUM_MASTERS];
	logic [TARGET_WIDTH-1:0] aw_dest_slave[NUM_MASTERS];

	logic [NUM_MASTERS-1:0] aw_req[NUM_SLAVES];
	logic [NUM_MASTERS-1:0] aw_grant[NUM_SLAVES];
	logic [MASTER_WIDTH-1:0] aw_gid[NUM_SLAVES];
	logic aw_gvalid[NUM_SLAVES];
	logic aw_unlock[NUM_SLAVES];

	logic dec_awvalid[NUM_MASTERS];
	logic [EXT_ID_WIDTH-1:0] dec_awid[NUM_MASTERS];
	logic dec_awready[NUM_MASTERS];
	logic dec_wvalid[NUM_MASTERS];
	logic dec_wlast[NUM_MASTERS];
	logic dec_wready[NUM_MASTERS];
	logic dec_bready[NUM_MASTERS];
	logic [EXT_ID_WIDTH-1:0] dec_bid[NUM_MASTERS];
	logic [1:0] dec_bresp[NUM_MASTERS];
	logic dec_bvalid[NUM_MASTERS];

	// W CHANNEL SIGNALS
	w_item w_in[NUM_MASTERS];
	w_item w_out[NUM_MASTERS];
	logic w_full[NUM_MASTERS];
	logic w_empty[NUM_MASTERS];
	logic w_push[NUM_MASTERS];
	logic w_pop[NUM_MASTERS];

	logic [TARGET_WIDTH-1:0] dest_slave_fifo_in[NUM_MASTERS];
	logic [TARGET_WIDTH-1:0] dest_slave_fifo_out[NUM_MASTERS];
	logic dest_slave_fifo_full[NUM_MASTERS];
	logic dest_slave_fifo_empty[NUM_MASTERS];
	logic dest_slave_fifo_push[NUM_MASTERS];
	logic dest_slave_fifo_pop[NUM_MASTERS];

	logic [MASTER_WIDTH-1:0] granted_master_fifo_in[NUM_SLAVES];
	logic [MASTER_WIDTH-1:0] granted_master_fifo_out[NUM_SLAVES];
	logic granted_master_fifo_full[NUM_SLAVES];
	logic granted_master_fifo_empty[NUM_SLAVES];
	logic granted_master_fifo_push[NUM_SLAVES];
	logic granted_master_fifo_pop[NUM_SLAVES];

	w_item d2m_win[NUM_MASTERS][NUM_SLAVES];
	logic d2m_wvalid[NUM_MASTERS][NUM_SLAVES];
	logic s_wready_to_m[NUM_SLAVES][NUM_MASTERS];

	// B CHANNEL SIGNALS
	b_item b_in[NUM_SLAVES][NUM_MASTERS];
	b_item b_out[NUM_SLAVES][NUM_MASTERS];
	logic b_full[NUM_SLAVES][NUM_MASTERS];
	logic b_empty[NUM_SLAVES][NUM_MASTERS];
	logic b_push[NUM_SLAVES][NUM_MASTERS];
	logic b_pop[NUM_SLAVES][NUM_MASTERS];

	logic [MASTER_WIDTH-1:0] b_dest_master[NUM_SLAVES];

	logic [NUM_SLAVES:0] b_req[NUM_MASTERS];
	logic [NUM_SLAVES:0] b_grant[NUM_MASTERS];
	logic [TARGET_WIDTH-1:0] b_gid[NUM_MASTERS];
	logic b_gvalid[NUM_MASTERS];
	logic b_unlock[NUM_MASTERS];

	logic [EXT_ID_WIDTH-1:0] b_mux_id[NUM_MASTERS];
	logic [1:0] b_mux_resp[NUM_MASTERS];
	logic [MASTER_WIDTH-1:0] b_strip_mid[NUM_MASTERS];

	// AR CHANNEL SIGNALS
	addr_item ar_in[NUM_MASTERS];
	addr_item ar_out[NUM_MASTERS];
	logic ar_full[NUM_MASTERS];
	logic ar_empty[NUM_MASTERS];
	logic ar_push[NUM_MASTERS];
	logic ar_pop[NUM_MASTERS];

	logic [EXT_ID_WIDTH-1:0] ext_arid[NUM_MASTERS];
	logic [TARGET_WIDTH-1:0] ar_dest_slave[NUM_MASTERS];

	logic [NUM_MASTERS-1:0] ar_req[NUM_SLAVES];
	logic [NUM_MASTERS-1:0] ar_grant[NUM_SLAVES];
	logic [MASTER_WIDTH-1:0] ar_gid[NUM_SLAVES];
	logic ar_gvalid[NUM_SLAVES];
	logic ar_unlock[NUM_SLAVES];

	logic dec_arvalid[NUM_MASTERS];
	logic [EXT_ID_WIDTH-1:0] dec_arid[NUM_MASTERS];
	logic [7:0] dec_arlen[NUM_MASTERS];
	logic dec_arready[NUM_MASTERS];
	logic dec_rready[NUM_MASTERS];
	logic [EXT_ID_WIDTH-1:0] dec_rid[NUM_MASTERS];
	logic [DATA_WIDTH-1:0] dec_rdata[NUM_MASTERS];
	logic [1:0] dec_rresp[NUM_MASTERS];
	logic dec_rvalid[NUM_MASTERS];
	logic dec_rlast[NUM_MASTERS];

	// R CHANNEL SIGNALS
	r_item r_in[NUM_SLAVES][NUM_MASTERS];
	r_item r_out[NUM_SLAVES][NUM_MASTERS];
	logic r_full[NUM_SLAVES][NUM_MASTERS];
	logic r_empty[NUM_SLAVES][NUM_MASTERS];
	logic r_push[NUM_SLAVES][NUM_MASTERS];
	logic r_pop[NUM_SLAVES][NUM_MASTERS];

	logic [MASTER_WIDTH-1:0] r_dest_master[NUM_SLAVES];

	logic [NUM_SLAVES:0] r_req[NUM_MASTERS];
	logic [NUM_SLAVES:0] r_grant[NUM_MASTERS];
	logic [TARGET_WIDTH-1:0] r_gid[NUM_MASTERS];
	logic r_gvalid[NUM_MASTERS];
	logic r_unlock[NUM_MASTERS];

	logic [EXT_ID_WIDTH-1:0] r_mux_id[NUM_MASTERS];
	logic [DATA_WIDTH-1:0] r_mux_data[NUM_MASTERS];
	logic [1:0] r_mux_resp[NUM_MASTERS];
	logic r_mux_last[NUM_MASTERS];
	logic [MASTER_WIDTH-1:0] r_strip_mid[NUM_MASTERS];


	for(genvar m = 0; m < NUM_MASTERS; m++) begin
		sync_fifo #(
			.DATA_WIDTH($bits(addr_item)),
			.FIFO_DEPTH(FIFO_DEPTH)
		) aw_fifo(
			.data_in(aw_in[m]),
			.write(aw_push[m]),
			.read(aw_pop[m]),
			.clk(aclk),
			.resetn(arst_n),
			.data_out(aw_out[m]),
			.full(aw_full[m]),
			.empty(aw_empty[m])
		);

		axi_xbar_id_extender #(
			.ID_WIDTH(ID_WIDTH),
			.NUM_MASTERS(NUM_MASTERS),
			.MASTER_WIDTH(MASTER_WIDTH),
			.EXT_ID_WIDTH(EXT_ID_WIDTH)
		) aw_ext(
			.id_in(aw_out[m].id),
			.master_id(MASTER_WIDTH'(m)),
			.id_out(ext_awid[m])
		);

		axi_xbar_aw_decerr #(
			.ID_WIDTH(ID_WIDTH),
			.NUM_MASTERS(NUM_MASTERS)
		) aw_decerr_gen(
			.aclk(aclk),
			.arst_n(arst_n),
			.awid(dec_awid[m]),
			.awvalid(dec_awvalid[m]),
			.awready(dec_awready[m]),
			.wvalid(dec_wvalid[m]),
			.wlast(dec_wlast[m]),
			.wready(dec_wready[m]),
			.bready(dec_bready[m]),
			.bid(dec_bid[m]),
			.bresp(dec_bresp[m]),
			.bvalid(dec_bvalid[m])
		);

		sync_fifo #(
			.DATA_WIDTH($bits(w_item)),
			.FIFO_DEPTH(FIFO_DEPTH)
		) w_fifo(
			.data_in(w_in[m]),
			.write(w_push[m]),
			.read(w_pop[m]),
			.clk(aclk),
			.resetn(arst_n),
			.data_out(w_out[m]),
			.full(w_full[m]),
			.empty(w_empty[m])
		);

		sync_fifo #(
			.DATA_WIDTH(TARGET_WIDTH),
			.FIFO_DEPTH(FIFO_DEPTH)
		) dest_slave_fifo(
			.data_in(dest_slave_fifo_in[m]),
			.write(dest_slave_fifo_push[m]),
			.read(dest_slave_fifo_pop[m]),
			.clk(aclk),
			.resetn(arst_n),
			.data_out(dest_slave_fifo_out[m]),
			.full(dest_slave_fifo_full[m]),
			.empty(dest_slave_fifo_empty[m])
		);

		rr_arbiter #(
			.NUM_REQ(NUM_SLAVES + 1)
		) b_arb(
			.aclk(aclk),
			.arst_n(arst_n),
			.req(b_req[m]),
			.unlock_en(b_unlock[m]),
			.grant(b_grant[m]),
			.grant_idx(b_gid[m]),
			.grant_valid(b_gvalid[m])
		);

		axi_xbar_id_stripper #(
			.ID_WIDTH(ID_WIDTH),
			.NUM_MASTERS(NUM_MASTERS),
			.MASTER_WIDTH(MASTER_WIDTH),
			.EXT_ID_WIDTH(EXT_ID_WIDTH)
		) b_strip(
			.id_in(b_mux_id[m]),
			.id_out(m_bid[m]),
			.master_id(b_strip_mid[m])
		);

		sync_fifo #(
			.DATA_WIDTH($bits(addr_item)),
			.FIFO_DEPTH(FIFO_DEPTH)
		) ar_fifo(
			.data_in(ar_in[m]),
			.write(ar_push[m]),
			.read(ar_pop[m]),
			.clk(aclk),
			.resetn(arst_n),
			.data_out(ar_out[m]),
			.full(ar_full[m]),
			.empty(ar_empty[m])
		);

		axi_xbar_id_extender #(
			.ID_WIDTH(ID_WIDTH),
			.NUM_MASTERS(NUM_MASTERS),
			.MASTER_WIDTH(MASTER_WIDTH),
			.EXT_ID_WIDTH(EXT_ID_WIDTH)
		) ar_ext(
			.id_in(ar_out[m].id),
			.master_id(MASTER_WIDTH'(m)),
			.id_out(ext_arid[m])
		);

		axi_xbar_ar_decerr #(
			.ID_WIDTH(ID_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUM_MASTERS(NUM_MASTERS)
		) ar_decerr_gen(
			.aclk(aclk),
			.arst_n(arst_n),
			.arid(dec_arid[m]),
			.arlen(dec_arlen[m]),
			.arvalid(dec_arvalid[m]),
			.arready(dec_arready[m]),
			.rready(dec_rready[m]),
			.rid(dec_rid[m]),
			.rdata(dec_rdata[m]),
			.rresp(dec_rresp[m]),
			.rvalid(dec_rvalid[m]),
			.rlast(dec_rlast[m])
		);

		rr_arbiter #(
			.NUM_REQ(NUM_SLAVES + 1)
		) r_arb(
			.aclk(aclk),
			.arst_n(arst_n),
			.req(r_req[m]),
			.unlock_en(r_unlock[m]),
			.grant(r_grant[m]),
			.grant_idx(r_gid[m]),
			.grant_valid(r_gvalid[m])
		);

		axi_xbar_id_stripper #(
			.ID_WIDTH(ID_WIDTH),
			.NUM_MASTERS(NUM_MASTERS),
			.MASTER_WIDTH(MASTER_WIDTH),
			.EXT_ID_WIDTH(EXT_ID_WIDTH)
		) r_strip(
			.id_in(r_mux_id[m]),
			.id_out(m_rid[m]),
			.master_id(r_strip_mid[m])
		);
	end

	for(genvar s = 0; s < NUM_SLAVES; s++) begin
		rr_arbiter #(
			.NUM_REQ(NUM_MASTERS)
		) aw_arb(
			.aclk(aclk),
			.arst_n(arst_n),
			.req(aw_req[s]),
			.unlock_en(aw_unlock[s]),
			.grant(aw_grant[s]),
			.grant_idx(aw_gid[s]),
			.grant_valid(aw_gvalid[s])
		);

		sync_fifo #(
			.DATA_WIDTH(MASTER_WIDTH),
			.FIFO_DEPTH(FIFO_DEPTH)
		) granted_master_fifo(
			.data_in(granted_master_fifo_in[s]),
			.write(granted_master_fifo_push[s]),
			.read(granted_master_fifo_pop[s]),
			.clk(aclk),
			.resetn(arst_n),
			.data_out(granted_master_fifo_out[s]),
			.full(granted_master_fifo_full[s]),
			.empty(granted_master_fifo_empty[s])
		);

		rr_arbiter #(
			.NUM_REQ(NUM_MASTERS)
		) ar_arb(
			.aclk(aclk),
			.arst_n(arst_n),
			.req(ar_req[s]),
			.unlock_en(ar_unlock[s]),
			.grant(ar_grant[s]),
			.grant_idx(ar_gid[s]),
			.grant_valid(ar_gvalid[s])
		);

		for(genvar m = 0; m < NUM_MASTERS; m++) begin
			sync_fifo #(
				.DATA_WIDTH($bits(b_item)),
				.FIFO_DEPTH(FIFO_DEPTH/2)
			) b_fifo(
				.data_in(b_in[s][m]),
				.write(b_push[s][m]),
				.read(b_pop[s][m]),
				.clk(aclk),
				.resetn(arst_n),
				.data_out(b_out[s][m]),
				.full(b_full[s][m]),
				.empty(b_empty[s][m])
			);

			sync_fifo #(
				.DATA_WIDTH($bits(r_item)),
				.FIFO_DEPTH(FIFO_DEPTH/2)
			) r_fifo(
				.data_in(r_in[s][m]),
				.write(r_push[s][m]),
				.read(r_pop[s][m]),
				.clk(aclk),
				.resetn(arst_n),
				.data_out(r_out[s][m]),
				.full(r_full[s][m]),
				.empty(r_empty[s][m])
			);
		end
	end

	//AW Channel
	always_comb begin
		for(int m = 0; m < NUM_MASTERS; m++) begin
			aw_in[m] = {m_awid[m], m_awaddr[m], m_awlen[m], m_awsize[m], m_awburst[m]};
			m_awready[m] = arst_n && !aw_full[m];
			aw_push[m] = m_awvalid[m] && m_awready[m];
			aw_dest_slave[m] = decode_addr(aw_out[m].addr);
			dec_awid[m] = ext_awid[m];
			dec_awvalid[m] = 1'b0;
			aw_pop[m] = 1'b0;
			dest_slave_fifo_in[m] = aw_dest_slave[m];
			dest_slave_fifo_push[m] = 1'b0;
		end

		for(int s = 0; s < NUM_SLAVES; s++) begin
			s_awid[s] = '0;
			s_awaddr[s] = '0;
			s_awlen[s] = '0;
			s_awsize[s] = '0;
			s_awburst[s] = '0;
			s_awvalid[s] = 1'b0;
			aw_unlock[s] = 1'b0;
			granted_master_fifo_in[s] = aw_gid[s];
			granted_master_fifo_push[s] = 1'b0;

			for(int m = 0; m < NUM_MASTERS; m++) begin
				aw_req[s][m] = !aw_empty[m] && (aw_dest_slave[m] == TARGET_WIDTH'(s)) && !dest_slave_fifo_full[m] && !granted_master_fifo_full[s];
			end

			if(aw_gvalid[s]) begin
				for(int m = 0; m < NUM_MASTERS; m++) begin
					if(aw_gid[s] == MASTER_WIDTH'(m)) begin
						s_awid[s] = ext_awid[m];
						s_awaddr[s] = aw_out[m].addr;
						s_awlen[s] = aw_out[m].len;
						s_awsize[s] = aw_out[m].size;
						s_awburst[s] = aw_out[m].burst;
						s_awvalid[s] = !aw_empty[m] && !dest_slave_fifo_full[m] && !granted_master_fifo_full[s];

						if(s_awvalid[s] && s_awready[s]) begin
							aw_unlock[s] = 1'b1;
							granted_master_fifo_push[s] = 1'b1;
						end
					end
				end
			end
		end

		for(int m = 0; m < NUM_MASTERS; m++) begin
			if(aw_dest_slave[m] == TARGET_WIDTH'(NUM_SLAVES)) begin
				dec_awvalid[m] = !aw_empty[m] && !dest_slave_fifo_full[m];
				if(dec_awvalid[m] && dec_awready[m]) begin
					aw_pop[m] = 1'b1;
					dest_slave_fifo_push[m] = 1'b1;
				end
			end
			else begin
				for(int s = 0; s < NUM_SLAVES; s++) begin
					if((aw_dest_slave[m] == TARGET_WIDTH'(s)) && aw_gvalid[s] && (aw_gid[s] == MASTER_WIDTH'(m)) && s_awvalid[s] && s_awready[s]) begin
						aw_pop[m] = 1'b1;
						dest_slave_fifo_push[m] = 1'b1;
					end
				end
			end
		end
	end

	//W Channel
	always_comb begin
		for(int m = 0; m < NUM_MASTERS; m++) begin
			w_in[m] = {m_wdata[m], m_wstrb[m], m_wlast[m]};
			m_wready[m] = arst_n && !w_full[m];
			w_push[m] = m_wvalid[m] && m_wready[m];

			for(int s = 0; s < NUM_SLAVES; s++) begin
				d2m_win[m][s] = '0;
				d2m_wvalid[m][s] = 1'b0;
			end
			dec_wvalid[m] = 1'b0;
			dec_wlast[m] = 1'b0;
			w_pop[m] = 1'b0;
			dest_slave_fifo_pop[m] = 1'b0;
		end

		for(int s = 0; s < NUM_SLAVES; s++) begin
			for(int m = 0; m < NUM_MASTERS; m++) begin
				s_wready_to_m[s][m] = 1'b0;
			end
			if(!granted_master_fifo_empty[s]) begin
				for(int m = 0; m < NUM_MASTERS; m++) begin
					if(granted_master_fifo_out[s] == MASTER_WIDTH'(m)) begin
						s_wready_to_m[s][m] = s_wready[s];
					end
				end
			end
		end

		for(int m = 0; m < NUM_MASTERS; m++) begin
			if(!w_empty[m] && !dest_slave_fifo_empty[m]) begin
				if(dest_slave_fifo_out[m] == TARGET_WIDTH'(NUM_SLAVES)) begin
					dec_wvalid[m] = 1'b1;
					dec_wlast[m] = w_out[m].last;
					if(dec_wready[m]) begin
						w_pop[m] = 1'b1;
						dest_slave_fifo_pop[m] = w_out[m].last;
					end
				end
				else begin
					for(int s = 0; s < NUM_SLAVES; s++) begin
						if(dest_slave_fifo_out[m] == TARGET_WIDTH'(s)) begin
							d2m_win[m][s] = w_out[m];
							d2m_wvalid[m][s] = 1'b1;
							if(s_wready_to_m[s][m]) begin
								w_pop[m] = 1'b1;
								dest_slave_fifo_pop[m] = w_out[m].last;
							end
						end
					end
				end
			end
		end

		for(int s = 0; s < NUM_SLAVES; s++) begin
			s_wdata[s] = '0;
			s_wstrb[s] = '0;
			s_wlast[s] = 1'b0;
			s_wvalid[s] = 1'b0;
			granted_master_fifo_pop[s] = 1'b0;

			if(!granted_master_fifo_empty[s]) begin
				for(int m = 0; m < NUM_MASTERS; m++) begin
					if(granted_master_fifo_out[s] == MASTER_WIDTH'(m)) begin
						s_wdata[s] = d2m_win[m][s].data;
						s_wstrb[s] = d2m_win[m][s].strb;
						s_wlast[s] = d2m_win[m][s].last;
						s_wvalid[s] = d2m_wvalid[m][s];

						if(s_wvalid[s] && s_wready[s] && s_wlast[s]) begin
							granted_master_fifo_pop[s] = 1'b1;
						end
					end
				end
			end
		end
	end

	//B Channel
	always_comb begin
		for(int s = 0; s < NUM_SLAVES; s++) begin
			b_dest_master[s] = s_bid[s][EXT_ID_WIDTH-1:ID_WIDTH];
			s_bready[s] = 1'b0;
			for(int m = 0; m < NUM_MASTERS; m++) begin
				b_in[s][m] = {s_bid[s], s_bresp[s]};
				b_push[s][m] = 1'b0;
				if(b_dest_master[s] == MASTER_WIDTH'(m)) begin
					s_bready[s] = arst_n && !b_full[s][m];
					b_push[s][m] = s_bvalid[s] && s_bready[s];
				end
			end
		end

		for(int m = 0; m < NUM_MASTERS; m++) begin
			for(int s = 0; s < NUM_SLAVES; s++) begin
				b_req[m][s] = !b_empty[s][m];
				b_pop[s][m] = 1'b0;
			end
			b_req[m][NUM_SLAVES] = dec_bvalid[m];

			b_mux_id[m] = '0;
			b_mux_resp[m] = '0;
			m_bvalid[m] = 1'b0;
			b_unlock[m] = 1'b0;
			dec_bready[m] = 1'b0;

			if(b_gvalid[m]) begin
				if(b_gid[m] == TARGET_WIDTH'(NUM_SLAVES)) begin
					b_mux_id[m] = dec_bid[m];
					b_mux_resp[m] = dec_bresp[m];
					m_bvalid[m] = dec_bvalid[m];
					if(m_bvalid[m] && m_bready[m]) begin
						dec_bready[m] = 1'b1;
						b_unlock[m] = 1'b1;
					end
				end
				else begin
					for(int s = 0; s < NUM_SLAVES; s++) begin
						if(b_gid[m] == TARGET_WIDTH'(s)) begin
							b_mux_id[m] = b_out[s][m].id;
							b_mux_resp[m] = b_out[s][m].resp;
							m_bvalid[m] = !b_empty[s][m];
							if(m_bvalid[m] && m_bready[m]) begin
								b_pop[s][m] = 1'b1;
								b_unlock[m] = 1'b1;
							end
						end
					end
				end
			end

			m_bresp[m] = b_mux_resp[m];
		end
	end

	//AR Channel
	always_comb begin
		for(int m = 0; m < NUM_MASTERS; m++) begin
			ar_in[m] = {m_arid[m], m_araddr[m], m_arlen[m], m_arsize[m], m_arburst[m]};
			m_arready[m] = arst_n && !ar_full[m];
			ar_push[m] = m_arvalid[m] && m_arready[m];
			ar_dest_slave[m] = decode_addr(ar_out[m].addr);
			dec_arid[m] = ext_arid[m];
			dec_arlen[m] = ar_out[m].len;
			dec_arvalid[m] = 1'b0;
			ar_pop[m] = 1'b0;
		end

		for(int s = 0; s < NUM_SLAVES; s++) begin
			s_arid[s] = '0;
			s_araddr[s] = '0;
			s_arlen[s] = '0;
			s_arsize[s] = '0;
			s_arburst[s] = '0;
			s_arvalid[s] = 1'b0;
			ar_unlock[s] = 1'b0;

			for(int m = 0; m < NUM_MASTERS; m++) begin
				ar_req[s][m] = !ar_empty[m] && (ar_dest_slave[m] == TARGET_WIDTH'(s));
			end

			if(ar_gvalid[s]) begin
				for(int m = 0; m < NUM_MASTERS; m++) begin
					if(ar_gid[s] == MASTER_WIDTH'(m)) begin
						s_arid[s] = ext_arid[m];
						s_araddr[s] = ar_out[m].addr;
						s_arlen[s] = ar_out[m].len;
						s_arsize[s] = ar_out[m].size;
						s_arburst[s] = ar_out[m].burst;
						s_arvalid[s] = !ar_empty[m];

						if(s_arvalid[s] && s_arready[s]) begin
							ar_unlock[s] = 1'b1;
						end
					end
				end
			end
		end

		for(int m = 0; m < NUM_MASTERS; m++) begin
			if(ar_dest_slave[m] == TARGET_WIDTH'(NUM_SLAVES)) begin
				dec_arvalid[m] = !ar_empty[m];
				if(dec_arvalid[m] && dec_arready[m]) begin
					ar_pop[m] = 1'b1;
				end
			end
			else begin
				for(int s = 0; s < NUM_SLAVES; s++) begin
					if((ar_dest_slave[m] == TARGET_WIDTH'(s)) && ar_gvalid[s] && (ar_gid[s] == MASTER_WIDTH'(m)) && s_arvalid[s] && s_arready[s]) begin
						ar_pop[m] = 1'b1;
					end
				end
			end
		end
	end

	//R Channel
	always_comb begin
		for(int s = 0; s < NUM_SLAVES; s++) begin
			r_dest_master[s] = s_rid[s][EXT_ID_WIDTH-1:ID_WIDTH];
			s_rready[s] = 1'b0;
			for(int m = 0; m < NUM_MASTERS; m++) begin
				r_in[s][m] = {s_rid[s], s_rdata[s], s_rresp[s], s_rlast[s]};
				r_push[s][m] = 1'b0;
				if(r_dest_master[s] == MASTER_WIDTH'(m)) begin
					s_rready[s] = arst_n && !r_full[s][m];
					r_push[s][m] = s_rvalid[s] && s_rready[s];
				end
			end
		end

		for(int m = 0; m < NUM_MASTERS; m++) begin
			for(int s = 0; s < NUM_SLAVES; s++) begin
				r_req[m][s] = !r_empty[s][m];
				r_pop[s][m] = 1'b0;
			end
			r_req[m][NUM_SLAVES] = dec_rvalid[m];

			r_mux_id[m] = '0;
			r_mux_data[m] = '0;
			r_mux_resp[m] = '0;
			r_mux_last[m] = 1'b0;
			m_rvalid[m] = 1'b0;
			r_unlock[m] = 1'b0;
			dec_rready[m] = 1'b0;

			if(r_gvalid[m]) begin
				if(r_gid[m] == TARGET_WIDTH'(NUM_SLAVES)) begin
					r_mux_id[m] = dec_rid[m];
					r_mux_data[m] = dec_rdata[m];
					r_mux_resp[m] = dec_rresp[m];
					r_mux_last[m] = dec_rlast[m];
					m_rvalid[m] = dec_rvalid[m];
					if(m_rvalid[m] && m_rready[m]) begin
						dec_rready[m] = 1'b1;
						if(r_mux_last[m]) begin
							r_unlock[m] = 1'b1;
						end
					end
				end
				else begin
					for(int s = 0; s < NUM_SLAVES; s++) begin
						if(r_gid[m] == TARGET_WIDTH'(s)) begin
							r_mux_id[m] = r_out[s][m].id;
							r_mux_data[m] = r_out[s][m].data;
							r_mux_resp[m] = r_out[s][m].resp;
							r_mux_last[m] = r_out[s][m].last;
							m_rvalid[m] = !r_empty[s][m];
							if(m_rvalid[m] && m_rready[m]) begin
								r_pop[s][m] = 1'b1;
								if(r_mux_last[m]) begin
									r_unlock[m] = 1'b1;
								end
							end
						end
					end
				end
			end

			m_rdata[m] = r_mux_data[m];
			m_rresp[m] = r_mux_resp[m];
			m_rlast[m] = r_mux_last[m];
		end
	end

endmodule

