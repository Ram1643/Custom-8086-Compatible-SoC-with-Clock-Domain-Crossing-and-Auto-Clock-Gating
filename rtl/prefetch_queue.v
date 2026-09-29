// ============================================================================
// MODULE 4: Prefetch Queue
// ============================================================================
module prefetch_queue #(parameter DEPTH = 6, parameter DATA_W = 8)(
    input  wire              clk, rst, push,
    input  wire [DATA_W-1:0] din, output wire full,
    input  wire              pop, output reg [DATA_W-1:0] dout, output wire empty
);
    reg [DATA_W-1:0] q_mem [0:DEPTH-1]; reg [2:0] head, tail; reg [3:0] count; 
    always @(posedge clk) begin
        if (rst) begin head <= 0; tail <= 0; count <= 0; end 
        else begin
            if (push && !full) begin q_mem[tail] <= din; tail <= (tail == DEPTH-1) ? 0 : tail + 1; end
            if (pop && !empty) begin head <= (head == DEPTH-1) ? 0 : head + 1; end
            if (push && !full && pop && !empty) count <= count; 
            else if (push && !full) count <= count + 1;
            else if (pop && !empty) count <= count - 1;
        end
    end
    assign full = (count == DEPTH); assign empty = (count == 0);
    always @(*) dout = q_mem[head];
endmodule
