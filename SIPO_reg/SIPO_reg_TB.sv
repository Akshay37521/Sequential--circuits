interface SIPO_bus(input logic clk);
  logic in;
  logic rst;
  logic [3:0] out;

  clocking cb @(posedge clk);
    default input #1 output #1;
    input out;
    output in;
  endclocking

  modport tb(clocking cb, input clk, input rst);
endinterface


module top;
  bit clk = 0;
  always #5 clk = ~clk;

  SIPO_bus inf(clk);

  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;   
  end

  SIPO_reg DUT(.clk(inf.clk), .rst(inf.rst), .in(inf.in), .out(inf.out));
  SIPO_tb tb(inf);
endmodule


program SIPO_tb(SIPO_bus inf);

  
  class SIPO_trans;
    rand bit in;
    bit rst;
    bit [3:0] out;
  endclass


  mailbox #(SIPO_trans) mbx = new();
  mailbox #(SIPO_trans) mbs = new();


  
  class SIPO_gen;
    mailbox #(SIPO_trans) mbx;

    function new(mailbox #(SIPO_trans) mbx);
      this.mbx = mbx;
    endfunction

    task run();
      SIPO_trans p;
      repeat (200) begin
        p = new();
        assert(p.randomize()) else $error("Randomization failed");
        mbx.put(p);
      end
    endtask
  endclass


  
  class SIPO_drive;
    virtual SIPO_bus inf;
    mailbox #(SIPO_trans) mbx;

    function new(virtual SIPO_bus inf, mailbox #(SIPO_trans) mbx);
      this.inf = inf;
      this.mbx = mbx;
    endfunction

    task run();
      SIPO_trans p;
      repeat (200) begin
        mbx.get(p);
        @(inf.cb);

        assert(!$isunknown(p.in)) else $error("Driver input X");

        inf.cb.in <= p.in;
      end
    endtask
  endclass


  
  class SIPO_monitor;
    virtual SIPO_bus inf;
    mailbox #(SIPO_trans) mbs;

    function new(virtual SIPO_bus inf, mailbox #(SIPO_trans) mbs);
      this.inf = inf;
      this.mbs = mbs;
    endfunction

    task run();
      SIPO_trans p;

      repeat (200) begin
        @(inf.cb);

        p = new();

        assert(!$isunknown(inf.cb.out))
          else $error("Monitor output X");

        p.in  = inf.in;
        p.rst = inf.rst;
        p.out = inf.cb.out;

        mbs.put(p);
      end
    endtask
  endclass


  
  class SIPO_scoreb;
    mailbox #(SIPO_trans) mbs;
    int item_pass = 0;
    int item_fail = 0;
    bit [3:0] expected;

    function new(mailbox #(SIPO_trans) mbs);
      this.mbs = mbs;
      expected = 0;
    endfunction

    task run();
      SIPO_trans p;

      repeat (200) begin
        mbs.get(p);

        
        if (p.rst) begin
          if (p.out == 0) begin
            $display("[%0t] RESET : out=%b (expected 0)", 
                      $time, p.out);
            item_pass++;
          end
          expected = 0;
        end
        else begin
          if (p.out !== expected) begin
            $display("[%0t] FAIL: out=%b expected=%b in=%b",
                      $time, p.out, expected, p.in);
            item_fail++;
          end
          else begin
            $display("[%0t] PASS: out=%b expected=%b in=%b",
                      $time, p.out, expected, p.in);
            item_pass++;
          end

          expected = {expected[2:0], p.in};
        end
      end
    endtask
  endclass


  
  task async_reset();

    
    inf.rst = 1;
    #20 inf.rst = 0;

    
    #10 inf.rst = 1;   
    #3  inf.rst = 0;

    #40 inf.rst = 1;   
    #4  inf.rst = 0;

    #10 inf.rst = 1;   
    #2  inf.rst = 0;

  endtask


  
  SIPO_gen     g;
  SIPO_drive   d;
  SIPO_monitor m;
  SIPO_scoreb  s;

  initial begin
    g = new(mbx);
    d = new(inf, mbx);
    m = new(inf, mbs);
    s = new(mbs);

    fork
      g.run();
      d.run();
      m.run();
      s.run();
      async_reset();   
    join

    $display("\n--- Final Results ---");
    $display("Total: %0d", s.item_pass + s.item_fail);
    $display("Pass: %0d Fail: %0d", s.item_pass, s.item_fail);

    $finish;
  end

endprogram
