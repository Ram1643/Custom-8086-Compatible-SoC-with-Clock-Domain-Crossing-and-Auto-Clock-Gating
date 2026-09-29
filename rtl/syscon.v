
// ============================================================================
// MODULE 10: System Controller (SYSCON / PMU) - Reset & Clock Manager
// ============================================================================
module system_controller #(parameter DATA_W = 16)(
    input  wire clk, rst,
    input  wire [15:0] wb_adr_i, input wire [DATA_W-1:0] wb_dat_i, output reg [DATA_W-1:0] wb_dat_o,
    input  wire wb_we_i, wb_stb_i, wb_cyc_i, output reg wb_ack_o,
    output reg  ip1_rst_o, output reg ip2_rst_o, output reg ip3_rst_o,
    output reg  ip1_ce_o,  output reg ip2_ce_o,  output reg ip3_ce_o // NEW: Clock Enables
);
    always @(posedge clk) begin
        if (rst) begin
            ip1_rst_o <= 1'b0; ip2_rst_o <= 1'b0; ip3_rst_o <= 1'b0;
            ip1_ce_o  <= 1'b1; ip2_ce_o  <= 1'b1; ip3_ce_o  <= 1'b1; // Clocks default ON
            wb_ack_o <= 1'b0; wb_dat_o <= 16'h0;
        end else begin
            ip1_rst_o <= 1'b0; ip2_rst_o <= 1'b0; ip3_rst_o <= 1'b0; // Resets are 1-cycle pulses
            wb_ack_o <= 1'b0;
            
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    if (wb_adr_i[3:0] == 4'h0) begin
                        ip1_rst_o <= wb_dat_i[0]; 
                        ip2_rst_o <= wb_dat_i[1]; 
                        ip3_rst_o <= wb_dat_i[2]; 
                    end
                    else if (wb_adr_i[3:0] == 4'h1) begin // Offset 0x1: Clock Enable Reg
                        ip1_ce_o <= wb_dat_i[0]; 
                        ip2_ce_o <= wb_dat_i[1]; 
                        ip3_ce_o <= wb_dat_i[2]; 
                    end
                end else begin
                    if (wb_adr_i[3:0] == 4'h1) wb_dat_o <= {13'h0, ip3_ce_o, ip2_ce_o, ip1_ce_o};
                    else wb_dat_o <= 16'h0;
                end
            end
        end
    end
endmodule

