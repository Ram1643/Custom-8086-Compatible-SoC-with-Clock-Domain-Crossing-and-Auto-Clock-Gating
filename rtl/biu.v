// ============================================================================
// MODULE 6: Bus Interface Unit (BIU) - Unified Fetch Manager
// ============================================================================
module bus_interface_unit #(parameter V_ADDR = 16, parameter P_ADDR = 20, parameter D_W = 16)(
    input  wire              clk, rst, 
    output wire              q_empty, output wire [7:0] q_dout, input  wire q_pop,
    input  wire [V_ADDR-1:0] eu_d_addr, input  wire [D_W-1:0] eu_d_wdata,
    input  wire              eu_d_req, input  wire eu_d_we,
    output wire [D_W-1:0]    eu_d_rdata, output reg eu_d_rdy,
    input  wire              cache_en_i, input wire tlb_en_i,
    input  wire              tlb_wr_en, input  wire [11:0] tlb_wr_v_tag, input  wire [15:0] tlb_wr_p_tag,
    output reg  [P_ADDR-1:0] wb_adr_o, output reg  [D_W-1:0] wb_dat_o, input  wire [D_W-1:0] wb_dat_i,
    output reg               wb_we_o, output reg wb_stb_o, output reg wb_cyc_o, input  wire wb_ack_i,
    input  wire              branch_en, input  wire [15:0] branch_addr
);
    reg [V_ADDR-1:0] ip; wire q_full;
    wire [15:0] i_p_frame, d_p_frame;
    wire i_tlb_hit, i_tlb_miss, d_tlb_hit, d_tlb_miss;

    wire [15:0] itcm_word;
    itcm internal_rom (.ip_addr(ip), .instruction(itcm_word));
    wire [7:0] itcm_byte = ip[0] ? itcm_word[15:8] : itcm_word[7:0];
    
    wire fetch_from_itcm = (ip < 16'h0800);
    wire fetch_from_mem  = !fetch_from_itcm;
    
    tlb_array #(.V_TAG_W(12), .P_TAG_W(16), .ENTRIES(8)) itlb (
        .clk(clk), .rst(rst), .req(!q_full & tlb_en_i & fetch_from_mem), .v_tag(ip[15:4]), 
        .p_tag(i_p_frame), .hit(i_tlb_hit), .miss(i_tlb_miss),
        .wr_en(tlb_wr_en), .wr_v_tag(tlb_wr_v_tag), .wr_p_tag(tlb_wr_p_tag)
    );

    tlb_array #(.V_TAG_W(12), .P_TAG_W(16), .ENTRIES(8)) dtlb (
        .clk(clk), .rst(rst), .req(eu_d_req & tlb_en_i), .v_tag(eu_d_addr[15:4]), 
        .p_tag(d_p_frame), .hit(d_tlb_hit), .miss(d_tlb_miss),
        .wr_en(tlb_wr_en), .wr_v_tag(tlb_wr_v_tag), .wr_p_tag(tlb_wr_p_tag)
    );

    wire [P_ADDR-1:0] i_p_addr = tlb_en_i ? {i_p_frame, ip[3:0]} : {4'h0, ip}; 
    wire [P_ADDR-1:0] d_p_addr = tlb_en_i ? {d_p_frame, eu_d_addr[3:0]} : {4'h0, eu_d_addr};

    wire i_is_cacheable = (i_p_addr[19:16] == 4'h0) && cache_en_i && fetch_from_mem;
    wire d_is_cacheable = (d_p_addr[19:16] == 4'h0) && cache_en_i;

    localparam S_IDLE = 3'd0, S_BURST = 3'd1, S_COMMIT = 3'd2, S_WRITE = 3'd3, S_UNCACHEABLE_RD = 3'd4, S_UNCACHEABLE_FETCH = 3'd5; 
    reg [2:0] state; reg [2:0] beat_cnt; reg [127:0] line_buf;
    reg [19:0] base_addr; reg filling_dcache;

    wire i_cache_hit, i_cache_miss, d_cache_hit, d_cache_miss;
    wire [D_W-1:0] i_cache_rdata, d_cache_rdata;

    wire i_cache_line_wr = (state == S_COMMIT && !filling_dcache);
    wire d_cache_line_wr = (state == S_COMMIT && filling_dcache);
    wire d_cache_word_wr = (state == S_WRITE && wb_ack_i && d_is_cacheable); 

    l1_cache #(.ADDR_W(20), .WORD_W(16), .LINE_W(128), .IDX_W(2)) icache (
        .clk(clk), .flush(rst), .req(!q_full && (i_tlb_hit || !tlb_en_i || fetch_from_itcm) && state == S_IDLE && i_is_cacheable),
        .addr(i_p_addr), .line_wr_en(i_cache_line_wr), .wdata_line(line_buf), .word_wr_en(1'b0), .wdata_word(16'h0),
        .rdata_word(i_cache_rdata), .hit(i_cache_hit), .miss(i_cache_miss)
    );

    l1_cache #(.ADDR_W(20), .WORD_W(16), .LINE_W(128), .IDX_W(2)) dcache (
        .clk(clk), .flush(rst), .req(eu_d_req && (d_tlb_hit || !tlb_en_i) && state == S_IDLE && d_is_cacheable),
        .addr(d_p_addr), .line_wr_en(d_cache_line_wr), .wdata_line(line_buf), .word_wr_en(d_cache_word_wr), .wdata_word(eu_d_wdata),
        .rdata_word(d_cache_rdata), .hit(d_cache_hit), .miss(d_cache_miss)
    );

    assign eu_d_rdata = d_is_cacheable ? d_cache_rdata : wb_dat_i;
    wire [D_W-1:0] i_data = i_is_cacheable ? i_cache_rdata : wb_dat_i;

    always @(*) begin
        eu_d_rdy = 1'b0;
        if (eu_d_req) begin
            if (eu_d_we) eu_d_rdy = (state == S_WRITE && wb_ack_i);
            else eu_d_rdy = d_is_cacheable ? (d_cache_hit && state == S_IDLE) : (state == S_UNCACHEABLE_RD && wb_ack_i);
        end
    end

    wire itcm_fetch_ready = fetch_from_itcm && !q_full;
    wire mem_fetch_ready  = fetch_from_mem && (i_is_cacheable ? (i_cache_hit && !q_full && state == S_IDLE) : (state == S_UNCACHEABLE_FETCH && wb_ack_i && !q_full));
    wire i_fetch_ready = itcm_fetch_ready || mem_fetch_ready;
    wire [7:0] byte_to_push = fetch_from_itcm ? itcm_byte : (ip[0] ? i_data[15:8] : i_data[7:0]);

    prefetch_queue #(.DEPTH(6), .DATA_W(8)) p_queue (
        .clk(clk), .rst(rst | branch_en), .push(i_fetch_ready), .din(byte_to_push),
        .full(q_full), .pop(q_pop), .dout(q_dout), .empty(q_empty)
    );

    always @(posedge clk) begin
        if (rst) ip <= 16'h0000;              
        else if (branch_en) ip <= branch_addr; 
        else if (i_fetch_ready) ip <= ip + 1'b1; 
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE; wb_cyc_o <= 0; wb_stb_o <= 0; wb_we_o <= 0; wb_adr_o <= 0; wb_dat_o <= 0;    
        end else begin
            case (state)
                S_IDLE: begin
                    if (eu_d_req && (d_tlb_hit || !tlb_en_i) && eu_d_we) begin
                        wb_cyc_o <= 1; wb_stb_o <= 1; wb_we_o <= 1;
                        wb_adr_o <= {d_p_addr[19:16], 1'b0, d_p_addr[15:1]}; wb_dat_o <= eu_d_wdata;
                        if (d_is_cacheable && d_cache_miss) begin
                            filling_dcache <= 1;
                            case (d_p_addr[3:1])
                                3'b000: line_buf <= {112'h0, eu_d_wdata}; 3'b001: line_buf <= {96'h0, eu_d_wdata, 16'h0};
                                3'b010: line_buf <= {80'h0, eu_d_wdata, 32'h0}; 3'b011: line_buf <= {64'h0, eu_d_wdata, 48'h0};
                                3'b100: line_buf <= {48'h0, eu_d_wdata, 64'h0}; 3'b101: line_buf <= {32'h0, eu_d_wdata, 80'h0};
                                3'b110: line_buf <= {16'h0, eu_d_wdata, 96'h0}; 3'b111: line_buf <= {eu_d_wdata, 112'h0};
                            endcase
                        end else filling_dcache <= 0;
                        state <= S_WRITE;
                    end
                    else if (eu_d_req && (d_tlb_hit || !tlb_en_i) && !eu_d_we) begin
                        if (d_is_cacheable) begin
                            if (d_cache_miss) begin
                                wb_cyc_o <= 1; wb_stb_o <= 1; wb_we_o <= 0;
                                base_addr <= {d_p_addr[19:4], 4'b0000}; 
                                wb_adr_o  <= {d_p_addr[19:16], 1'b0, d_p_addr[15:4], 3'b000}; 
                                filling_dcache <= 1; beat_cnt <= 0; state <= S_BURST;
                            end
                        end else begin
                            wb_cyc_o <= 1; wb_stb_o <= 1; wb_we_o <= 0;
                            wb_adr_o <= {d_p_addr[19:16], 1'b0, d_p_addr[15:1]}; 
                            state <= S_UNCACHEABLE_RD;
                        end
                    end
                    else if (!q_full && (i_tlb_hit || !tlb_en_i) && fetch_from_mem) begin
                        if (i_is_cacheable) begin
                            if (i_cache_miss) begin
                                wb_cyc_o <= 1; wb_stb_o <= 1; wb_we_o <= 0;
                                base_addr <= {i_p_addr[19:4], 4'b0000}; 
                                wb_adr_o  <= {i_p_addr[19:16], 1'b0, i_p_addr[15:4], 3'b000}; 
                                filling_dcache <= 0; beat_cnt <= 0; state <= S_BURST;
                            end
                        end else begin
                            wb_cyc_o <= 1; wb_stb_o <= 1; wb_we_o <= 0;
                            wb_adr_o <= {i_p_addr[19:16], 1'b0, i_p_addr[15:1]}; 
                            state <= S_UNCACHEABLE_FETCH;
                        end
                    end
                end
                S_BURST: begin
                    if (wb_ack_i) begin
                        case (beat_cnt)
                            3'b000: line_buf[15:0]    <= wb_dat_i;  3'b001: line_buf[31:16]   <= wb_dat_i;
                            3'b010: line_buf[47:32]   <= wb_dat_i;  3'b011: line_buf[63:48]   <= wb_dat_i;
                            3'b100: line_buf[79:64]   <= wb_dat_i;  3'b101: line_buf[95:80]   <= wb_dat_i;
                            3'b110: line_buf[111:96]  <= wb_dat_i;  3'b111: line_buf[127:112] <= wb_dat_i;
                        endcase
                        if (beat_cnt == 3'b111) begin wb_cyc_o <= 0; wb_stb_o <= 0; state <= S_COMMIT; end 
                        else begin beat_cnt <= beat_cnt + 1; wb_adr_o <= {base_addr[19:16], 1'b0, base_addr[15:4], 3'b000} + {17'h0, beat_cnt} + 20'h1; end
                    end
                end
                S_COMMIT: state <= S_IDLE; 
                S_WRITE: begin if (wb_ack_i) begin wb_cyc_o <= 0; wb_stb_o <= 0; wb_we_o <= 0; if (filling_dcache) state <= S_COMMIT; else state <= S_IDLE; end end
                S_UNCACHEABLE_RD, S_UNCACHEABLE_FETCH: begin if (wb_ack_i) begin wb_cyc_o <= 0; wb_stb_o <= 0; state <= S_IDLE; end end
            endcase
        end
    end
endmodule


