// ============================================================================
// MODULE 3: L1 Cache
// ============================================================================
module l1_cache #(parameter ADDR_W = 20, parameter WORD_W = 16, parameter LINE_W = 128, parameter IDX_W = 2)(
    input  wire              clk, flush, req,
    input  wire [ADDR_W-1:0] addr,
    input  wire              line_wr_en, input  wire [LINE_W-1:0] wdata_line,
    input  wire              word_wr_en, input  wire [WORD_W-1:0] wdata_word,
    output reg  [WORD_W-1:0] rdata_word, output reg hit, miss
);
    localparam DEPTH = 1 << IDX_W; 
    localparam TAG_W = ADDR_W - (IDX_W + 4); 
    wire [2:0]       word_off = addr[3:1];          
    wire [IDX_W-1:0] idx      = addr[IDX_W+3 : 4];  
    wire [TAG_W-1:0] tag      = addr[ADDR_W-1 : IDX_W+4]; 

    reg [TAG_W-1:0]  tag_ram  [0:DEPTH-1];
    reg [LINE_W-1:0] data_ram [0:DEPTH-1];
    reg              valid    [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        if (flush) begin
            for (i = 0; i < DEPTH; i = i + 1) valid[i] <= 1'b0;
        end else begin
            if (line_wr_en) begin
                valid[idx]    <= 1'b1; tag_ram[idx]  <= tag; data_ram[idx] <= wdata_line;
            end
            else if (word_wr_en && valid[idx] && (tag_ram[idx] == tag)) begin
                case (word_off)
                    3'b000: data_ram[idx][15:0]    <= wdata_word;
                    3'b001: data_ram[idx][31:16]   <= wdata_word;
                    3'b010: data_ram[idx][47:32]   <= wdata_word;
                    3'b011: data_ram[idx][63:48]   <= wdata_word;
                    3'b100: data_ram[idx][79:64]   <= wdata_word;
                    3'b101: data_ram[idx][95:80]   <= wdata_word;
                    3'b110: data_ram[idx][111:96]  <= wdata_word;
                    3'b111: data_ram[idx][127:112] <= wdata_word;
                endcase
            end
        end
    end

    wire [LINE_W-1:0] selected_line = data_ram[idx];
    always @(*) begin
        hit = 1'b0; miss = 1'b0; rdata_word = {WORD_W{1'b0}}; 
        if (req) begin
            if (valid[idx] && (tag_ram[idx] == tag)) begin
                hit = 1'b1; 
                case (word_off)
                    3'b000: rdata_word = selected_line[15:0];
                    3'b001: rdata_word = selected_line[31:16];
                    3'b010: rdata_word = selected_line[47:32];
                    3'b011: rdata_word = selected_line[63:48];
                    3'b100: rdata_word = selected_line[79:64];
                    3'b101: rdata_word = selected_line[95:80];
                    3'b110: rdata_word = selected_line[111:96];
                    3'b111: rdata_word = selected_line[127:112];
                endcase
            end else miss = 1'b1;
        end
    end
endmodule

