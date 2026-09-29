// ============================================================================
// MODULE 5: ITCM (Internal Instruction Memory)
// ============================================================================
module itcm (input wire [15:0] ip_addr, output wire [15:0] instruction);
    reg [15:0] rom_array [0:1024]; 
    assign instruction = rom_array[ip_addr >> 1];
endmodule
