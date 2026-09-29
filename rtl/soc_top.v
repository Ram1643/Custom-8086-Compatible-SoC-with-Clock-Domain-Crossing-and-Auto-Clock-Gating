// ============================================================================
// MODULE 14: SOC TOP (With CDC Bridges)
// ============================================================================
module soc_top #(parameter V_ADDR = 16, parameter P_ADDR = 20, parameter DATA_W = 16, parameter MAIN_MEM_BYTES = 4096)(
    input  wire clk_cpu_200, clk_dma_150, clk_mem_100, rst_i, 
    input  wire tlb_wr_en, input wire [11:0] tlb_wr_v_tag, input wire [15:0] tlb_wr_p_tag
);
    wire [P_ADDR-1:0] m0_adr, m1_adr, m2_adr, m3_adr; 
    wire [DATA_W-1:0] m0_dat_c2m, m0_dat_m2c, m1_dat_c2m, m1_dat_m2c, m2_dat_c2m, m2_dat_m2c, m3_dat_c2m, m3_dat_m2c;
    wire m0_we, m0_stb, m0_cyc, m0_ack, m0_err, m1_we, m1_stb, m1_cyc, m1_ack, m2_we, m2_stb, m2_cyc, m2_ack, m3_we, m3_stb, m3_cyc, m3_ack;
    
    wire [P_ADDR-1:0] s0_adr, s1_adr, s2_adr, s3_adr, s4_adr, s5_adr; 
    wire [DATA_W-1:0] s0_dat_o, s0_dat_i, s1_dat_o, s1_dat_i, s2_dat_o, s2_dat_i, s3_dat_o, s3_dat_i, s4_dat_o, s4_dat_i, s5_dat_o, s5_dat_i; 
    wire s0_we, s0_stb, s0_cyc, s0_ack, s1_we, s1_stb, s1_cyc, s1_ack, s2_we, s2_stb, s2_cyc, s2_ack, s3_we, s3_stb, s3_cyc, s3_ack, s4_we, s4_stb, s4_cyc, s4_ack, s5_we, s5_stb, s5_cyc, s5_ack;
    
    wire t1, t2, t3; wire d1, d2, d3; wire intr_cpu;
    wire soft_rst_ip1, soft_rst_ip2, soft_rst_ip3;
    wire ce_ip1, ce_ip2, ce_ip3;
    custom_8086_core #(.V_ADDR(V_ADDR), .P_ADDR(P_ADDR), .DATA_W(DATA_W)) cpu_core (
        .clk_i(clk_cpu_200), .rst_i(rst_i), .tlb_wr_en(tlb_wr_en), .tlb_wr_v_tag(tlb_wr_v_tag), .tlb_wr_p_tag(tlb_wr_p_tag),
        .wb_adr_o(m0_adr), .wb_dat_o(m0_dat_c2m), .wb_dat_i(m0_dat_m2c), .wb_we_o(m0_we), .wb_stb_o(m0_stb), .wb_cyc_o(m0_cyc), .wb_ack_i(m0_ack), .wb_err_i(m0_err),
        .trig1_o(t1), .trig2_o(t2), .trig3_o(t3), .intr_i(intr_cpu), .ip_done_i({d3, d2, d1})
    );

    /*system_controller #(.DATA_W(DATA_W)) syscon_inst (
        .clk(clk_cpu_200), .rst(rst_i),
        .wb_adr_i(s5_adr[15:0]), .wb_dat_i(s5_dat_o), .wb_dat_o(s5_dat_i), .wb_we_i(s5_we), .wb_stb_i(s5_stb), .wb_cyc_i(s5_cyc), .wb_ack_o(s5_ack),
        .ip1_rst_o(soft_rst_ip1), .ip2_rst_o(soft_rst_ip2), .ip3_rst_o(soft_rst_ip3)
    );*/
    system_controller #(.DATA_W(DATA_W)) syscon_inst (
        .clk(clk_cpu_200), .rst(rst_i),
        .wb_adr_i(s5_adr[15:0]), .wb_dat_i(s5_dat_o), .wb_dat_o(s5_dat_i), .wb_we_i(s5_we), .wb_stb_i(s5_stb), .wb_cyc_i(s5_cyc), .wb_ack_o(s5_ack),
        .ip1_rst_o(soft_rst_ip1), .ip2_rst_o(soft_rst_ip2), .ip3_rst_o(soft_rst_ip3),
        .ip1_ce_o(ce_ip1), .ip2_ce_o(ce_ip2), .ip3_ce_o(ce_ip3) // FIXED: Connected outputs
    );
    // Interconnect runs on the Combinational Logic path 
    wishbone_interconnect #(.ADDR_W(P_ADDR), .DATA_W(DATA_W)) interconn (
        .m0_adr_i(m0_adr), .m0_dat_i(m0_dat_c2m), .m0_dat_o(m0_dat_m2c), .m0_we_i(m0_we), .m0_stb_i(m0_stb), .m0_cyc_i(m0_cyc), .m0_ack_o(m0_ack), .m0_err_o(m0_err),
        .m1_adr_i(m1_adr), .m1_dat_i(m1_dat_c2m), .m1_dat_o(m1_dat_m2c), .m1_we_i(m1_we), .m1_stb_i(m1_stb), .m1_cyc_i(m1_cyc), .m1_ack_o(m1_ack),
        .m2_adr_i(m2_adr), .m2_dat_i(m2_dat_c2m), .m2_dat_o(m2_dat_m2c), .m2_we_i(m2_we), .m2_stb_i(m2_stb), .m2_cyc_i(m2_cyc), .m2_ack_o(m2_ack),
        .m3_adr_i(m3_adr), .m3_dat_i(m3_dat_c2m), .m3_dat_o(m3_dat_m2c), .m3_we_i(m3_we), .m3_stb_i(m3_stb), .m3_cyc_i(m3_cyc), .m3_ack_o(m3_ack),
        .s0_adr_o(s0_adr), .s0_dat_o(s0_dat_o), .s0_dat_i(s0_dat_i), .s0_we_o(s0_we), .s0_stb_o(s0_stb), .s0_cyc_o(s0_cyc), .s0_ack_i(s0_ack),
        .s1_adr_o(s1_adr), .s1_dat_o(s1_dat_o), .s1_dat_i(s1_dat_i), .s1_we_o(s1_we), .s1_stb_o(s1_stb), .s1_cyc_o(s1_cyc), .s1_ack_i(s1_ack),
        .s2_adr_o(s2_adr), .s2_dat_o(s2_dat_o), .s2_dat_i(s2_dat_i), .s2_we_o(s2_we), .s2_stb_o(s2_stb), .s2_cyc_o(s2_cyc), .s2_ack_i(s2_ack),
        .s3_adr_o(s3_adr), .s3_dat_o(s3_dat_o), .s3_dat_i(s3_dat_i), .s3_we_o(s3_we), .s3_stb_o(s3_stb), .s3_cyc_o(s3_cyc), .s3_ack_i(s3_ack),
        .s4_adr_o(s4_adr), .s4_dat_o(s4_dat_o), .s4_dat_i(s4_dat_i), .s4_we_o(s4_we), .s4_stb_o(s4_stb), .s4_cyc_o(s4_cyc), .s4_ack_i(s4_ack),
        .s5_adr_o(s5_adr), .s5_dat_o(s5_dat_o), .s5_dat_i(s5_dat_i), .s5_we_o(s5_we), .s5_stb_o(s5_stb), .s5_cyc_o(s5_cyc), .s5_ack_i(s5_ack)
    );

    // Memory gets 150 MHz Write, 100 MHz Read
    dual_clock_main_memory #(.ADDR_W(P_ADDR), .DATA_W(DATA_W), .MEM_SIZE(4096)) main_memory (
        .rst_i(rst_i), 
        .clk_w_150(clk_dma_150), .wb_wr_adr_i(s0_adr), .wb_wr_dat_i(s0_dat_o), .wb_wr_we_i(s0_we), .wb_wr_stb_i(s0_stb), .wb_wr_cyc_i(s0_cyc), .wb_wr_ack_o(s0_ack),
        .clk_r_100(clk_mem_100), .wb_rd_adr_i(s0_adr), .wb_rd_dat_o(s0_dat_i), .wb_rd_stb_i(s0_stb), .wb_rd_cyc_i(s0_cyc)
    );

    // --- CDC BRIDGES AND IPs ---
    wire [19:0] b1_adr, b2_adr, b3_adr;
    wire [15:0] b1_d_m2s, b1_d_s2m, b2_d_m2s, b2_d_s2m, b3_d_m2s, b3_d_s2m;
    wire b1_we, b1_stb, b1_cyc, b1_ack, b2_we, b2_stb, b2_cyc, b2_ack, b3_we, b3_stb, b3_cyc, b3_ack;
        wishbone_cdc_bridge #(.ADDR_W(P_ADDR), .DATA_W(DATA_W)) ip1_bridge (
        .clk_a(clk_cpu_200), .rst_a(rst_i), .s_adr_i(s2_adr), .s_dat_i(s2_dat_o), .s_dat_o(s2_dat_i), .s_we_i(s2_we), .s_stb_i(s2_stb), .s_cyc_i(s2_cyc), .s_ack_o(s2_ack),
        .clk_b(clk_dma_150), .rst_b(rst_i), .m_adr_o(b1_adr), .m_dat_o(b1_d_m2s), .m_dat_i(b1_d_s2m), .m_we_o(b1_we), .m_stb_o(b1_stb), .m_cyc_o(b1_cyc), .m_ack_i(b1_ack)
    );
    ip_controller #(.BASE_ADDR(20'h00200), .MAX_WORDS(16'd64)) slave_ctrl_1 (
        .clk(clk_dma_150), .rst(rst_i | soft_rst_ip1), .cpu_trigger_i(t1), .cpu_done_o(d1),.sys_clk_en_i(ce_ip1), 
        .m_cyc_o(m1_cyc), .m_stb_o(m1_stb), .m_we_o(m1_we), .m_adr_o(m1_adr), .m_dat_o(m1_dat_c2m), .m_ack_i(m1_ack), 
        .s_cyc_i(b1_cyc), .s_stb_i(b1_stb), .s_we_i(b1_we), .s_adr_i(b1_adr), .s_dat_i(b1_d_m2s), .s_dat_o(b1_d_s2m), .s_ack_o(b1_ack)
    );

    wishbone_cdc_bridge #(.ADDR_W(P_ADDR), .DATA_W(DATA_W)) ip2_bridge (
        .clk_a(clk_cpu_200), .rst_a(rst_i), .s_adr_i(s3_adr), .s_dat_i(s3_dat_o), .s_dat_o(s3_dat_i), .s_we_i(s3_we), .s_stb_i(s3_stb), .s_cyc_i(s3_cyc), .s_ack_o(s3_ack),
        .clk_b(clk_dma_150), .rst_b(rst_i), .m_adr_o(b2_adr), .m_dat_o(b2_d_m2s), .m_dat_i(b2_d_s2m), .m_we_o(b2_we), .m_stb_o(b2_stb), .m_cyc_o(b2_cyc), .m_ack_i(b2_ack)
    );
    ip_controller #(.BASE_ADDR(20'h00280), .MAX_WORDS(16'd64)) slave_ctrl_2 (
        .clk(clk_dma_150), .rst(rst_i | soft_rst_ip2), .cpu_trigger_i(t2), .cpu_done_o(d2),.sys_clk_en_i(ce_ip2), 
        .m_cyc_o(m2_cyc), .m_stb_o(m2_stb), .m_we_o(m2_we), .m_adr_o(m2_adr), .m_dat_o(m2_dat_c2m), .m_ack_i(m2_ack), 
        .s_cyc_i(b2_cyc), .s_stb_i(b2_stb), .s_we_i(b2_we), .s_adr_i(b2_adr), .s_dat_i(b2_d_m2s), .s_dat_o(b2_d_s2m), .s_ack_o(b2_ack)
    );

    wishbone_cdc_bridge #(.ADDR_W(P_ADDR), .DATA_W(DATA_W)) ip3_bridge (
        .clk_a(clk_cpu_200), .rst_a(rst_i), .s_adr_i(s4_adr), .s_dat_i(s4_dat_o), .s_dat_o(s4_dat_i), .s_we_i(s4_we), .s_stb_i(s4_stb), .s_cyc_i(s4_cyc), .s_ack_o(s4_ack),
        .clk_b(clk_dma_150), .rst_b(rst_i), .m_adr_o(b3_adr), .m_dat_o(b3_d_m2s), .m_dat_i(b3_d_s2m), .m_we_o(b3_we), .m_stb_o(b3_stb), .m_cyc_o(b3_cyc), .m_ack_i(b3_ack)
    );
    ip_controller #(.BASE_ADDR(20'h00300), .MAX_WORDS(16'd64)) slave_ctrl_3 (
        .clk(clk_dma_150), .rst(rst_i | soft_rst_ip3), .cpu_trigger_i(t3), .cpu_done_o(d3),.sys_clk_en_i(ce_ip3), 
        .m_cyc_o(m3_cyc), .m_stb_o(m3_stb), .m_we_o(m3_we), .m_adr_o(m3_adr), .m_dat_o(m3_dat_c2m), .m_ack_i(m3_ack), 
        .s_cyc_i(b3_cyc), .s_stb_i(b3_stb), .s_we_i(b3_we), .s_adr_i(b3_adr), .s_dat_i(b3_d_m2s), .s_dat_o(b3_d_s2m), .s_ack_o(b3_ack)
    );

    programmable_interrupt_controller #(.DATA_W(DATA_W)) pic (
        .clk(clk_cpu_200), .rst(rst_i), .ip_irq_i({d3, d2, d1}), .cpu_intr_o(intr_cpu),
        .wb_adr_i(s1_adr[15:0]), .wb_dat_i(s1_dat_o), .wb_dat_o(s1_dat_i), .wb_we_i(s1_we), .wb_stb_i(s1_stb), .wb_cyc_i(s1_cyc), .wb_ack_o(s1_ack)
    );
endmodule

