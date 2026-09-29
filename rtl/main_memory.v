// ============================================================================
// MODULE 12: ASYNCHRONOUS DUAL-PORT MAIN MEMORY (150MHz Write / 100MHz Read)
// ============================================================================
module dual_clock_main_memory #(parameter ADDR_W = 20, parameter DATA_W = 16, parameter MEM_SIZE = 4096)(
    input  wire rst_i,
    input  wire              clk_w_150,
    input  wire [ADDR_W-1:0] wb_wr_adr_i, input wire [DATA_W-1:0] wb_wr_dat_i, 
    input  wire              wb_wr_we_i, wb_wr_stb_i, wb_wr_cyc_i, output reg wb_wr_ack_o,

    input  wire              clk_r_100,
    input  wire [ADDR_W-1:0] wb_rd_adr_i, output reg [DATA_W-1:0] wb_rd_dat_o,
    input  wire              wb_rd_stb_i, wb_rd_cyc_i, output reg wb_rd_ack_o
);
    reg [DATA_W-1:0] ram [0:MEM_SIZE-1];
    wire [$clog2(MEM_SIZE)-1:0] wr_idx = wb_wr_adr_i[$clog2(MEM_SIZE)-1:0];
    wire [$clog2(MEM_SIZE)-1:0] rd_idx = wb_rd_adr_i[$clog2(MEM_SIZE)-1:0];

    always @(posedge clk_w_150) begin
        if (rst_i) wb_wr_ack_o <= 1'b0;
        else begin
            wb_wr_ack_o <= 1'b0; 
            if (wb_wr_cyc_i && wb_wr_stb_i && wb_wr_we_i && !wb_wr_ack_o) begin
                ram[wr_idx] <= wb_wr_dat_i; wb_wr_ack_o <= 1'b1; 
            end
        end
    end

    always @(posedge clk_r_100) begin
        if (rst_i) begin wb_rd_ack_o <= 1'b0; wb_rd_dat_o <= 0; end 
        else begin
            wb_rd_ack_o <= 1'b0; 
            // FIXED: Removed the undeclared !wb_rd_we_i check
            if (wb_rd_cyc_i && wb_rd_stb_i && !wb_rd_ack_o) begin
                wb_rd_dat_o <= ram[rd_idx]; wb_rd_ack_o <= 1'b1; 
            end
        end
    end
endmodule

