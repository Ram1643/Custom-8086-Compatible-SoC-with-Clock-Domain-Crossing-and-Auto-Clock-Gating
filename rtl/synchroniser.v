// ============================================================================
// NEW MODULE A: CDC Pointer Synchronizer (2-Stage)
// ============================================================================
module pointer_sync #(parameter ADDR_W = 4)(
    input  wire              clk,
    input  wire              rst,
    input  wire [ADDR_W:0]   ptr_in,
    output reg  [ADDR_W:0]   ptr_out
);
    reg [ADDR_W:0] sync1;
    always @(posedge clk) begin
        if (rst) begin
            sync1   <= 0;
            ptr_out <= 0;
        end else begin
            sync1   <= ptr_in;
            ptr_out <= sync1;
        end
    end
endmodule
