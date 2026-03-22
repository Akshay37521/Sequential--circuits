interface SISO_bus(input logic clk);
  logic rst;
  logic in;
  logic out;
  
  clocking cb@(posedge clk);
    default input#1 output #1;
    input out;
    output rst,in;
  endclocking
  
  modport tb(clocking cb,input clk);
    
endinterface

module top;
  bit clk =0;
  always #5 clk = ~clk;
  SISO_bus inf(clk);
  SISO_reg dut(.clk(inf.clk),.rst(inf.rst),.in(inf.in),.out(inf.out));
  SISO_tb tb(inf);
endmodule
    
program SISO_tb(SISO_bus inf);
  class SISO_trans;
    rand bit in;
    rand bit rst;
    rand bit out;
    constraint rst_dist {
    rst dist {1 := 10, 0 := 90};
    }

  
    constraint valid {
    if (rst) in == 0;
    }
  endclass
  
  mailbox #(SISO_trans) mbx = new();
  mailbox #(SISO_trans) mbs = new();
  
  class SISO_gen;
    mailbox #(SISO_trans) mbx;
    function new(mailbox #(SISO_trans) mbx );
      this.mbx = mbx;
    endfunction
    task run();
      SISO_trans p1;
      repeat(5) begin
        p1 = new();
        p1.rst =1;
        p1.in = 0;
        mbx.put(p1);
      end
      repeat(195) begin
        p1 = new();
        void' (p1.randomize() );
        mbx.put(p1);
      end
    endtask
  endclass
  
  class SISO_drive;
    virtual SISO_bus inf;
    mailbox #(SISO_trans) mbx;
    function new(virtual SISO_bus inf,mailbox #(SISO_trans) mbx);
      this.inf = inf;
      this.mbx = mbx;
    endfunction
    
    task run();
      SISO_trans p2;
      forever begin
        mbx.get(p2);
        @(inf.cb);
        inf.cb.in <= p2.in;
        inf.cb.rst <= p2.rst;
      end
    endtask
  endclass
  
  class SISO_monitor;
    virtual SISO_bus inf;
    mailbox #(SISO_trans) mbs;
    function new(virtual SISO_bus inf, mailbox #(SISO_trans) mbs);
      this.inf = inf;
      this.mbs = mbs;
    endfunction
    
    task run();
      SISO_trans p3;
      forever begin
        @(inf.cb)
        p3 = new();
        p3.in = inf.in;
        p3.rst = inf.rst;
        p3.out = inf.cb.out;
        mbs.put(p3);
      end
    endtask
  endclass
  
  class SISO_scoreb;
    mailbox #(SISO_trans) mbs;
    int item_pass = 0;
    int item_fail = 0;
    bit [3:0] expected;
    function new(mailbox #(SISO_trans) mbs);
      this.mbs = mbs;
    endfunction
    
    

    task run();
      SISO_trans p4;
       forever begin
         mbs.get(p4);

         if (p4.out !== expected[3]) begin
           $display("[%0t] FAIL: out=%b expected=%b input =%b", $time, p4.out, expected,p4.in);
           item_fail++;
         end
         else begin
           $display("[%0t] PASS: out=%b expected=%b input =%b", $time, p4.out, expected,p4.in);
           item_pass++;
         end
         
        if (p4.rst)
          expected = 0;
        else
          expected = {expected[2:0], p4.in};
       end
    endtask
  endclass
  
  SISO_gen g; SISO_drive d; SISO_monitor m; SISO_scoreb s;
  initial begin
    g = new(mbx);
    d = new(inf,mbx);
    m = new(inf,mbs);
    s = new(mbs);
    fork
      g.run();
      d.run();
      m.run();
      s.run();
    join_any // Generator finishes first

    // Wait until Scoreboard processes all 200 transactions
    wait(s.item_pass + s.item_fail == 200);
    
    #10; 
    $display("--- Final Results ---");
    $display("Total Transactions: %0d", s.item_pass + s.item_fail);
    $display("Pass: %0d, Fail: %0d", s.item_pass, s.item_fail);
    $finish;
  end
endprogram
    
  
      
  

    
    
  
      
    
    
