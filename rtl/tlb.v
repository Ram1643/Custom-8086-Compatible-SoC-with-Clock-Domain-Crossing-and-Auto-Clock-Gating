// ============================================================================
// MODULE 2: Translation Lookaside Buffer (TLB)
// ============================================================================
module tlb_array #(parameter V_TAG_W = 12, parameter P_TAG_W = 16, parameter ENTRIES = 8)(
    input  wire               clk, rst, req,
    input  wire [V_TAG_W-1:0] v_tag, output reg  [P_TAG_W-1:0] p_tag, output reg hit, miss,
    input  wire               wr_en, input  wire [V_TAG_W-1:0] wr_v_tag, input  wire [P_TAG_W-1:0] wr_p_tag
);
    reg [V_TAG_W-1:0] v_array [0:ENTRIES-1];
    reg [P_TAG_W-1:0] p_array [0:ENTRIES-1];
    reg               valid   [0:ENTRIES-1];
    reg [2:0]         replace_ptr;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            replace_ptr <= 3'b000;
            for (i = 0; i < ENTRIES; i = i + 1) valid[i] <= 1'b0;
        end else if (wr_en) begin
            valid[replace_ptr]   <= 1'b1;
            v_array[replace_ptr] <= wr_v_tag;
            p_array[replace_ptr] <= wr_p_tag;
            replace_ptr <= replace_ptr + 3'b001;
        end
    end

    always @(*) begin
        hit = 1'b0; miss = 1'b0; p_tag = {P_TAG_W{1'b0}};
        if (req) begin
            miss = 1'b1;
            for (i = 0; i < ENTRIES; i = i + 1) begin
                if (valid[i] && (v_array[i] == v_tag)) begin
                    hit = 1'b1; miss = 1'b0; p_tag = p_array[i];
                end
            end
        end
    end
endmodule
