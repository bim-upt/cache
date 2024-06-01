module mux_8 #(
  parameter w=2
)(
  input [w-1:0]d0,
  input [w-1:0]d1,
  input [w-1:0]d2,
  input [w-1:0]d3,
  input [w-1:0]d4,
  input [w-1:0]d5,
  input [w-1:0]d6,
  input [w-1:0]d7,
  input [2:0]s,
  output [w-1:0]q
  );
  wire [w-1:0]m1;
  wire [w-1:0]m2;
  mux_4 #(.w(w)) mux1 (.d0(d0),.d1(d1),.d2(d2),.d3(d3),.q(m1),.s(s[1:0]));
  mux_4 #(.w(w)) mux2 (.d0(d4),.d1(d5),.d2(d6),.d3(d7),.q(m2),.s(s[1:0]));
  mux_2 #(.w(w)) mux3 (.d0(m2),.d1(m1),.q(q),.s(s[2]));
endmodule

module mux_16 #(
  parameter w=2
)(
  input [w*16-1:0]d,
  input [3:0]s,
  output [w-1:0]q
  );
  wire [w-1:0]m1;
  wire [w-1:0]m2;
  mux_8 #(.w(w)) mux1 (.d0(d[w*16-1:w*15]),.d1(d[w*15-1:w*14]),.d2(d[w*14-1:w*13]),.d3(d[w*13-1:w*12]),.d4(d[w*12-1:w*11]),.d5(d[w*11-1:w*10]),.d6(d[w*10-1:w*9]),.d7(d[w*9-1:w*8]),.q(m1),.s(s[2:0]));
  mux_8 #(.w(w)) mux2 (.d0(d[w*8-1:w*7]),.d1(d[w*7-1:w*6]),.d2(d[w*6-1:w*5]),.d3(d[w*5-1:w*4]),.d4(d[w*4-1:w*3]),.d5(d[w*3-1:w*2]),.d6(d[w*2-1:w*1]),.d7(d[w*1-1:w*0]),.q(m2),.s(s[2:0]));
  mux_2 #(.w(w)) mux3 (.d0(m2),.d1(m1),.q(q),.s(s[3]));
endmodule

module mux_32 #(
  parameter w=2
)(
  input [w*32-1:0]d,
  input [4:0]s,
  output [w-1:0]q
  );
  wire [w-1:0]m1;
  wire [w-1:0]m2;
  mux_16 #(.w(w)) mux1 (.d(d[w*32-1:w*16]),.q(m1),.s(s[3:0]));
  mux_16 #(.w(w)) mux2 (.d(d[w*16-1:0]),.q(m2),.s(s[3:0]));
  mux_2 #(.w(w)) mux3 (.d0(m2),.d1(m1),.q(q),.s(s[4]));
endmodule

module mux_64 #(
  parameter w=2
)(
  input [w*64-1:0]d,
  input [5:0]s,
  output [w-1:0]q
  );
  wire [w-1:0]m1;
  wire [w-1:0]m2;
  mux_32 #(.w(w)) mux1 (.d(d[w*64-1:w*32]),.q(m1),.s(s[4:0]));
  mux_32 #(.w(w)) mux2 (.d(d[w*32-1:0]),.q(m2),.s(s[4:0]));
  mux_2 #(.w(w)) mux3 (.d0(m2),.d1(m1),.q(q),.s(s[5]));
endmodule

module mux_128 #(
  parameter w=2
)(
  input [w*128-1:0]d,
  input [6:0]s,
  output [w-1:0]q
  );
  wire [w-1:0]m1;
  wire [w-1:0]m2;
  mux_64 #(.w(w)) mux1 (.d(d[w*128-1:w*64]),.q(m1),.s(s[5:0]));
  mux_64 #(.w(w)) mux2 (.d(d[w*64-1:0]),.q(m2),.s(s[5:0]));
  mux_2 #(.w(w)) mux3 (.d0(m2),.d1(m1),.q(q),.s(s[6]));
endmodule

module cacheController(
  input wire clk,
  input wire rst_b,
  input wire op, //0 read, 1 write
  input wire start,
  input wire got,
  input wire hit,
  output wire write,
  output wire done,
  output wire read_mm
  );
  reg [5:0]q;
  wire [5:0]nxt;
  localparam IDLE = 0;
  localparam RH = 1; //read hit
  localparam RM = 2; //read miss
  localparam WH = 3;  //write hit
  localparam WM = 4;  //write miss
  localparam EVICT = 5; 
  assign state = q;
  assign nxt_state = nxt;
  
  assign nxt[IDLE] = q[RH] | q[WH] | q[RM] & got | q[WM] & got;
 
  assign nxt[RH] = q[IDLE] & hit & ~op & start;
  assign nxt[RM] = q[IDLE] & ~hit & ~op & start | q[RM] & ~got;
 
  assign nxt[WH] = q[IDLE] & hit & op;
  assign nxt[WM] = q[EVICT] | q[WM] & ~got;
 
  assign nxt[EVICT] = q[IDLE] & ~hit & op & start;
  
  assign write = q[WH] | q[WM] & got;
  assign read_mm = q[WM] | q[RM];
  assign done = q[RH] | q[WH] | q[RM] & got | q[WM] & got; 
  
  always @ (posedge clk, negedge rst_b) begin
    if(rst_b == 0) begin
      q <= 0;
      q[IDLE] <=1;
    end else
      q <= nxt;
  end
endmodule


module cache(
  input wire clk,
  input wire rst_b,
  input wire op, //0 read, 1 write
  input wire [31:0]adr,
  input wire start,
  input wire [511:0]mblk, //blk got from mm
  input wire got, //we can read gblok
  input wire [7:0]i_word,
  output wire done, //cache done
  output wire [7:0]o_word, //word got from cache
  output wire [26:0]madr, //block adr sent to mm
  output wire get //send signal to mm to bring block
  );

  
  //tags, blocks, valids, and dirtys for each way
  wire [19*128-1:0]tags0;
  wire [19*128-1:0]tags1;
  wire [19*128-1:0]tags2;
  wire [19*128-1:0]tags3;
  
  wire [128-1:0]v0;
  wire [128-1:0]v1;
  wire [128-1:0]v2;
  wire [128-1:0]v3;
  
  wire [128*512-1:0]blk0;
  wire [128*512-1:0]blk1;
  wire [128*512-1:0]blk2;
  wire [128*512-1:0]blk3;
  
  wire [128-1:0]d0;
  wire [128-1:0]d1;
  wire [128-1:0]d2;
  wire [128-1:0]d3;
  
  
  wire [2*128-1:0]oldest; //oldest index for a set
  wire [2*128-1:0]updated; //last accessed index for a set
  wire [511:0]new_blk; //block made with i_word
  
  wire [1:0]changed;// index of which way is updated
  genvar i;
  generate
    for(i = 0; i < 128; i = i +1) begin
      wire [511:0]updated_blk0;
      wire [511:0]updated_blk1;
      wire [511:0]updated_blk2;
      wire [511:0]updated_blk3;
      
      //updated blk = blk itself, new_block (blk with changed word), or blk from mm
      mux_4 #(.w(512)) whichBlk0(.d0(blk0[(128-i)*512-1:(128-i-1)*512]), //decide the value of a blk each clk
                                .d1(new_blk), 
                                .d2(mblk), 
                                .d3(blk0[(128-i)*512-1:(128-i-1)*512]),
                                .s({(128-i-1 == adr[12:6]) & got & (changed == 2'b00), (changed == 2'b00) & (128-i-1 == adr[12:6]) & write}),
                                .q(updated_blk0));
      mux_4 #(.w(512)) whichBlk1(.d0(blk1[(128-i)*512-1:(128-i-1)*512]), 
                                .d1(new_blk), 
                                .d2(mblk), 
                                .d3(blk1[(128-i)*512-1:(128-i-1)*512]),
                                .s({(128-i-1 == adr[12:6]) & got & (changed == 2'b01), (changed == 2'b01) & (128-i-1 == adr[12:6]) & write}),
                                .q(updated_blk1));
       mux_4 #(.w(512)) whichBlk2(.d0(blk2[(128-i)*512-1:(128-i-1)*512]), 
                                .d1(new_blk), 
                                .d2(mblk), 
                                .d3(blk2[(128-i)*512-1:(128-i-1)*512]),
                                .s({(128-i-1 == adr[12:6]) & got & (changed == 2'b10), (changed == 2'b10) & (128-i-1 == adr[12:6]) & write}),
                                .q(updated_blk2));
       mux_4 #(.w(512)) whichBlk3(.d0(blk3[(128-i)*512-1:(128-i-1)*512]), 
                                .d1(new_blk), 
                                .d2(mblk), 
                                .d3(blk3[(128-i)*512-1:(128-i-1)*512]),
                                .s({(128-i-1 == adr[12:6]) & got & (changed == 2'b11), (changed == 2'b11) & (128-i-1 == adr[12:6]) & write}),
                                .q(updated_blk3));
                                
      wire [18:0]updated_tag0;
      wire [18:0]updated_tag1;
      wire [18:0]updated_tag2;
      wire [18:0]updated_tag3;
      
      ///updated tag = tag itself, tag from adress if miss
      mux_2 #(.w(19)) whichTag0(.d0(tags0[(128-i)*(19)-1:(128-i-1)*(19)]),  //decide value of a tag each clk
                               .d1(adr[31:13]),
                               .s((128-i-1 == adr[12:6]) & (changed == 2'b00) & got),
                               .q(updated_tag0));
      mux_2 #(.w(19)) whichTag1(.d0(tags1[(128-i)*(19)-1:(128-i-1)*(19)]),
                               .d1(adr[31:13]),
                               .s((128-i-1 == adr[12:6]) & (changed == 2'b01) & got),
                               .q(updated_tag1));
      mux_2 #(.w(19)) whichTag2(.d0(tags2[(128-i)*(19)-1:(128-i-1)*(19)]),
                               .d1(adr[31:13]),
                               .s((128-i-1 == adr[12:6]) & (changed == 2'b10) & got),
                               .q(updated_tag2));
      mux_2 #(.w(19)) whichTag3(.d0(tags3[(128-i)*(19)-1:(128-i-1)*(19)]),
                               .d1(adr[31:13]),
                               .s((128-i-1 == adr[12:6]) & (changed == 2'b11) & got),
                               .q(updated_tag3));
                               
      //v becomes 1 whenever it is accessed for any reason
      wire updated_v0;
      mux_2 #(.w(1)) whichV0 (.d0(v0[127-i]),.d1(1'b1),.q(updated_v0), .s((128-i-1 == adr[12:6]) & (changed == 2'b00)));
      wire updated_v1;
      mux_2 #(.w(1)) whichV1 (.d0(v1[127-i]),.d1(1'b1),.q(updated_v1), .s((128-i-1 == adr[12:6]) & (changed == 2'b01)));
      wire updated_v2;
      mux_2 #(.w(1)) whichV2 (.d0(v2[127-i]),.d1(1'b1),.q(updated_v2), .s((128-i-1 == adr[12:6]) & (changed == 2'b10)));
      wire updated_v3;
      mux_2 #(.w(1)) whichV3 (.d0(v3[127-i]),.d1(1'b1),.q(updated_v3), .s((128-i-1 == adr[12:6]) & (changed == 2'b11)));
      
   
      wire replace0;
      wire replace1;
      wire replace2;
      wire replace3;
      //updated on a write and oldest => clean, else dirty
      mux_2 #(.w(1)) replace_m0(.d0(1'b1),.d1(1'b0),.s((oldest[(128-i)*2 - 1:(128-i-1)*2]  == 2'b00) & ~hit),.q(replace0));
      mux_2 #(.w(1)) replace_m1(.d0(1'b1),.d1(1'b0),.s((oldest[(128-i)*2 - 1:(128-i-1)*2]  == 2'b01) & ~hit),.q(replace1));
      mux_2 #(.w(1)) replace_m2(.d0(1'b1),.d1(1'b0),.s((oldest[(128-i)*2 - 1:(128-i-1)*2]  == 2'b10) & ~hit),.q(replace2));
      mux_2 #(.w(1)) replace_m3(.d0(1'b1),.d1(1'b0),.s((oldest[(128-i)*2 - 1:(128-i-1)*2]  == 2'b11) & ~hit),.q(replace3));
    
      //update on write operation
      mux_2 #(.w(1)) d0_m(.d0(d0[127-i]),.d1(replace0),.s((changed == 2'b00) & op & (i == adr[12:6])), .q(updated_d0));
      mux_2 #(.w(1)) d1_m(.d0(d1[127-i]),.d1(replace1),.s((changed == 2'b01) & op & (i == adr[12:6])), .q(updated_d1));
      mux_2 #(.w(1)) d2_m(.d0(d2[127-i]),.d1(replace2),.s((changed == 2'b10) & op & (i == adr[12:6])), .q(updated_d2));
      mux_2 #(.w(1)) d3_m(.d0(d3[127-i]),.d1(replace3),.s((changed == 2'b11) & op & (i == adr[12:6])), .q(updated_d3));
      
      
    
      cacheLine set0(.clk(clk), .rst_b(rst_b), .v(updated_v0), .d(updated_d0), .tag(updated_tag0), .blk(updated_blk0), .vo(v0[127-i]), .do(d0[127-i]), .blko(blk0[(128-i)*512-1:(128-i-1)*512]), .tago(tags0[(128-i)*(19)-1:(128-i-1)*(19)]));
      cacheLine set1(.clk(clk), .rst_b(rst_b), .v(updated_v1), .d(updated_d0), .tag(updated_tag1), .blk(updated_blk1), .vo(v1[127-i]), .do(d1[127-i]), .blko(blk1[(128-i)*512-1:(128-i-1)*512]), .tago(tags1[(128-i)*(19)-1:(128-i-1)*(19)]));
      cacheLine set2(.clk(clk), .rst_b(rst_b), .v(updated_v2), .d(updated_d0), .tag(updated_tag2), .blk(updated_blk2), .vo(v2[127-i]), .do(d2[127-i]), .blko(blk2[(128-i)*512-1:(128-i-1)*512]), .tago(tags2[(128-i)*(19)-1:(128-i-1)*(19)]));
      cacheLine set3(.clk(clk), .rst_b(rst_b), .v(updated_v3), .d(updated_d0), .tag(updated_tag3), .blk(updated_blk3), .vo(v3[127-i]), .do(d3[127-i]), .blko(blk3[(128-i)*512-1:(128-i-1)*512]), .tago(tags3[(128-i)*(19)-1:(128-i-1)*(19)]));
      
      //handle updating age
      wire [1:0]last_updated;
      assign updated[(128-i)*2-1:(128-i-1)*2] = last_updated;
      mux_2 #(.w(2)) last (.d0(updated[(128-i)*2-1:(128-i-1)*2]), .d1(changed),.s((128-i-1 == adr[12:6])),.q(last_updated));
      
      LRU lru(.clk(clk), .rst_b(rst_b), .updated(last_updated), .oldest(oldest[2*(128-i)-1:2*(128-i-1)]));
    end
  endgenerate
  
  //find matching tag
  wire [18:0]ti0; //tag at index in way 0
  mux_128 #(.w(19)) select_tag0(.d(tags0),.q(ti0),.s(adr[12:6]));
  wire ti0e; //tag way 0 equals tag
  equal #(.w(19)) mti0 (.a(adr[31:13]), .b(ti0), .x(ti0e));
  
  wire [18:0]ti1;
  mux_128 #(.w(19)) select_tag1(.d(tags1),.q(ti1),.s(adr[12:6]));
  wire ti1e;
  equal #(.w(19)) mti1 (.a(adr[31:13]), .b(ti1), .x(ti1e));
  
  wire [18:0]ti2;
  mux_128 #(.w(19)) select_tag2(.d(tags2),.q(ti2),.s(adr[12:6]));
  wire ti2e;
  equal #(.w(19))mti2 (.a(adr[31:13]), .b(ti2), .x(ti2e));
  
  wire [18:0]ti3;
  mux_128 #(.w(19)) select_tag3(.d(tags3),.q(ti3),.s(adr[12:6]));
  wire ti3e;
  equal #(.w(19)) mti3 (.a(adr[31:13]), .b(ti3), .x(ti3e));
  
  //find if matching tag is valid
  wire i0v; //index 0 valid
  mux_128 #(.w(1)) select_v0(.d(v0), .s(adr[12:6]), .q(i0v));
  
  wire i1v;
  mux_128 #(.w(1)) select_v1(.d(v1), .s(adr[12:6]), .q(i1v));
  
  wire i2v;
  mux_128 #(.w(1)) select_v2(.d(v2), .s(adr[12:6]), .q(i2v));
  
  wire i3v;
  mux_128 #(.w(1)) select_v3(.d(v3), .s(adr[12:6]), .q(i3v));
  
  //select blks for each way
  wire [511:0]b0;
  wire [511:0]b1;
  wire [511:0]b2;
  wire [511:0]b3;
  
  mux_128 #(.w(512)) select_blk0(.d(blk0), .s(adr[12:6]), .q(b0));
  mux_128 #(.w(512)) select_blk1(.d(blk1), .s(adr[12:6]), .q(b1));
  mux_128 #(.w(512)) select_blk2(.d(blk2), .s(adr[12:6]), .q(b2));
  mux_128 #(.w(512)) select_blk3(.d(blk3), .s(adr[12:6]), .q(b3));
  
  //select blk based on valid
  wire [511:0]b;
  mux_4 #(.w(512)) select_blk(.d0(b0), .d1(b1), .d2(b2), .d3(b3), .s({ti2e&i2v | ti3e&i3v, ti1e&i1v | ti3e&i3v}), .q(b));
  
  //select word
  mux_64 #(.w(8)) select_wrd(.d(b), .s(adr[5:0]), .q(o_word));
  
  //check if hit
  wire hit;
  assign hit = ti0e&i0v | ti1e&i1v | ti2e&i2v | ti3e&i3v;
  
  //get which way was hit
  wire [1:0]which_way;
  mux_4 #(.w(2)) whichw (.d0(2'b00), .d1(2'b01), .d2(2'b10), .d3(2'b11), .s({ti2e&i2v | ti3e&i3v, ti1e&i1v | ti3e&i3v}), .q(which_way));
  
  //form blk in case of write
  
  generate
    for(i = 0; i < 64; i = i +1) begin
      mux_2 #(.w(8)) newCell(.d0(b[8*(64-i)-1:8*(64-i-1)]),.d1(i_word), .s(op & (adr[5:0] == (64-i-1))), .q(new_blk[8*(64-i)-1:8*(64-i-1)]));
    end
  endgenerate
  
  //select who to change, oldest on miss, which_way on hit
  wire [1:0]oldest_at_index;
  mux_128 #(.w(2)) oldie (.d(oldest), .s(adr[12:6]),.q(oldest_at_index));
  mux_2 #(.w(2)) ch (.d0(oldest_at_index),.d1(which_way),.q(changed),.s(hit));
  
  wire write;
  wire read_mm;
  assign madr = adr[31:5];
  cacheController control(
    .clk(clk),
    .rst_b(rst_b),
    .op(op), 
    .start(start),
    .got(got),
    .hit(hit),
    .write(write),
    .done(done),
    .read_mm(get)
  );
endmodule

module cache_tb;
  reg clk;
  reg rst_b;
  reg op;
  reg [31:0]adr;
  reg start;
  reg [511:0]mblk; //blk got from mm
  reg got; //we can read gblok
  reg [7:0]i_word;
  wire done; //cache done
  wire [7:0]o_word; //word got from cache
  wire [26:0]madr; //block adr sent to mm
  wire get; //send signal to mm to bring block
  
  cache cache_uut(
    .clk(clk),
    .rst_b(rst_b),
    .op(op),
    .adr(adr),
    .start(start),
    .mblk(mblk),
    .got(got),
    .i_word(i_word),
    .done(done),
    .o_word(o_word),
    .madr(madr),
    .get(get)
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
    op = 0;
    start = 0;
    mblk = 512'd1234;
    got = 0;
    i_word = 32'd123;
    rst_b = 0;
    #25
    rst_b = 1;
  end
  
  initial begin
    repeat(CYCLES) begin
      adr = 32'd123;
      #(PERIOD)
      start = 1;
      #(PERIOD)
      adr = 32'd124;
      #(PERIOD * 10)
      got = 1;
      adr = 32'd125;
      #(PERIOD)
      got = 0;
      #(PERIOD)
      got = 0;
      #(PERIOD)
      op = 1;
      #(PERIOD)
      adr = 32'd10000;
      #(PERIOD * 5)
      got = 1;
      
    end
  end
  
endmodule

