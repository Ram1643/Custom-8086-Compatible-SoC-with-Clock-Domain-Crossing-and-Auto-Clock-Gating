// ============================================================================
// TOP-LEVEL TESTBENCH
// ============================================================================
//`timescale 1ns / 1ps

module tb_custom_8086_core;
    localparam V_ADDR = 16;
    localparam P_ADDR = 20;
    localparam DATA_W = 16;

    reg clk;
    reg rst;
    reg        tlb_wr;
    reg [11:0] tlb_v_tag;
    reg [15:0] tlb_p_tag;
    
    integer i;

   /* soc_top #(.V_ADDR(V_ADDR), .P_ADDR(P_ADDR), .DATA_W(DATA_W), .MAIN_MEM_BYTES(4096)) uut_soc (
        .clk_i(clk), .rst_i(rst), .tlb_wr_en(tlb_wr), .tlb_wr_v_tag(tlb_v_tag), .tlb_wr_p_tag(tlb_p_tag)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; 
    end*/
reg clk_cpu_200;
    reg clk_dma_150;
    reg clk_mem_100;
    
    soc_top #(.V_ADDR(V_ADDR), .P_ADDR(P_ADDR), .DATA_W(DATA_W), .MAIN_MEM_BYTES(4096)) uut_soc (
        .clk_cpu_200(clk_cpu_200),
        .clk_dma_150(clk_dma_150),
        .clk_mem_100(clk_mem_100),
        .rst_i(rst), .tlb_wr_en(tlb_wr), .tlb_wr_v_tag(tlb_v_tag), .tlb_wr_p_tag(tlb_p_tag)
    );

    initial begin
        clk_cpu_200 = 1'b0;
        clk_dma_150 = 1'b0;
        clk_mem_100 = 1'b0;
    end

    // Mimic the PLL Clock Generation using nanosecond delay increments
    always #2.500 clk_cpu_200 = ~clk_cpu_200; // 5ns period = 200 MHz
    always #3.333 clk_dma_150 = ~clk_dma_150; // 6.666ns period = 150 MHz
    always #5.000 clk_mem_100 = ~clk_mem_100; // 10ns period = 100 MHz

 // ========================================================================
    // SYSTEMVERILOG VERIFICATION EVENTS & SELF-CHECKING LOGIC
 // ========================================================================
    event slave1_done;
    event slave2_done;
    event slave3_done;

    // Single duplicate memory for verification (Size 64 to match the burst size)
    reg [15:0] tb_duplicate_mem [0:63];

    // 1. DATA INITIALIZATION: Pre-load the IP Controllers so they have real data to send
    initial begin
        for (int i = 0; i < 64; i++) begin
            uut_soc.slave_ctrl_1.local_ram[i] = 16'h1100 + i; // IP1 Payload
            uut_soc.slave_ctrl_2.local_ram[i] = 16'h2200 + i; // IP2 Payload
            uut_soc.slave_ctrl_3.local_ram[i] = 16'h3300 + i; // IP3 Payload
        end
    end

    // 2. BUS MONITOR: Trigger events when IPs assert their 'done' wires
    always @(posedge clk_cpu_200) begin
        if (uut_soc.slave_ctrl_1.status_reg==4'b1) -> slave1_done;
        if (uut_soc.slave_ctrl_2.status_reg==4'b1) -> slave2_done;
        if (uut_soc.slave_ctrl_3.status_reg==4'b1) -> slave3_done;
    end
    int err1;  int err2;  int err3; 
    // 3. EVENT HANDLERS: Wake up, Copy, and Self-Check
    initial begin
        @ (slave1_done);
        $display("\n[EVENT CAUGHT] IP Controller 1 finished its burst!");
        
        // Copy from Main Memory (IP1 writes to BASE 0x200 = decimal 512)
        for (int i = 0; i < 64; i++) begin
            tb_duplicate_mem[i] = uut_soc.main_memory.ram[512 + i];
            $display("  --> [PASS] mm  data successfully mirrored to duplicate! \n tb_location=%h ,mm_location=%h,a_data=%h , e_data=%h ,time =%d",i,512+i,tb_duplicate_mem[i], uut_soc.main_memory.ram[512+i],$time);

        end
        
        // Self-Check against the source local_ram
       err1 = 0;
        for (int i = 0; i < 64; i++) begin
            if (tb_duplicate_mem[i] !== uut_soc.slave_ctrl_1.local_ram[i])
            //  begin
                err1++;
               $display("  --> [PASS] IP 1 data successfully mirrored to Main Memory! \n location=%h ,a_data=%h , e_data=%h",i,tb_duplicate_mem[i],uut_soc.slave_ctrl_1.local_ram[i]);
              //end
        end
        
        if (err1 == 0) $display("  --> [PASS] IP 1 data successfully mirrored to Main Memory!");
        else $display("  --> [FAIL] IP 1 memory corruption! %0d mismatches.", err1);
    end

    initial begin
        @ (slave2_done);
        $display("\n[EVENT CAUGHT] IP Controller 2 finished its burst!");
        
        // Copy from Main Memory (IP2 writes to BASE 0x280 = decimal 640)
        for (int i = 0; i < 64; i++) begin
            tb_duplicate_mem[i] = uut_soc.main_memory.ram[640 + i];  
            $display("  --> [PASS] mm  data successfully mirrored to duplicate! \n tb_location=%h ,mm_location=%h,a_data=%h , e_data=%h",i,640+i,tb_duplicate_mem[i], uut_soc.main_memory.ram[640+i]);

            
      end
        
        // Self-Check against the source local_ram
        err2 = 0;
        for (int i = 0; i < 64; i++) begin
            if (tb_duplicate_mem[i] !== uut_soc.slave_ctrl_2.local_ram[i])
            //begin
             err2++;
            $display("  --> [PASS] IP 2 data successfully mirrored to Main Memory! \n location=%h ,a_data=%h , e_data=%h",i,tb_duplicate_mem[i],uut_soc.slave_ctrl_2.local_ram[i]);
           // end
        end
        
        if (err2 == 0) $display("  --> [PASS] IP 2 data successfully mirrored to Main Memory!");
        else $display("  --> [FAIL] IP 2 memory corruption! %0d mismatches.", err2);
    end

    initial begin
        @ (slave3_done);
        $display("\n[EVENT CAUGHT] IP Controller 3 finished its burst!");
        
        // Copy from Main Memory (IP3 writes to BASE 0x300 = decimal 768)
        for (int i = 0; i < 64; i++) begin
            tb_duplicate_mem[i] = uut_soc.main_memory.ram[768 + i];
            $display("  --> [PASS] mm  data successfully mirrored to duplicate! \n tb_location=%h ,mm_location=%h,a_data=%h , e_data=%h",i,640+i,tb_duplicate_mem[i], uut_soc.main_memory.ram[768+i]);

        end
        
        // Self-Check against the source local_ram
       err3 = 0;
        for (int i = 0; i < 64; i++) begin
            if (tb_duplicate_mem[i] !== uut_soc.slave_ctrl_3.local_ram[i]) err3++;
             $display("  --> [PASS] IP 3 data successfully mirrored to Main Memory! \n location=%h ,a_data=%h , e_data=%h",i,tb_duplicate_mem[i],uut_soc.slave_ctrl_3.local_ram[i]);

        end
        
        if (err3 == 0) $display("  --> [PASS] IP 3 data successfully mirrored to Main Memory!");
        else $display("  --> [FAIL] IP 3 memory corruption! %0d mismatches.", err3);
    end
    // ======================================================================== 
    initial begin
        
        $fsdbDumpfile("soc_int.fsdb");
        $fsdbDumpvars();
        $fsdbDumpMDA(tb_custom_8086_core.uut_soc.main_memory.ram);
        $fsdbDumpMDA(tb_custom_8086_core.uut_soc.slave_ctrl_1.local_ram);
        $fsdbDumpMDA(tb_custom_8086_core.uut_soc.cpu_core.biu_inst.p_queue.q_mem);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.internal_rom.rom_array);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.icache.tag_ram);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.icache.valid);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.icache.data_ram);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dcache.tag_ram);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dcache.valid);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dcache.data_ram);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dtlb.v_array);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dtlb.valid);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.dtlb.p_array);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.itlb.v_array); 
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.itlb.p_array);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.cpu_core.biu_inst.itlb.valid);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.slave_ctrl_2.local_ram[0:63]);
        $fsdbDumpMDA( tb_custom_8086_core.uut_soc.slave_ctrl_3.local_ram[0:63]);
        $readmemh("firmware1.hex", uut_soc.cpu_core.biu_inst.internal_rom.rom_array);
        
       /* uut_soc.slave_ctrl_1.local_ram[0] = 16'hDEAD;
        uut_soc.slave_ctrl_1.local_ram[1] = 16'hBEEF;
        for (i = 2; i < 64; i = i + 1) begin
            uut_soc.slave_ctrl_1.local_ram[i] = 16'hA000 + i; 
            uut_soc.slave_ctrl_2.local_ram[i] = 16'hB000 + i;
            uut_soc.slave_ctrl_3.local_ram[i] = 16'hC000 + i;
        end
        */
        rst = 1'b1; tlb_wr = 1'b0;
        #20;
        rst = 1'b0;

        // TLB MUST BE MAPPED TO 0x7000 FOR PIC TO RECEIVE INSTRUCTIONS
        @(posedge clk_cpu_200); tlb_wr = 1'b1;
        tlb_v_tag = 12'h040; tlb_p_tag = 16'h0040; @(posedge clk_cpu_200 ); 
       tlb_v_tag = 12'h050; tlb_p_tag = 16'h0050; @(posedge clk_cpu_200);
       // tlb_v_tag = 12'h028; tlb_p_tag = 16'h0280; @(posedge clk_cpu_200); 

        tlb_v_tag = 12'h700; tlb_p_tag = 16'h7000; @(posedge clk_cpu_200); 
    /*    tlb_v_tag = 12'h000; tlb_p_tag = 16'h0000; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h001; tlb_p_tag = 16'h0001; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h002; tlb_p_tag = 16'h0002; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h003; tlb_p_tag = 16'h0003; @(posedge clk_cpu_200); 
        
        tlb_v_tag = 12'h010; tlb_p_tag = 16'h0010; @(posedge clk_cpu_200); 
        
        tlb_v_tag = 12'h800; tlb_p_tag = 16'h1000; @(posedge clk); // Slave 1
        tlb_v_tag = 12'h900; tlb_p_tag = 16'h2000; @(posedge clk); // Slave 2
        tlb_v_tag = 12'hA00; tlb_p_tag = 16'h3000; @(posedge clk); // Slave 3*/
       // tlb_v_tag = 12'h700; tlb_p_tag = 16'h7000; @(posedge clk); 
        
        // Map IP RAM (Offset 0x00)
        tlb_v_tag = 12'h800; tlb_p_tag = 16'h1000; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h900; tlb_p_tag = 16'h2000; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'hA00; tlb_p_tag = 16'h3000; @(posedge clk_cpu_200); 
        
        // Map IP Status Registers (Offset 0x40 Words -> 0x80 Bytes)
        // 0x8080 belongs to page 0x808!
        tlb_v_tag = 12'h808; tlb_p_tag = 16'h1008; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h908; tlb_p_tag = 16'h2008; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'hA08; tlb_p_tag = 16'h3008; @(posedge clk_cpu_200); 
        tlb_v_tag = 12'h500; tlb_p_tag = 16'h5000; @(posedge clk_cpu_200); // Map S
        tlb_wr = 1'b0; 

        #10000; 
        $finish;
    end

  endmodule
