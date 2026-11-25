import axi_xbar_param_pkg::*;

interface axi_xbar_if #(ID_W = ID_WIDTH) (input aclk);
	logic arst_n;

	logic [ID_W-1:0] awid;
	logic [ADDR_WIDTH-1:0] awaddr;
	logic [7:0] awlen;
	logic [2:0] awsize;
	logic [1:0] awburst;
	logic awvalid;
	logic awready;

	logic [DATA_WIDTH-1:0] wdata;
	logic [STRB_WIDTH-1:0] wstrb;
	logic wlast;
	logic wvalid;
	logic wready;

	logic [ID_W-1:0] bid;
	logic [1:0] bresp;
	logic bvalid;
	logic bready;

	logic [ID_W-1:0] arid;
	logic [ADDR_WIDTH-1:0] araddr;
	logic [7:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	logic arvalid;
	logic arready;

	logic [ID_W-1:0] rid;
	logic [DATA_WIDTH-1:0] rdata;
	logic [1:0] rresp;
	logic rlast;
	logic rvalid;
	logic rready;


	property p_rst_valids_low;
		@(posedge aclk)
		(!arst_n) |-> (!awvalid && !wvalid && !bvalid && !arvalid && !rvalid);
	endproperty
	a_rst_valids_low: assert property (p_rst_valids_low)
		else $error("[SVA][%m] VALID remained high during reset at time %0d", $time);

	property p_no_x_handshakes;
		@(posedge aclk) disable iff (!arst_n)
		!$isunknown({awvalid, awready, wvalid, wready, bvalid, bready, arvalid, arready, rvalid, rready});
	endproperty
	a_no_x_handshakes: assert property (p_no_x_handshakes)
		else $error("[SVA][%m] X/Z detected on handshake signals at time %0d", $time);

	property p_aw_no_x;
		@(posedge aclk) disable iff (!arst_n)
		awvalid |-> !$isunknown({awid, awaddr, awlen, awsize, awburst});
	endproperty
	a_aw_no_x: assert property (p_aw_no_x)
		else $error("[SVA][%m] X/Z on AW payload when AWVALID=1 at time %0d", $time);

	property p_aw_stable;
		@(posedge aclk) disable iff (!arst_n)
		(awvalid && !awready) |=> (awvalid && $stable(awid) && $stable(awaddr) && $stable(awlen) && $stable(awsize) && $stable(awburst));
	endproperty
	a_aw_stable: assert property (p_aw_stable)
		else $error("[SVA][%m] AW channel violated handshake stability at time %0d", $time);

	property p_aw_burst_size_legal;
		@(posedge aclk) disable iff (!arst_n)
		awvalid |-> ((awburst != 2'b11) && ((1 << awsize) <= STRB_WIDTH));
	endproperty
	a_aw_burst_size_legal: assert property (p_aw_burst_size_legal)
		else $error("[SVA][%m] Illegal AWBURST or AWSIZE detected at time %0d", $time);

	property p_w_no_x;
		@(posedge aclk) disable iff (!arst_n)
		wvalid |-> !$isunknown({wdata, wstrb, wlast});
	endproperty
	a_w_no_x: assert property (p_w_no_x)
		else $error("[SVA][%m] X/Z on W payload when WVALID=1 at time %0d", $time);

	property p_w_stable;
		@(posedge aclk) disable iff (!arst_n)
		(wvalid && !wready) |=> (wvalid && $stable(wdata) && $stable(wstrb) && $stable(wlast));
	endproperty
	a_w_stable: assert property (p_w_stable)
		else $error("[SVA][%m] W channel violated handshake stability at time %0d", $time);

	property p_b_no_x;
		@(posedge aclk) disable iff (!arst_n)
		bvalid |-> !$isunknown({bid, bresp});
	endproperty
	a_b_no_x: assert property (p_b_no_x)
		else $error("[SVA][%m] X/Z on B payload when BVALID=1 at time %0d", $time);

	property p_b_stable;
		@(posedge aclk) disable iff (!arst_n)
		(bvalid && !bready) |=> (bvalid && $stable(bid) && $stable(bresp));
	endproperty
	a_b_stable: assert property (p_b_stable)
		else $error("[SVA][%m] B channel violated handshake stability at time %0d", $time);

	property p_bresp_legal;
		@(posedge aclk) disable iff (!arst_n)
		bvalid |-> (bresp != 2'b01);
	endproperty
	a_bresp_legal: assert property (p_bresp_legal)
		else $error("[SVA][%m] Illegal EXOKAY BRESP detected at time %0d", $time);

	property p_ar_no_x;
		@(posedge aclk) disable iff (!arst_n)
		arvalid |-> !$isunknown({arid, araddr, arlen, arsize, arburst});
	endproperty
	a_ar_no_x: assert property (p_ar_no_x)
		else $error("[SVA][%m] X/Z on AR payload when ARVALID=1 at time %0d", $time);

	property p_ar_stable;
		@(posedge aclk) disable iff (!arst_n)
		(arvalid && !arready) |=> (arvalid && $stable(arid) && $stable(araddr) && $stable(arlen) && $stable(arsize) && $stable(arburst));
	endproperty
	a_ar_stable: assert property (p_ar_stable)
		else $error("[SVA][%m] AR channel violated handshake stability at time %0d", $time);

	property p_ar_burst_size_legal;
		@(posedge aclk) disable iff (!arst_n)
		arvalid |-> ((arburst != 2'b11) && ((1 << arsize) <= STRB_WIDTH));
	endproperty
	a_ar_burst_size_legal: assert property (p_ar_burst_size_legal)
		else $error("[SVA][%m] Illegal ARBURST or ARSIZE detected at time %0d", $time);

	property p_r_no_x;
		@(posedge aclk) disable iff (!arst_n)
		rvalid |-> !$isunknown({rid, rdata, rresp, rlast});
	endproperty
	a_r_no_x: assert property (p_r_no_x)
		else $error("[SVA][%m] X/Z on R payload when RVALID=1 at time %0d", $time);

	property p_r_stable;
		@(posedge aclk) disable iff (!arst_n)
		(rvalid && !rready) |=> (rvalid && $stable(rid) && $stable(rdata) && $stable(rresp) && $stable(rlast));
	endproperty
	a_r_stable: assert property (p_r_stable)
		else $error("[SVA][%m] R channel violated handshake stability at time %0d", $time);

	property p_rresp_legal;
		@(posedge aclk) disable iff (!arst_n)
		rvalid |-> (rresp != 2'b01);
	endproperty
	a_rresp_legal: assert property (p_rresp_legal)
		else $error("[SVA][%m] Illegal EXOKAY RRESP detected at time %0d", $time);
	

	int unsigned cov_rst_valids_low = 0;
	int unsigned cov_no_x_handshakes = 0;
	int unsigned cov_aw_no_x = 0;
	int unsigned cov_aw_stable = 0;
	int unsigned cov_aw_burst_size_legal = 0;
	int unsigned cov_w_no_x = 0;
	int unsigned cov_w_stable = 0;
	int unsigned cov_b_no_x = 0;
	int unsigned cov_b_stable = 0;
	int unsigned cov_bresp_legal = 0;
	int unsigned cov_ar_no_x = 0;
	int unsigned cov_ar_stable = 0;
	int unsigned cov_ar_burst_size_legal = 0;
	int unsigned cov_r_no_x = 0;
	int unsigned cov_r_stable = 0;
	int unsigned cov_rresp_legal = 0;

	always @(posedge aclk) begin
		if (!arst_n) begin
			cov_rst_valids_low++;
		end else begin
			cov_no_x_handshakes++;
			if (awvalid) begin
				cov_aw_no_x++;
				cov_aw_burst_size_legal++;
				if (!awready) cov_aw_stable++;
			end
			if (wvalid) begin
				cov_w_no_x++;
				if (!wready) cov_w_stable++;
			end
			if (bvalid) begin
				cov_b_no_x++;
				cov_bresp_legal++;
				if (!bready) cov_b_stable++;
			end
			if (arvalid) begin
				cov_ar_no_x++;
				cov_ar_burst_size_legal++;
				if (!arready) cov_ar_stable++;
			end
			if (rvalid) begin
				cov_r_no_x++;
				cov_rresp_legal++;
				if (!rready) cov_r_stable++;
			end
		end
	end

	final begin
		$display("[SVA_COV][%m] rst_valids_low=%0d", cov_rst_valids_low);
		$display("[SVA_COV][%m] no_x_handshakes=%0d", cov_no_x_handshakes);
		$display("[SVA_COV][%m] aw_no_x=%0d", cov_aw_no_x);
		$display("[SVA_COV][%m] aw_stable=%0d", cov_aw_stable);
		$display("[SVA_COV][%m] aw_burst_size_legal=%0d", cov_aw_burst_size_legal);
		$display("[SVA_COV][%m] w_no_x=%0d", cov_w_no_x);
		$display("[SVA_COV][%m] w_stable=%0d", cov_w_stable);
		$display("[SVA_COV][%m] b_no_x=%0d", cov_b_no_x);
		$display("[SVA_COV][%m] b_stable=%0d", cov_b_stable);
		$display("[SVA_COV][%m] bresp_legal=%0d", cov_bresp_legal);
		$display("[SVA_COV][%m] ar_no_x=%0d", cov_ar_no_x);
		$display("[SVA_COV][%m] ar_stable=%0d", cov_ar_stable);
		$display("[SVA_COV][%m] ar_burst_size_legal=%0d", cov_ar_burst_size_legal);
		$display("[SVA_COV][%m] r_no_x=%0d", cov_r_no_x);
		$display("[SVA_COV][%m] r_stable=%0d", cov_r_stable);
		$display("[SVA_COV][%m] rresp_legal=%0d", cov_rresp_legal);
	end

endinterface
