// ============================================================================
// MODULE 8: DUAL-PORT IP CONTROLLER (With Auto-Clock Gating)
// ============================================================================
module ip_controller #(parameter BASE_ADDR = 20'h00200, parameter MAX_WORDS = 16'd64)(
    input  wire clk, rst, cpu_trigger_i, sys_clk_en_i, output wire cpu_done_o, 
    output reg m_cyc_o, output reg m_stb_o, output reg m_we_o, output reg [19:0] m_adr_o, output reg [15:0] m_dat_o, input wire m_ack_i,
    input  wire        s_cyc_i, s_stb_i, s_we_i, input  wire [19:0] s_adr_i, input  wire [15:0] s_dat_i, output reg  [15:0] s_dat_o, output reg s_ack_o
);
    reg [1:0] state; 
    
    // --- SMART CLOCK GATING LOGIC ---
    wire gated_clk;
    
    // Wake up if: SYSCON allows it AND (Resetting OR CPU Triggering OR Slave Access OR Currently Busy)
    wire auto_wake_en = sys_clk_en_i & (rst | cpu_trigger_i | s_cyc_i | (state != 2'b00));
    
    icg_cell cg_inst (
        .clk_i(clk),
        .en_i(auto_wake_en),
        .clk_o(gated_clk)
    );
    // --------------------------------

    reg [15:0] local_ram [0:63]; 
    reg [3:0] status_reg; // [3]=Reset, [2]=Timeout, [1]=Full, [0]=Success
    assign cpu_done_o = |status_reg; 
    
    wire [6:0] s_offset = s_adr_i[6:0]; 
    
    // Notice: Powered by gated_clk!
    always @(posedge gated_clk) begin
        s_ack_o <= 1'b0;
        if (s_cyc_i && s_stb_i && !s_ack_o) begin
            if (s_we_i) begin
                if (s_offset < 64) local_ram[s_offset[5:0]] <= s_dat_i;
            end else begin
                if (s_offset < 64) s_dat_o <= local_ram[s_offset[5:0]];
                else if (s_offset == 7'h40) s_dat_o <= {12'h0, status_reg};
                else s_dat_o <= 16'h0;
            end
            s_ack_o <= 1'b1;
        end
    end

    reg [15:0] words_written; reg [19:0] target_addr; reg [7:0] timeout_cnt; 
    wire is_full = (words_written >= MAX_WORDS);

    // Notice: Powered by gated_clk!
    always @(posedge gated_clk) begin
        if (rst) begin
            state <= 2'b00; m_cyc_o <= 1'b0; m_stb_o <= 1'b0; m_we_o <= 1'b0;
            words_written <= 0; target_addr <= BASE_ADDR; timeout_cnt <= 0; 
            status_reg <= 4'b1000; 
        end else begin
            if (s_cyc_i && s_stb_i && s_we_i && (s_offset == 7'h40) && !s_ack_o) begin
                status_reg <= status_reg & ~s_dat_i[3:0]; // W1C
            end
            case (state)
                2'b00: begin
                    m_cyc_o <= 1'b0; m_stb_o <= 1'b0;
                    if (cpu_trigger_i && (status_reg == 4'b0000)) begin
                        if (is_full) begin status_reg[1] <= 1'b1; state <= 2'b10; end 
                        else begin timeout_cnt <= 0; state <= 2'b01; end
                    end
                end
                2'b01: begin
                    m_cyc_o <= 1'b1; m_stb_o <= 1'b1; m_we_o <= 1'b1; m_adr_o <= target_addr; m_dat_o <= local_ram[words_written[5:0]];
                    if (m_ack_i) begin
                        m_stb_o <= 1'b0; words_written <= words_written + 1'b1; target_addr <= target_addr + 1'b1; timeout_cnt <= 0; 
                        if ((words_written + 1'b1) >= MAX_WORDS) begin m_cyc_o <= 1'b0; status_reg[0] <= 1'b1; state <= 2'b10; end
                    end else begin
                        timeout_cnt <= timeout_cnt + 1'b1;
                        if (timeout_cnt >= 8'd250) begin m_cyc_o <= 1'b0; m_stb_o <= 1'b0; status_reg[2] <= 1'b1; state <= 2'b10; end
                    end
                end
                2'b10: begin if (!cpu_trigger_i) state <= 2'b00; end
            endcase
        end
    end
endmodule
