module and_gate(
  input x,
  input y,
  input z);
  assign z = x & y;
endmodule

module and_tree #(
  parameter w = 16
  )(
  input [w-1:0]x,
  output out
  );
  wire [w-2:0] results;
  and_gate and_gate_init(
    .x(x[0]),
    .y(x[1]),
    .z(results[0])
    );
  genvar i;
  generate
    for(i = 1; i < w - 1; i = i +1) begin
      and_gate and_gate(
        .x(x[i]),
        .y(results[i-1]),
        .z(results[i])
        );
    end
  endgenerate
  and_gate and_gate_final(
    .x(x[w-1]),
    .y(results[w-2]),
    .z(out)
    );
endmodule


module equal_bit(
  input wire a,
  input wire b,
  output x);
  assign x = ~a&~b | a&b;
endmodule

module equal#(
  parameter w = 2
  )(
    input wire [w-1:0]a,
    input wire [w-1:0]b,
    output wire x
  );
    wire [w-1:0]and_tree_wire;
    
    genvar i;
    generate
      for (i = 0; i < w; i = i + 1) begin
        equal_bit equal_bit(.a(a[i]),.b(b[i]),.x(and_tree_wire[i]));
      end 
    endgenerate
    and_tree #(.w(w)) and_tree(.x(and_tree_wire), .out(x));
endmodule


module mux_2 #(
  parameter w=2
)(
  input [w-1:0]d0,
  input [w-1:0]d1,
  input s,
  output [w-1:0]q
  );
  assign q = ( ~s ) ? d0: {w{1'bz}};
  assign q = ( s ) ? d1: {w{1'bz}};
endmodule


module mux_4 #(
  parameter w=2
)(
  input [w-1:0]d0,
  input [w-1:0]d1,
  input [w-1:0]d2,
  input [w-1:0]d3,
  input [1:0]s,
  output [w-1:0]q
  );
  assign q = ( ~s[1] & ~s[0]) ? d0: {w{1'bz}};
  assign q = ( ~s[1] & s[0]) ? d1: {w{1'bz}};
  assign q = ( s[1] & ~s[0]) ? d2: {w{1'bz}};
  assign q = ( s[1] & s[0]) ? d3: {w{1'bz}};
endmodule

module greaterTwoBit(
    input wire [1:0]a,
    input wire [1:0]b,
    output wire x
  );
  assign x = ~a[1]&b[1] | ~a[1]&~a[0] | ~a[0]&b[1];
endmodule



module oldestIndex(
    input [1:0]first,
    input [1:0]second,
    input [1:0]third,
    input [1:0]fourth,
    output wire [1:0]oldest
  );
  wire firstSecondGreater;
  wire [1:0]firstSecondMux;
  greaterTwoBit greaterTwoBitFirstSecond(.a(first), .b(second), .x(firstSecondGreater));
  mux_2 #(.w(2)) mux_2_firstSecond(.d0(first), .d1(second), .s(firstSecondGreater), .q(firstSecondMux));
  
  wire thirdFourthGreater;
  wire [1:0]thirdFourthMux;
  greaterTwoBit greaterTwoBitThirdFourth(.a(third), .b(fourth), .x(thirdFourthGreater));
  mux_2 #(.w(2)) mux_2_thirdFourth(.d0(third), .d1(fourth), .s(thirdFourthGreater), .q(thirdFourthMux));
  
  wire finalGreater;
  wire [1:0]finalMux;
  greaterTwoBit greaterTwoBitFinal(.a(firstSecondMux), .b(thirdFourthMux), .x(finalGreater));
  mux_2 #(.w(2)) mux_2_final(.d0(firstSecondMux), .d1(thirdFourthMux), .s(finalGreater), .q(finalMux));
  
  wire firstGreater;
  equal #(.w(2)) equalFirstGreater(.a(first),.b(finalMux),.x(firstGreater));
  
  wire secondGreater;
  equal #(.w(2)) equalSecondGreater(.a(second),.b(finalMux),.x(secondGreater));
  
  wire thirdGreater;
  equal #(.w(2)) equalThirdGreater(.a(third),.b(finalMux),.x(thirdGreater));
  
  wire fourthGreater;
  equal #(.w(2)) equalFourthGreater(.a(fourth),.b(finalMux),.x(fourthGreater));
  
  mux_4 #(.w(2)) mux_4_result(.d0(2'd0),.d1(2'd1),.d2(2'd2),.d3(2'd3),.q(oldest), .s({thirdGreater | fourthGreater, fourthGreater | secondGreater}));
  
endmodule

module customRstReg(
    input clk,
    input [1:0]rst_val,
    input rst_b,
    input [1:0]d,
    output reg [1:0]q
  );
  always @(posedge clk, negedge rst_b) begin
    if( !rst_b) q <= rst_val;
    else q <= d;
  end
endmodule


//Had to crunch hard for another project a few days ago, and now my pinky hurts a lot from pressing shift
//and after making the oldestIndex module, I decided to shorten variable names, I am not sorry, I would do it again
//though got to admit, the oldestIndex looks pretty neat with all those explicit names, too bad
module LRU(
  
  //output wire [1:0]o0,
  //output wire [1:0]o1,
  //output wire [1:0]o2,
  //output wire [1:0]o3,
  /*
  output wire ou0,
  output wire ou1,
  output wire ou2,
  output wire ou3,
  
  output wire ow0s1,
  output wire ow0s2,
  output wire ow0s3,
  
  output wire ow1s0,
  output wire ow1s2,
  output wire ow1s3,
  
  output wire ow2s0,
  output wire ow2s1,
  output wire ow2s3,
  
  output wire ow3s0,
  output wire ow3s1,
  output wire ow3s2,
  
  output wire onu0,
  output wire onu1,
  output wire onu2,
  output wire onu3,
  */
  input wire clk,
  input wire rst_b,
  input wire [1:0]updated, //index of who got updated
  output wire [1:0]oldest //index of oldest
  );
  wire [1:0]v0; //value of x
  wire [1:0]v1;
  wire [1:0]v2;
  wire [1:0]v3;
  
  
  //assign o0 = v0;
  //assign o1 = v1;
  //assign o2 = v2;
  //assign o3 = v3;
  
   
  wire u0; //update index x
  wire u1;
  wire u2;
  wire u3;
  assign u0 = ~updated[1] & ~updated[0];
  assign u1 = ~updated[1] & updated[0];
  assign u2 = updated[1] & ~updated[0];
  assign u3 = updated[1] & updated[0];  
  

  wire w0s1; //wire x smaller than y;
  wire w0s2;
  wire w0s3;
  
  wire w1s0;
  wire w1s2;
  wire w1s3;
  
  wire w2s0;
  wire w2s1;
  wire w2s3;
  
  wire w3s0;
  wire w3s2;
  wire w3s1;
  
  
  
  greaterTwoBit m0s1(.a(v0), .b(v1), .x(w0s1));  //module x smaller than y
  greaterTwoBit m0s2(.a(v0), .b(v2), .x(w0s2));
  greaterTwoBit m0s3(.a(v0), .b(v3), .x(w0s3));
  
  greaterTwoBit m1s0(.a(v1), .b(v0), .x(w1s0));
  greaterTwoBit m1s2(.a(v1), .b(v2), .x(w1s2));
  greaterTwoBit m1s3(.a(v1), .b(v3), .x(w1s3));
  
  greaterTwoBit m2s0(.a(v2), .b(v0), .x(w2s0));
  greaterTwoBit m2s1(.a(v2), .b(v1), .x(w2s1));
  greaterTwoBit m2s3(.a(v2), .b(v3), .x(w2s3));
  
  greaterTwoBit m3s0(.a(v3), .b(v0), .x(w3s0));
  greaterTwoBit m3s1(.a(v3), .b(v1), .x(w3s1));
  greaterTwoBit m3s2(.a(v3), .b(v2), .x(w3s2));
  
  wire nu0; //x needs update
  wire nu1;
  wire nu2;
  wire nu3;
  assign nu0 = w0s1&u1 | w0s2&u2 | w0s3&u3; 
  assign nu1 = w1s0&u0 | w1s2&u2 | w1s3&u3;
  assign nu2 = w2s1&u1 | w2s0&u0 | w2s3&u3;
  assign nu3 = w3s1&u1 | w3s2&u2 | w3s0&u0;
  

  
  //if updating something bigger than current, then current++. If current is getting updated, then current = 0;
  customRstReg r0(.clk(clk),.rst_b(rst_b),.d({(v0[1]&~nu0 | nu0&v0[0] | nu0&~v0[0]&v0[1]) & ~u0, (v0[0]&~nu0 | nu0&~v0[0]) & ~u0}),.q(v0),.rst_val(2'd0));
  customRstReg r1(.clk(clk),.rst_b(rst_b),.d({(v1[1]&~nu1 | nu1&v1[0] | nu1&~v1[0]&v1[1]) & ~u1, (v1[0]&~nu1 | nu1&~v1[0]) & ~u1}),.q(v1),.rst_val(2'd1));
  customRstReg r2(.clk(clk),.rst_b(rst_b),.d({(v2[1]&~nu2 | nu2&v2[0] | nu2&~v2[0]&v2[1]) & ~u2, (v2[0]&~nu2 | nu2&~v2[0]) & ~u2}),.q(v2),.rst_val(2'd2));
  customRstReg r3(.clk(clk),.rst_b(rst_b),.d({(v3[1]&~nu3 | nu3&v3[0] | nu3&~v3[0]&v3[1]) & ~u3, (v3[0]&~nu3 | nu3&~v3[0]) & ~u3}),.q(v3),.rst_val(2'd3)); 
  
  oldestIndex oldestIndex(.first(v0),.second(v1),.third(v2),.fourth(v3), .oldest(oldest));
  /*
  assign ou0 = u0;
  assign ou1 = u1;
  assign ou2 = u2;
  assign ou3 = u3;
  assign onu0 = nu0;
  assign onu1 = nu1;
  assign onu2 = nu2;
  assign onu3 = nu3;
  
  assign ow0s1 = w0s1;
  assign ow0s2 = w0s2;
  assign ow0s3 = w0s3;
  
  assign ow1s0 = w1s0;
  assign ow1s2 = w1s2;
  assign ow1s3 = w1s3;
  
  assign ow2s0 = w2s0;
  assign ow2s1 = w2s1;
  assign ow2s3 = w2s3;
  
  assign ow3s0 = w3s0;
  assign ow3s1 = w3s1;
  assign ow3s2 = w3s2;*/
endmodule

module LRU_TB;
  //wire [1:0]o0;
  //wire [1:0]o1;
  //wire [1:0]o2;
  //wire [1:0]o3;
  /*
  
  wire onu0;
  wire onu1;
  wire onu2;
  wire onu3;
  
  wire ou0;
  wire ou1;
  wire ou2;
  wire ou3;
  wire ow0s1;
  wire ow0s2;
  wire ow0s3;
  wire ow1s0;
  wire ow1s2;
  wire ow1s3;
  
  wire ow2s0;
  wire ow2s1;
  wire ow2s3;
  
   wire ow3s0;
   wire ow3s1;
   wire ow3s2;
  */
  
  reg clk;
  reg rst_b;
  reg [1:0]updated; //index of who got updated
  wire [1:0]oldest; //index of oldest
  
  LRU LRU_CUT(
    //.o0(o0),
    //.o1(o1),
   // .o2(o2),
   // .o3(o3),
    /*.ou0(ou0),
    .ou1(ou1),
    .ou2(ou2),
    .ou3(ou3),
    .onu0(onu0),
    .onu1(onu1),
    .onu2(onu2),
    .onu3(onu3),
    
    .ow0s1(ow0s1),
    .ow0s2(ow0s2),
    .ow0s3(ow0s3),
    
    .ow1s0(ow1s0),
    .ow1s2(ow1s2),
    .ow1s3(ow1s3),
    
    .ow2s0(ow2s0),
    .ow2s1(ow2s1),
    .ow2s3(ow2s3),
    
    .ow3s0(ow3s0),
    .ow3s1(ow3s1),
    .ow3s2(ow3s2),
    */
    .clk(clk),
    .rst_b(rst_b),
    .updated(updated),
    .oldest(oldest)
  );
  
  
  localparam CYCLES = 50, PERIOD = 100;
  initial begin
    clk = 0;
    repeat(CYCLES*2) begin
      #(PERIOD/2) 
      clk = ~clk;
    end
  end
  
  initial begin
    rst_b = 0;
    #25
    rst_b = 1;
  end
  
  initial begin
    repeat(CYCLES) begin
      #(PERIOD)
      //$display("upd %d %d %d %d %d | nu %d %d %d %d | smal %d %d %d - %d %d %d - %d %d %d - %d %d %d | regs %d %d %d %d| %d\n", updated, ou0,ou1,ou2,ou3, onu0,onu1,onu2,onu3, ow0s1,ow0s2,ow0s3,ow1s0,ow1s2,ow1s3,ow2s0,ow2s1,ow2s3,ow3s0,ow3s1,ow3s2, o0, o1, o2, o3, oldest);
      //$display("%d | %d %d %d %d | %d", updated, o0, o1, o2,o3, oldest);
      $display("%d | %d",updated, oldest);
    end
  end
  
  initial begin
      updated = 1;
      #(PERIOD)
      updated = 1;
      #(PERIOD)
      updated = 2;
      #(PERIOD)
      updated = 3;
      #(PERIOD)
      updated = 1;
      #(PERIOD)
      updated = 0;
      #(PERIOD)
      updated = 2;
      #(PERIOD)
      updated = 0;
      #(PERIOD)
      updated = 1;
      #(PERIOD)
      updated = 3;
      
 end
endmodule
  
