module corelet #(
    parameter row     = 8,
    parameter col     = 8,
    parameter bw      = 4,
    parameter psum_bw = 16
)(
    input  clk,
    input  reset,
    input  [33:0] inst,
    input  [row*bw-1:0] data_in,             // From XMEM -> L0
    input  [col*psum_bw-1:0] data_in_acc,    // From PMEM -> SFU
    output [col*psum_bw-1:0] data_out,       // From OFIFO -> PMEM
    output ofifo_valid,                      // From OFIFO -> core_tb
    output [col*psum_bw-1:0] sfp_data_out    // From SFU -> core_tb
);


    // Instruction Bits
    wire acc_en   = inst[33];
    wire ofifo_rd = inst[6];
    wire l0_rd    = inst[3];
    wire l0_wr    = inst[2];
    wire execute  = inst[1];
    wire load     = inst[0];
    wire [1:0] inst_w = {execute, load};

    //tie up wires
    wire [row*bw-1:0]      l0_out;
    wire                   l0_ready;
    wire                   l0_full;

    wire [col*psum_bw-1:0] mac_out;
    wire [col-1:0]         mac_valid;

    wire                   ofifo_ready;
    wire                   ofifo_full;

    //L0 Input/Weight FIFO
    l0 #(
        .row(row),
        .bw(bw)
    ) l0_instance (
        .clk     (clk),
        .reset   (reset),
        .wr      (l0_wr),
        .rd      (l0_rd),
        .in      (data_in),
        .out     (l0_out),
        .o_ready (l0_ready),
        .o_full  (l0_full)
    );

    // MAC Array (WS)
    mac_array #(
        .bw      (bw),
        .psum_bw (psum_bw),
        .col     (col),
        .row     (row)
    ) mac_array_instance (
        .clk    (clk),
        .reset  (reset),
        .in_w   (l0_out),
        .in_n   ({(col*psum_bw){1'b0}}),
        .inst_w (inst_w),
        .out_s  (mac_out),
        .valid  (mac_valid)
    );

    //OFIFO
    ofifo #(
        .col(col),
        .bw (psum_bw)
    ) ofifo_instance (
        .clk     (clk),
        .reset   (reset),
        .wr      (mac_valid),
        .rd      (ofifo_rd),
        .in      (mac_out),
        .out     (data_out),
        .o_ready (ofifo_ready),
        .o_full  (ofifo_full),
        .o_valid (ofifo_valid)
    );

    // SFU Row
    sfp #(
        .col     (col),
        .psum_bw (psum_bw)
    ) sfp_instance (
        .clk   (clk),
        .reset (reset),
        .acc   (acc_en),
        .in    (data_in_acc),
        .out   (sfp_data_out)
    );

endmodule