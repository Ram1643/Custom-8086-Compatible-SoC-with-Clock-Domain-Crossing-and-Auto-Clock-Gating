// ============================================================================
// MODULE 1: Arithmetic Logic Unit (ALU)
// ============================================================================
module alu #(parameter DATA_W = 16)(
    input  wire [DATA_W-1:0] op_a, input  wire [DATA_W-1:0] op_b,
    input  wire [2:0]        alu_ctrl, output reg  [DATA_W-1:0] result
);
    localparam ALU_ADD = 3'b000, ALU_SUB = 3'b001, ALU_AND = 3'b010, ALU_OR = 3'b011, ALU_PASS = 3'b100;
    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:  result = op_a + op_b;
            ALU_SUB:  result = op_a - op_b;
            ALU_AND:  result = op_a & op_b;
            ALU_OR:   result = op_a | op_b;
            ALU_PASS: result = op_b;
            default:  result = {DATA_W{1'b0}};
        endcase
    end
endmodule

