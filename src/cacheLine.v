module bist(
  input clk,
  input rst_b,
  input clr,
  input d,
  output reg q);
  
  always @ (posedge clk, negedge rst_b)
        if (!rst_b)                 q <= 0;
        else if (clr)               q <= 0;
        else                        q <= d;
endmodule

module rgst_no_shift #(
    parameter w=16
)(
    input clk,
    input rst_b, 
    input clr,
    input [w-1:0] d,
    output wire [w-1:0] q
);
    genvar i;
    generate
      for (i = 0; i < w; i = i + 1) begin
        bist bist(
          .clk(clk),
          .rst_b(rst_b),
          .clr(clr),
          .d(d[i]),
          .q(q[i])
        );
      end 
    endgenerate
endmodule


module cacheLine(
  input wire clk,
  input wire rst_b,
  input wire v,
  input wire d,
  input wire [511:0]blk,
  input wire [18:0]tag,
  output wire [18:0]tago,
  output wire [511:0]blko,
  output wire vo,
  output wire do
  );
  
  rgst_no_shift #(.w(512)) blk_reg(.d(blk), .q(blko), .clk(clk), .rst_b(rst_b),.clr(1'd0));
  rgst_no_shift #(.w(19)) tag_reg(.d(tag), .q(tago), .clk(clk), .rst_b(rst_b),.clr(1'd0));
  bist bistV(
          .clk(clk),
          .rst_b(rst_b),
          .clr(1'd0),
          .d(v),
          .q(vo)
        );
  bist bistD(
          .clk(clk),
          .rst_b(rst_b),
          .clr(1'd0),
          .d(d),
          .q(do)
        );
  
  
  /*
  wire [511:0]wb0; //wire block 0
  rgst_no_shift #(.w(512)) blk_reg0(.d(blk), .q(wb0), .clk(clk), .rst_b(rst_b));
  wire [18:0]wt0; //wire tag 0
  rgst_no_shift #(.w(19)) tag_reg0(.d(tag), .q(wt0), .clk(clk), .rst_b(rst_b));
  wire wte0; //wire tag equal with tag 0
  equal #(.w(19)) mte0(.a(tag),.b(wt0),.x(wte0));
  
  wire [511:0]wb1;
  rgst_no_shift #(.w(512)) blk_reg1(.d(blk), .q(wb1), .clk(clk), .rst_b(rst_b));
  wire [18:0]wt1; 
  rgst_no_shift #(.w(19)) tag_reg1(.d(tag), .q(wt1), .clk(clk), .rst_b(rst_b));
  wire wte1;
  equal #(.w(19)) mte1(.a(tag),.b(wt1),.x(wte1));
  
  wire [511:0]wb2;
  rgst_no_shift #(.w(512)) blk_reg2(.d(blk), .q(wb2), .clk(clk), .rst_b(rst_b));
  wire [18:0]wt2;
  rgst_no_shift #(.w(19)) tag_reg2(.d(tag), .q(wt2), .clk(clk), .rst_b(rst_b));
  wire wte2;
  equal #(.w(19)) mte3(.a(tag),.b(wt2),.x(wte2));
  
  wire [511:0]wb3;
  rgst_no_shift #(.w(512)) blk_reg3(.d(blk), .q(wb3), .clk(clk), .rst_b(rst_b));
  wire [18:0]wt3; 
  rgst_no_shift #(.w(19)) tag_reg3(.d(tag), .q(wt33), .clk(clk), .rst_b(rst_b));
  wire wte3;
  equal #(.w(19)) mte3(.a(tag),.b(wt3),.x(wte3));
  
  mux_4 #(.w(511)) mblk (.d0(wb0), .d1(wb1), .d2(wb2), .d3(wb3), .s({wte3 | wte4, wte4 | wte1}), .q(blko));
  assign v = wte3 | wte2 | wte1 |wte0;
  
  wire [1:0]c_oldest;
  wire [1:0]oldest;
  wire [1:0]updated;
  wire [1:0]c_updated;
  rgst_no_shift #(.w(2)) old_reg(.d(oldest), .q(c_oldest), .clk(clk), .rst_b(rst_b));
  
  mux_2
  rgst_no_shift #(.w(2)) update_reg(.d(updated), .q(updated), .clk(clk), .rst_b(rst_b));
  LRU LRU(
    .clk(clk),
    .rst_b(rst_b),
    .updated(updated),
    .oldest(oldest)
    );*/

endmodule
  