module sfp #(
    parameter col = 8,
    parameter psum_bw = 16
)(
    input  clk,
    input  reset,
    input  acc,
    input  [col*psum_bw-1:0] in,
    output [col*psum_bw-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < col; i = i + 1) begin : sfp_lane
            reg signed [psum_bw-1:0] psum_q;
            wire signed [psum_bw-1:0] in_lane;

            assign in_lane = in[(i+1)*psum_bw-1 : i*psum_bw];

            always @(posedge clk) begin
                if (reset)
                    psum_q <= {psum_bw{1'b0}};
                else if (acc)
                    psum_q <= psum_q + in_lane;
            end

            // ReLU on acc output (set to 0 if negative)
            assign out[(i+1)*psum_bw-1 : i*psum_bw] = (psum_q[psum_bw-1] == 1'b1) ? {psum_bw{1'b0}} : psum_q;
        end
    endgenerate

endmodule