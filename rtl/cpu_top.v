// ============================================================================
// MODULE 13: CUSTOM 8086 CORE WRAPPER
// ============================================================================
module custom_8086_core #(parameter V_ADDR = 16, parameter P_ADDR = 20, parameter DATA_W = 16)(
    input  wire              clk_i, rst_i, tlb_wr_en,
    input  wire [11:0]       tlb_wr_v_tag, input  wire [15:0] tlb_wr_p_tag,
    output wire [P_ADDR-1:0] wb_adr_o, output wire [DATA_W-1:0] wb_dat_o, input  wire [DATA_W-1:0] wb_dat_i,
    output wire              wb_we_o, output wire wb_stb_o, output wire wb_cyc_o, input  wire wb_ack_i,
    input  wire              wb_err_i, output wire trig1_o, trig2_o, trig3_o, input  wire intr_i,
    input  wire [2:0]        ip_done_i
);
    wire [V_ADDR-1:0] d_addr; wire [DATA_W-1:0] d_wdata, d_rdata; wire d_req, d_we, d_rdy;
    wire q_empty, q_pop; wire [7:0] q_dout; wire cache_en, tlb_en;
    wire branch_en; wire [15:0] branch_addr;

    execution_unit #(.DATA_W(DATA_W), .ADDR_W(V_ADDR)) eu_inst (
        .clk(clk_i), .rst(rst_i), .q_empty(q_empty), .q_dout(q_dout), .q_pop(q_pop),
        .d_addr(d_addr), .d_wdata(d_wdata), .d_req(d_req), .d_we(d_we), .d_rdata(d_rdata), .d_rdy(d_rdy), .wb_err_i(wb_err_i),
        .cache_en_o(cache_en), .tlb_en_o(tlb_en), 
        .trig1_o(trig1_o), .trig2_o(trig2_o), .trig3_o(trig3_o), .intr_i(intr_i),
        .ip_done_i(ip_done_i), .branch_en(branch_en), .branch_addr(branch_addr)
    );

    bus_interface_unit #(.V_ADDR(V_ADDR), .P_ADDR(P_ADDR), .D_W(DATA_W)) biu_inst (
        .clk(clk_i), .rst(rst_i), .q_empty(q_empty), .q_dout(q_dout), .q_pop(q_pop),
        .eu_d_addr(d_addr), .eu_d_wdata(d_wdata), .eu_d_req(d_req), .eu_d_we(d_we), .eu_d_rdata(d_rdata), .eu_d_rdy(d_rdy),
        .cache_en_i(cache_en), .tlb_en_i(tlb_en), .tlb_wr_en(tlb_wr_en), .tlb_wr_v_tag(tlb_wr_v_tag), .tlb_wr_p_tag(tlb_wr_p_tag),
        .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i), .wb_we_o(wb_we_o), .wb_stb_o(wb_stb_o), .wb_cyc_o(wb_cyc_o), .wb_ack_i(wb_ack_i),
        .branch_en(branch_en), .branch_addr(branch_addr)
    );
endmodule

