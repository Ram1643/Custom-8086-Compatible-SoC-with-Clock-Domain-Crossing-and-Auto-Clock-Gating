// ============================================================================
// ============================================================================
// MODULE 7: Execution Unit (EU) with 4-Phase Handshake Latches
// ============================================================================
module execution_unit #(parameter DATA_W = 16, parameter ADDR_W = 16)(
    input  wire              clk, rst, wb_err_i, 
    input  wire              q_empty, input  wire [7:0] q_dout, output reg q_pop,
    output reg  [ADDR_W-1:0] d_addr, output reg [DATA_W-1:0] d_wdata,
    output reg               d_req, output reg d_we,
    input  wire [DATA_W-1:0] d_rdata, input  wire d_rdy,
    output wire              cache_en_o, output wire tlb_en_o,
    
    output wire              trig1_o, trig2_o, trig3_o,
    input  wire [2:0]        ip_done_i, 
    input  wire              intr_i,
    output reg               branch_en, output reg [15:0] branch_addr
);
    reg [15:0] ax, bx, cx, dx, si, di; reg [7:0] opcode, modrm, temp_lo, temp_hi;
    reg IF_flag; reg [15:0] ip_save, eu_ip; 
    reg [1:0] CR0; assign cache_en_o = CR0[0]; assign tlb_en_o = CR0[1];

    // Zero Flag for Conditional Branching
    reg ZF; 
    reg [3:0] state, next_state;
    reg  [DATA_W-1:0] alu_in_a, alu_in_b; reg [2:0] alu_cmd; wire [DATA_W-1:0] alu_out;

    reg trig1_reg, trig2_reg, trig3_reg;
    always @(posedge clk) begin
        if (rst) begin
            trig1_reg <= 1'b0; trig2_reg <= 1'b0; trig3_reg <= 1'b0;
        end else begin
            if (state == 4'd5) begin
                if (opcode == 8'hE1) trig1_reg <= 1'b1;
                if (opcode == 8'hE2) trig2_reg <= 1'b1;
                if (opcode == 8'hE3) trig3_reg <= 1'b1;
            end
            if (ip_done_i[0]) trig1_reg <= 1'b0;
            if (ip_done_i[1]) trig2_reg <= 1'b0;
            if (ip_done_i[2]) trig3_reg <= 1'b0;
        end
    end
    assign trig1_o = trig1_reg;
    assign trig2_o = trig2_reg;
    assign trig3_o = trig3_reg;

    // ADDED: S_BRANCH_WAIT state (4'd9)
    localparam S_FETCH_OP = 4'd0, S_DECODE = 4'd1, S_FETCH_MODRM = 4'd2;
    localparam S_FETCH_LO = 4'd3, S_FETCH_HI = 4'd4, S_EXEC = 4'd5, S_MEM_WAIT = 4'd6;
    localparam S_INT_HANDLE = 4'd7, S_HALT = 4'd8, S_BRANCH_WAIT = 4'd9;
    
    alu #(.DATA_W(DATA_W)) core_alu (.op_a(alu_in_a), .op_b(alu_in_b), .alu_ctrl(alu_cmd), .result(alu_out));

    always @(*) begin
        alu_in_a = ax; alu_in_b = bx; alu_cmd = 3'b100; 
        if (opcode == 8'hB8 || opcode == 8'hB9 || opcode == 8'hBB || opcode == 8'hBE || opcode == 8'hBF) begin
            alu_in_b = {temp_hi, temp_lo}; alu_cmd = 3'b100; 
        end else if (opcode == 8'h01 && modrm == 8'hD8) begin alu_in_a = ax; alu_in_b = bx; alu_cmd = 3'b000; end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_FETCH_OP; opcode <= 0; temp_lo <= 0; temp_hi <= 0;
            eu_ip <= 0; ip_save <= 0; ax <= 0; bx <= 0; cx <= 0; CR0 <= 2'b00; IF_flag <= 0; branch_en <= 0; branch_addr <= 0;
            ZF <= 0; // Initialize Zero Flag
        end else if (wb_err_i) begin
            state <= S_FETCH_OP; 
        end else begin
            state <= next_state; branch_en <= 0; 
            if (q_pop) eu_ip <= eu_ip + 1;

            if (state == S_FETCH_OP && !q_empty) opcode <= q_dout;
            else if (state == S_FETCH_MODRM && !q_empty) modrm <= q_dout;
            else if (state == S_FETCH_LO && !q_empty) temp_lo <= q_dout;
            else if (state == S_FETCH_HI && !q_empty) temp_hi <= q_dout;
            else if (state == S_EXEC) begin
                if (opcode == 8'hB8) ax <= alu_out; 
                if (opcode == 8'hBB) bx <= alu_out; 
                if (opcode == 8'hB9) cx <= alu_out; 
                if (opcode == 8'h01 && modrm == 8'hD8) ax <= alu_out; 
                if (opcode == 8'h0F) CR0 <= ax[1:0]; 
                
                if (opcode == 8'hFB) IF_flag <= 1'b1; 
                if (opcode == 8'hFA) IF_flag <= 1'b0; 
                
                // Branching Logic
                if (opcode == 8'h3D) ZF <= (ax == {temp_hi, temp_lo}); // CMP logic
                
                if (opcode == 8'hCF) begin 
                    branch_en <= 1'b1; branch_addr <= ip_save; eu_ip <= ip_save; IF_flag <= 1'b1; 
                end
                
                // JMP (E9) or JE (74) if ZF is 1
                if (opcode == 8'hE9 || (opcode == 8'h74 && ZF)) begin 
                    branch_en <= 1'b1; 
                    branch_addr <= {temp_hi, temp_lo}; 
                    eu_ip <= {temp_hi, temp_lo}; 
                end
            end
            else if (state == S_MEM_WAIT && d_rdy) begin
                if (opcode == 8'hA1) ax <= d_rdata; 
            end
            else if (state == S_INT_HANDLE) begin
                ip_save <= eu_ip; 
                branch_en <= 1'b1; 
                branch_addr <= 16'h0400; eu_ip <= 16'h0400; 
                IF_flag <= 1'b0;       
            end
        end
    end

    always @(*) begin
        next_state = state; q_pop = 1'b0; d_req = 1'b0; d_we = 1'b0; d_addr = 0; d_wdata = 0;
        case (state)
            S_FETCH_OP: if (!q_empty) begin q_pop = 1'b1; next_state = S_DECODE; end
            S_DECODE: begin
                if (intr_i && IF_flag) next_state = S_INT_HANDLE;
                else if (opcode == 8'hB8 || opcode == 8'hBB || opcode == 8'hB9 || opcode == 8'hBE || opcode == 8'hBF || opcode == 8'hA3 || opcode == 8'hA1 || opcode == 8'h3D || opcode == 8'h74 || opcode == 8'hE9) next_state = S_FETCH_LO;                
                else if (opcode == 8'h01) next_state = S_FETCH_MODRM;
                else if (opcode == 8'hE1 || opcode == 8'hE2 || opcode == 8'hE3 || opcode == 8'h0F || opcode == 8'hFB || opcode == 8'hFA || opcode == 8'hCF) next_state = S_EXEC; 
                else if (opcode == 8'hF4) next_state = S_HALT;
                else next_state = S_FETCH_OP; 
            end
            S_FETCH_MODRM: if (!q_empty) begin q_pop = 1'b1; next_state = S_EXEC; end
            S_FETCH_LO:    if (!q_empty) begin q_pop = 1'b1; next_state = S_FETCH_HI; end
            S_FETCH_HI:    if (!q_empty) begin q_pop = 1'b1; next_state = S_EXEC; end
            S_EXEC: begin
                if (opcode == 8'hA3) begin d_req = 1'b1; d_we = 1'b1; d_addr = {temp_hi, temp_lo}; d_wdata = ax; next_state = S_MEM_WAIT; end 
                else if (opcode == 8'hA1) begin d_req = 1'b1; d_we = 1'b0; d_addr = {temp_hi, temp_lo}; next_state = S_MEM_WAIT; end 
                
                // ADDED: Go to S_BRANCH_WAIT if a jump is actively taken
                else if (opcode == 8'hCF || opcode == 8'hE9 || (opcode == 8'h74 && ZF)) next_state = S_BRANCH_WAIT; 
                
                else next_state = S_FETCH_OP;
            end
            S_MEM_WAIT: begin
                if (opcode == 8'hA3) begin d_req = 1'b1; d_we = 1'b1; d_addr = {temp_hi, temp_lo}; d_wdata = ax; end
                else if (opcode == 8'hA1) begin d_req = 1'b1; d_we = 1'b0; d_addr = {temp_hi, temp_lo}; end
                if (d_rdy) next_state = S_FETCH_OP;
            end
            
            // ADDED: Force a wait state after an interrupt triggers
            S_INT_HANDLE: next_state = S_BRANCH_WAIT; 
            
            // ADDED: Stall for 1 cycle to let the Fetch FIFO clear out old garbage
            S_BRANCH_WAIT: next_state = S_FETCH_OP;
            
            S_HALT: begin 
                if (intr_i && IF_flag) next_state = S_INT_HANDLE; 
                else next_state = S_HALT; 
            end
            default: next_state = S_FETCH_OP;
        endcase
    end
endmodule
