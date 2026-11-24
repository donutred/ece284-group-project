module core # (
    parameter bw      = 4,
    parameter psum_bw = 16,
    parameter col     = 8,
    parameter row     = 8
)(
    input  clk,
    input  reset,
    input  [33:0] inst,
    input  [bw*row-1:0] D_xmem,
    output ofifo_valid,
    output [col*psum_bw-1:0] sfp_out
);

    //Inst bit slicing
    wire        CEN_pmem = inst[32];
    wire        WEN_pmem = inst[31];
    wire [10:0] A_pmem   = inst[30:20];

    wire        CEN_xmem = inst[19];
    wire        WEN_xmem = inst[18];
    wire [10:0] A_xmem   = inst[17:7];

    wire [bw*row-1:0]      xmem_out;   // XMEM Q -> corelet data_in (L0)
    wire [col*psum_bw-1:0] pmem_in;    // corelet data_out (OFIFO) -> PMEM D
    wire [col*psum_bw-1:0] pmem_out;   // PMEM Q -> corelet data_in_acc (SFU)

    //XMEM
    sram_32b_w2048 xmem_instance (
        .CLK (clk),
        .CEN (CEN_xmem),
        .WEN (WEN_xmem),
        .A   (A_xmem),
        .D   (D_xmem),
        .Q   (xmem_out)
    );

    //PMEM (need 4x32 for 128bit)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pmem_bank
            sram_32b_w2048 pmem_instance (
                .CLK (clk),
                .CEN (CEN_pmem),
                .WEN (WEN_pmem),
                .A   (A_pmem),
                .D   (pmem_in[(i+1)*32-1 : i*32]),
                .Q   (pmem_out[(i+1)*32-1 : i*32])
            );
        end
    endgenerate

    //Corelet
    corelet #(
        .row     (row),
        .col     (col),
        .bw      (bw),
        .psum_bw (psum_bw)
    ) corelet_instance (
        .clk          (clk),
        .reset        (reset),
        .inst         (inst),
        .data_in      (xmem_out),
        .data_in_acc  (pmem_out),
        .data_out     (pmem_in),
        .ofifo_valid  (ofifo_valid),
        .sfp_data_out (sfp_out)
    );

endmodule