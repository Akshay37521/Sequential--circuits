interface SIPO_bus(input logic clk);
  logic in;
  logic rst;
  logic [3:0] out;

  clocking cb @(posedge clk);
    default input #1 output #1;
    input out;
    output in, rst;
  endclocking

  modport tb(clocking cb, input clk);
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
        assert(p.randomize());
        mbx.put(p);
      end
    endtask
  endclass


  
  class SIPO_drive;
    virtual SIPO_bus inf;
    mailbox #(SIPO_trans) mbx;

    int cycle = 0;

    function new(virtual SIPO_bus inf, mailbox #(SIPO_trans) mbx);
      this.inf = inf;
      this.mbx = mbx;
    endfunction

    
    task apply_reset(int cycles);
      repeat (cycles) begin
        @(inf.cb);
        inf.cb.rst <= 1;
        inf.cb.in  <= 0;
      end
      @(inf.cb);
      inf.cb.rst <= 0;
    endtask

    task run();
      SIPO_trans p;

      
      apply_reset(3);

      forever begin
        @(inf.cb);
        cycle++;

        
        if (cycle == 10) apply_reset(2);
        if (cycle == 30) apply_reset(3);
        if (cycle == 70) apply_reset(1);

        
        if (!inf.rst) begin
          mbx.get(p);
          inf.cb.in <= p.in;
        end
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

      forever begin
        @(inf.cb);

        p = new();
        p.in  = inf.in;
        p.rst = inf.rst;
        p.out = inf.cb.out;

        mbs.put(p);
      end
    endtask
  endclass


  
  class SIPO_scoreb;
    mailbox #(SIPO_trans) mbs;

    int pass = 0;
    int fail = 0;
    bit [3:0] expected;

    function new(mailbox #(SIPO_trans) mbs);
      this.mbs = mbs;
      expected = 0;
    endfunction

    task run();
      SIPO_trans p;

      forever begin
        mbs.get(p);

        if (p.rst) begin
          expected = 0;
        end
        else begin
          if (p.out !== expected) begin
            $display("[%0t] FAIL: out=%b expected=%b in=%b",
                      $time, p.out, expected, p.in);
            fail++;
          end
          else begin
            pass++;
          end

          expected = {expected[2:0], p.in};
        end
      end
    endtask
  endclass


  
  SIPO_gen g;
  SIPO_drive d;
  SIPO_monitor m;
  SIPO_scoreb s;

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
    join_none

    repeat (250) @(inf.cb);

    $display("\n--- FINAL RESULTS ---");
    $display("PASS: %0d FAIL: %0d", s.pass, s.fail);

    $finish;
  end

endprogram
