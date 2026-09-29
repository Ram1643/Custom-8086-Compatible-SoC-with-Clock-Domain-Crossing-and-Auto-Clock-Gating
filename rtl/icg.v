// ============================================================================
// MODULE: Integrated Clock Gating (ICG) Cell
// ============================================================================
module icg_cell (
    input  wire clk_i,
    input  wire en_i,
    output wire clk_o
);
    reg latched_en;
    
    // Negative-level sensitive latch guarantees glitch-free clock gating
    always @(clk_i or en_i) begin
        if (!clk_i) latched_en <= en_i;
    end
    
    assign clk_o = clk_i & latched_en;
endmodule
