// ============================================================================
// MODULE 11: WISHBONE INTERCONNECT (4x6 MATRIX)
// ============================================================================
module wishbone_interconnect #(parameter ADDR_W = 20, parameter DATA_W = 16)(
    input  wire [ADDR_W-1:0] m0_adr_i, input  wire [DATA_W-1:0] m0_dat_i, output reg [DATA_W-1:0] m0_dat_o, input wire m0_we_i, m0_stb_i, m0_cyc_i, output reg m0_ack_o, m0_err_o,
    input  wire [ADDR_W-1:0] m1_adr_i, input  wire [DATA_W-1:0] m1_dat_i, output reg [DATA_W-1:0] m1_dat_o, input wire m1_we_i, m1_stb_i, m1_cyc_i, output reg m1_ack_o,
    input  wire [ADDR_W-1:0] m2_adr_i, input  wire [DATA_W-1:0] m2_dat_i, output reg [DATA_W-1:0] m2_dat_o, input wire m2_we_i, m2_stb_i, m2_cyc_i, output reg m2_ack_o,
    input  wire [ADDR_W-1:0] m3_adr_i, input  wire [DATA_W-1:0] m3_dat_i, output reg [DATA_W-1:0] m3_dat_o, input wire m3_we_i, m3_stb_i, m3_cyc_i, output reg m3_ack_o,
    
    output reg  [ADDR_W-1:0] s0_adr_o, output reg  [DATA_W-1:0] s0_dat_o, input  wire [DATA_W-1:0] s0_dat_i, output reg s0_we_o, s0_stb_o, s0_cyc_o, input wire s0_ack_i,
    output reg  [ADDR_W-1:0] s1_adr_o, output reg  [DATA_W-1:0] s1_dat_o, input  wire [DATA_W-1:0] s1_dat_i, output reg s1_we_o, s1_stb_o, s1_cyc_o, input wire s1_ack_i,
    output reg  [ADDR_W-1:0] s2_adr_o, output reg  [DATA_W-1:0] s2_dat_o, input  wire [DATA_W-1:0] s2_dat_i, output reg s2_we_o, s2_stb_o, s2_cyc_o, input wire s2_ack_i,
    output reg  [ADDR_W-1:0] s3_adr_o, output reg  [DATA_W-1:0] s3_dat_o, input  wire [DATA_W-1:0] s3_dat_i, output reg s3_we_o, s3_stb_o, s3_cyc_o, input wire s3_ack_i,
    output reg  [ADDR_W-1:0] s4_adr_o, output reg  [DATA_W-1:0] s4_dat_o, input  wire [DATA_W-1:0] s4_dat_i, output reg s4_we_o, s4_stb_o, s4_cyc_o, input wire s4_ack_i,
    output reg  [ADDR_W-1:0] s5_adr_o, output reg  [DATA_W-1:0] s5_dat_o, input  wire [DATA_W-1:0] s5_dat_i, output reg s5_we_o, s5_stb_o, s5_cyc_o, input wire s5_ack_i
);
    wire [3:0] target_id = m0_adr_i[19:16];

    wire m1_req_s0 = m1_cyc_i & m1_stb_i; wire m2_req_s0 = m2_cyc_i & m2_stb_i; wire m3_req_s0 = m3_cyc_i & m3_stb_i; wire m0_req_s0 = m0_cyc_i & m0_stb_i & (target_id == 4'h0);
    wire m1_gnt = m1_req_s0; wire m2_gnt = m2_req_s0 & !m1_gnt; wire m3_gnt = m3_req_s0 & !m1_gnt & !m2_gnt; wire m0_gnt_s0 = m0_req_s0 & !m1_gnt & !m2_gnt & !m3_gnt;

    always @(*) begin
        s0_cyc_o = m1_gnt | m2_gnt | m3_gnt | m0_gnt_s0; s0_stb_o = m1_gnt | m2_gnt | m3_gnt | m0_gnt_s0;
        s0_we_o  = m1_gnt ? m1_we_i  : m2_gnt ? m2_we_i  : m3_gnt ? m3_we_i  : m0_we_i;
        s0_adr_o = m1_gnt ? m1_adr_i : m2_gnt ? m2_adr_i : m3_gnt ? m3_adr_i : m0_adr_i;
        s0_dat_o = m1_gnt ? m1_dat_i : m2_gnt ? m2_dat_i : m3_gnt ? m3_dat_i : m0_dat_i;
        
        m1_ack_o = 1'b0; m2_ack_o = 1'b0; m3_ack_o = 1'b0;
        if (m1_gnt) m1_ack_o = s0_ack_i; if (m2_gnt) m2_ack_o = s0_ack_i; if (m3_gnt) m3_ack_o = s0_ack_i;
        m1_dat_o = s0_dat_i; m2_dat_o = s0_dat_i; m3_dat_o = s0_dat_i;
    end

    always @(*) begin
        s1_cyc_o = m0_cyc_i & (target_id == 4'h7); s1_stb_o = m0_stb_i & (target_id == 4'h7); s1_we_o = m0_we_i; s1_adr_o = m0_adr_i; s1_dat_o = m0_dat_i;
        s2_cyc_o = m0_cyc_i & (target_id == 4'h1); s2_stb_o = m0_stb_i & (target_id == 4'h1); s2_we_o = m0_we_i; s2_adr_o = m0_adr_i; s2_dat_o = m0_dat_i;
        s3_cyc_o = m0_cyc_i & (target_id == 4'h2); s3_stb_o = m0_stb_i & (target_id == 4'h2); s3_we_o = m0_we_i; s3_adr_o = m0_adr_i; s3_dat_o = m0_dat_i;
        s4_cyc_o = m0_cyc_i & (target_id == 4'h3); s4_stb_o = m0_stb_i & (target_id == 4'h3); s4_we_o = m0_we_i; s4_adr_o = m0_adr_i; s4_dat_o = m0_dat_i;
        s5_cyc_o = m0_cyc_i & (target_id == 4'h5); s5_stb_o = m0_stb_i & (target_id == 4'h5); s5_we_o = m0_we_i; s5_adr_o = m0_adr_i; s5_dat_o = m0_dat_i;
    end

    always @(*) begin
        m0_err_o = 1'b0; m0_dat_o = 16'h0; m0_ack_o = 1'b0;
        if (m0_cyc_i && m0_we_i && ((m0_adr_i >= 20'h400 && m0_adr_i <= 20'h47F) || (m0_adr_i >= 20'h500 && m0_adr_i <= 20'h57F) || (m0_adr_i >= 20'h600 && m0_adr_i <= 20'h67F))) begin
            m0_err_o = 1'b1; m0_ack_o = 1'b1; 
        end else if (m0_cyc_i && m0_stb_i) begin
            case (target_id)
                4'h0: begin m0_dat_o = s0_dat_i; m0_ack_o = m0_gnt_s0 ? s0_ack_i : 1'b0; end 
                4'h1: begin m0_dat_o = s2_dat_i; m0_ack_o = s2_ack_i; end 
                4'h2: begin m0_dat_o = s3_dat_i; m0_ack_o = s3_ack_i; end 
                4'h3: begin m0_dat_o = s4_dat_i; m0_ack_o = s4_ack_i; end 
                4'h5: begin m0_dat_o = s5_dat_i; m0_ack_o = s5_ack_i; end 
                4'h7: begin m0_dat_o = s1_dat_i; m0_ack_o = s1_ack_i; end 
                default: begin m0_err_o = 1'b1; m0_ack_o = 1'b1; end 
            endcase
        end
    end
endmodule

