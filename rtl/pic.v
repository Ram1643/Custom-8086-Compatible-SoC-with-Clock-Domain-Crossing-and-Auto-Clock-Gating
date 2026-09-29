// ============================================================================
// MODULE 9: Programmable Interrupt Controller (PIC) 
// ============================================================================
module programmable_interrupt_controller #(parameter DATA_W = 16)(
    input  wire clk, rst, input  wire [2:0] ip_irq_i, output wire cpu_intr_o,
    input  wire [15:0] wb_adr_i, input  wire [DATA_W-1:0] wb_dat_i, output reg  [DATA_W-1:0] wb_dat_o,
    input  wire wb_we_i, input  wire wb_stb_i, input  wire wb_cyc_i, output reg wb_ack_o
);
    reg [2:0] irq_pending; reg [2:0] irq_mask; reg global_en; reg [2:0] ip_irq_sync;
    assign cpu_intr_o = global_en ? |(irq_pending & irq_mask) : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin ip_irq_sync <= 0; irq_pending <= 0; end 
        else begin
            ip_irq_sync <= ip_irq_i;
            if (ip_irq_i[0] && !ip_irq_sync[0]) irq_pending[0] <= 1'b1;
            if (ip_irq_i[1] && !ip_irq_sync[1]) irq_pending[1] <= 1'b1;
            if (ip_irq_i[2] && !ip_irq_sync[2]) irq_pending[2] <= 1'b1;
            if (wb_cyc_i && wb_stb_i && wb_we_i && (wb_adr_i[3:0] == 4'h2)) irq_pending <= irq_pending & ~wb_dat_i[2:0];
        end
    end

    always @(posedge clk) begin
        if (rst) begin wb_ack_o <= 0; wb_dat_o <= 0; irq_mask <= 0; global_en <= 0; end 
        else begin
            wb_ack_o <= 0; 
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1; 
                if (wb_we_i) begin
                    if (wb_adr_i[3:0] == 4'h1) irq_mask  <= wb_dat_i[2:0];
                    if (wb_adr_i[3:0] == 4'h3) global_en <= wb_dat_i[0];
                end else begin
                    case (wb_adr_i[3:0])
                        4'h0: wb_dat_o <= {13'h0, (irq_pending & irq_mask)};
                        4'h1: wb_dat_o <= {13'h0, irq_mask};                 
                        4'h3: wb_dat_o <= {15'h0, global_en};                
                        default: wb_dat_o <= 0;
                    endcase
                end
            end
        end
    end
endmodule
