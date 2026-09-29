// ============================================================================
// NEW MODULE C: Wishbone Asynchronous CDC Bridge
// ============================================================================
module wishbone_cdc_bridge #(parameter ADDR_W = 20, parameter DATA_W = 16)(
    input  wire              clk_a, rst_a,
    input  wire [ADDR_W-1:0] s_adr_i, input wire [DATA_W-1:0] s_dat_i, output reg [DATA_W-1:0] s_dat_o,
    input  wire              s_we_i, s_stb_i, s_cyc_i, output reg s_ack_o,

    input  wire              clk_b, rst_b,
    output reg  [ADDR_W-1:0] m_adr_o, output reg [DATA_W-1:0] m_dat_o, input wire [DATA_W-1:0] m_dat_i,
    output reg               m_we_o, m_stb_o, m_cyc_o, input wire m_ack_i
);
    wire cmd_full, cmd_empty, rsp_full, rsp_empty;
    wire [ADDR_W+DATA_W:0] cmd_din = {s_we_i, s_adr_i, s_dat_i};
    wire [ADDR_W+DATA_W:0] cmd_dout;
    wire [DATA_W-1:0]      rsp_dout;
    reg cmd_push, cmd_pop, rsp_push, rsp_pop;

    async_fifo #(.DATA_W(ADDR_W+DATA_W+1), .ADDR_W(4)) cmd_fifo (
        .wclk(clk_a), .wrst(rst_a), .winc(cmd_push), .wdata(cmd_din), .wfull(cmd_full),
        .rclk(clk_b), .rrst(rst_b), .rinc(cmd_pop),  .rdata(cmd_dout), .rempty(cmd_empty)
    );

    async_fifo #(.DATA_W(DATA_W), .ADDR_W(4)) rsp_fifo (
        .wclk(clk_b), .wrst(rst_b), .winc(rsp_push), .wdata(m_dat_i), .wfull(rsp_full),
        .rclk(clk_a), .rrst(rst_a), .rinc(rsp_pop),  .rdata(rsp_dout), .rempty(rsp_empty)
    );

    reg state_a;
    always @(posedge clk_a) begin
        if (rst_a) begin state_a <= 0; s_ack_o <= 0; cmd_push <= 0; rsp_pop <= 0; s_dat_o <= 0; end 
        else begin
            s_ack_o <= 0; cmd_push <= 0; rsp_pop <= 0;
            case (state_a)
                0: if (s_cyc_i && s_stb_i && !s_ack_o && !cmd_full) begin cmd_push <= 1; state_a <= 1; end
                1: if (!rsp_empty) begin rsp_pop <= 1; s_dat_o <= rsp_dout; s_ack_o <= 1; state_a <= 0; end
            endcase
        end
    end

    reg state_b;
    always @(posedge clk_b) begin
        if (rst_b) begin state_b <= 0; m_cyc_o <= 0; m_stb_o <= 0; m_we_o <= 0; cmd_pop <= 0; rsp_push <= 0; end 
        else begin
            cmd_pop <= 0; rsp_push <= 0;
            case (state_b)
                0: if (!cmd_empty && !rsp_full) begin
                       cmd_pop <= 1; m_we_o <= cmd_dout[ADDR_W+DATA_W]; m_adr_o <= cmd_dout[ADDR_W+DATA_W-1 : DATA_W];
                       m_dat_o <= cmd_dout[DATA_W-1 : 0]; m_cyc_o <= 1; m_stb_o <= 1; state_b <= 1;
                   end
                1: if (m_ack_i) begin m_cyc_o <= 0; m_stb_o <= 0; rsp_push <= 1; state_b <= 0; end
            endcase
        end
    end
endmodule

