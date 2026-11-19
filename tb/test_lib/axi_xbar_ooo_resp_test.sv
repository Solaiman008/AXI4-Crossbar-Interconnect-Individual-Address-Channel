class axi_xbar_ooo_resp_test extends axi_xbar_base_test;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		super.new(vif_m0, vif_m1, vif_s0, vif_s1);
	endfunction

	task run();
		logic [DATA_WIDTH-1:0] wdata_0[$];
		logic [DATA_WIDTH-1:0] wdata_1[$];
		logic [STRB_WIDTH-1:0] wstrb_q[$];
		logic [DATA_WIDTH-1:0] rdata_0[$];
		logic [DATA_WIDTH-1:0] rdata_1[$];
		logic [1:0] rresp_q[$];
		logic [DATA_WIDTH-1:0] rand_data0;
		logic [DATA_WIDTH-1:0] rand_data1;
		logic [ADDR_WIDTH-1:0] addr_s0;
		logic [ADDR_WIDTH-1:0] addr_s1;
		logic [ADDR_WIDTH-1:0] addr_err;
		logic [ID_WIDTH-1:0] id_0;
		logic [ID_WIDTH-1:0] id_1;

		env.run();
		env.agt_m0.gen.reset();
		env.agt_m1.gen.reset();

		for(int i = 0; i < 3; i++) begin
			repeat(REPEAT_COUNT) begin
				rand_data0 = {$urandom, $urandom};
				rand_data1 = {$urandom, $urandom};
				wdata_0 = {rand_data0};
				wdata_1 = {rand_data1};
				wstrb_q = {'1};
				rdata_0 = {rand_data0};
				rdata_1 = {rand_data1};
				rresp_q = {2'b00};

				id_0 = $urandom_range((1<<ID_WIDTH)-1, 0);
				id_1 = ~id_0;

				addr_s0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

				if(i == 0) begin
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m0.gen.write(id_0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m0.gen.write(id_1, addr_s1, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
						begin
							env.agt_m0.gen.read(id_0, addr_s0, 8'd0, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_s1, 8'd0, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 1) begin
					fork
						begin
							repeat(20) @(posedge vif_s1.aclk);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m0.gen.write(id_0, addr_s1, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m0.gen.write(id_1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s1.aclk);
							env.agt_s1.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						env.agt_s0.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
						begin
							env.agt_m0.gen.read(id_0, addr_s1, 8'd0, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_s0, 8'd0, 3'd3, 2'b01);
						end
					join
				end
				else begin
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m0.gen.write(id_0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m0.gen.write(id_1, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						begin
							env.agt_m0.gen.read(id_0, addr_s0, 8'd0, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_err, 8'd0, 3'd3, 2'b01);
						end
					join
				end
			end
		end

		for(int i = 0; i < 3; i++) begin
			repeat(REPEAT_COUNT) begin
				rand_data0 = {$urandom, $urandom};
				rand_data1 = {$urandom, $urandom};
				wdata_0 = {rand_data0};
				wdata_1 = {rand_data1};
				wstrb_q = {'1};
				rdata_0 = {rand_data0};
				rdata_1 = {rand_data1};
				rresp_q = {2'b00};

				id_0 = $urandom_range((1<<ID_WIDTH)-1, 0);
				id_1 = ~id_0;

				addr_s0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

				if(i == 0) begin
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m1.gen.write(id_0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m1.gen.write(id_1, addr_s1, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
						begin
							env.agt_m1.gen.read(id_0, addr_s0, 8'd0, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_s1, 8'd0, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 1) begin
					fork
						begin
							repeat(20) @(posedge vif_s1.aclk);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m1.gen.write(id_0, addr_s1, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m1.gen.write(id_1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s1.aclk);
							env.agt_s1.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						env.agt_s0.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
						begin
							env.agt_m1.gen.read(id_0, addr_s1, 8'd0, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_s0, 8'd0, 3'd3, 2'b01);
						end
					join
				end
				else begin
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m1.gen.write(id_0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
							env.agt_m1.gen.write(id_1, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
						end
					join
					fork
						begin
							repeat(20) @(posedge vif_s0.aclk);
							env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
						end
						begin
							env.agt_m1.gen.read(id_0, addr_s0, 8'd0, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_err, 8'd0, 3'd3, 2'b01);
						end
					join
				end
			end
		end

		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 2 * 6 * REPEAT_COUNT)
		);
		$display("Out of Order Response Edge Test Complete for M0 and M1");
		env.sb.report();
	endtask

endclass
