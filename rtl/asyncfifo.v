// ============================================================================
// FIXED MODULE B: Asynchronous FIFO (Gray-Code Pointers)
// ============================================================================
module async_fifo #(parameter DATA_W = 16, parameter ADDR_W = 4)(
    input  wire              wclk, wrst, winc,
    input  wire [DATA_W-1:0] wdata,
    output wire              wfull,
    
    input  wire              rclk, rrst, rinc,
    output wire [DATA_W-1:0] rdata,
    output wire              rempty
);
    localparam DEPTH = 1 << ADDR_W;
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0] wbin, wgray, rbin, rgray;
    
    reg wfull_reg;
    reg rempty_reg;

    wire [ADDR_W:0] wptr_sync, rptr_sync;

    pointer_sync #(.ADDR_W(ADDR_W)) sync_w2r (.clk(rclk), .rst(rrst), .ptr_in(wgray), .ptr_out(wptr_sync));
    pointer_sync #(.ADDR_W(ADDR_W)) sync_r2w (.clk(wclk), .rst(wrst), .ptr_in(rgray), .ptr_out(rptr_sync));

    // ---------------------------------------------------------
    // WRITE DOMAIN (Fixed Combinational Loop)
    // ---------------------------------------------------------
    wire [ADDR_W:0] wbin_next  = wbin + winc; // Loop broken here
    wire [ADDR_W:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    wire wfull_val = (wgray_next == {~rptr_sync[ADDR_W:ADDR_W-1], rptr_sync[ADDR_W-2:0]});

    always @(posedge wclk) begin
        if (wrst) begin 
            wbin <= 0; 
            wgray <= 0; 
            wfull_reg <= 0; 
        end else begin
            wbin <= wbin_next; 
            wgray <= wgray_next;
            wfull_reg <= wfull_val;
            // Only write to memory if the registered full flag is 0
            if (winc && !wfull_reg) mem[wbin[ADDR_W-1:0]] <= wdata;
        end
    end
    assign wfull = wfull_reg;
    
    // ---------------------------------------------------------
    // READ DOMAIN (Fixed Combinational Loop)
    // ---------------------------------------------------------
    wire [ADDR_W:0] rbin_next  = rbin + rinc; // Loop broken here
    wire [ADDR_W:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
    wire rempty_val = (rgray_next == wptr_sync);

    always @(posedge rclk) begin
        if (rrst) begin 
            rbin <= 0; 
            rgray <= 0; 
            rempty_reg <= 1'b1; // FIFO starts completely empty
        end else begin 
            rbin <= rbin_next; 
            rgray <= rgray_next; 
            rempty_reg <= rempty_val;
        end
    end
    assign rdata = mem[rbin[ADDR_W-1:0]];
    assign rempty = rempty_reg;
    
endmodule
