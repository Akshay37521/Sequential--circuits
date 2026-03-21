interface D_bus(input logic clk);
  logic D, rst, out;

  clocking cb @(posedge clk);
    default input #1step output #0;
    output D, rst;
    input out;
  endclocking

  modport tb(clocking cb, input clk);
  modport DUT_tb(input clk, rst, D, output out);
endinterface


module D_ff_tb;

  bit clk = 0;
  always #5 clk = ~clk;

  D_bus inf(clk);

  // DUT
  D_ff dut(.D(inf.D), .rst(inf.rst), .out(inf.out), .clk(inf.clk));

  // Transaction
  class D_trans;
    rand bit D;
    rand bit rst;
    bit out;
  endclass

  mailbox #(D_trans) mbx = new();
  mailbox #(D_trans) mbs = new();

  // Generator
  class D_gen;
    mailbox #(D_trans) mbx;

    function new(mailbox #(D_trans) mbx);
      this.mbx = mbx;
    endfunction

    task run();
      D_trans t;

      // Reset phase
      repeat(5) begin
        t = new();
        t.rst = 1;
        t.D   = 0;
        mbx.put(t);
      end

      // Normal operation
      repeat(195) begin
        t = new();
        assert(t.randomize() with { rst == 0; });
        mbx.put(t);
      end
    endtask
  endclass


  // Driver
  class D_driver;
    virtual D_bus inf;
    mailbox #(D_trans) mbx;

    function new(virtual D_bus inf, mailbox #(D_trans) mbx);
      this.inf = inf;
      this.mbx = mbx;
    endfunction

    task run();
      D_trans t;
      repeat(200) begin
        mbx.get(t);
        @(inf.cb);
        inf.cb.D   <= t.D;
        inf.cb.rst <= t.rst;
      end
    endtask
  endclass


  // Monitor
  class D_monitor;
    virtual D_bus inf;
    mailbox #(D_trans) mbs;

    function new(virtual D_bus inf, mailbox #(D_trans) mbs);
      this.inf = inf;
      this.mbs = mbs;
    endfunction

    task run();
      D_trans t;
      repeat(200) begin
        @(inf.cb);
        t = new();
        t.D   = inf.cb.D;
        t.rst = inf.cb.rst;
        t.out = inf.cb.out;
        mbs.put(t);
      end
    endtask
  endclass


  // Scoreboard
  class D_scoreboard;
    mailbox #(D_trans) mbs;
    int pass = 0;
    int fail = 0;

    function new(mailbox #(D_trans) mbs);
      this.mbs = mbs;
    endfunction

    task run();
      D_trans t;
      bit prev_D = 0;
      bit expected;
      int valid_cycles = 0;

      repeat(200) begin
        mbs.get(t);

        if (t.rst) begin
          expected = 0;
          prev_D = 0;
          valid_cycles = 0;
        end
        else begin
          expected = prev_D;
          prev_D = t.D;
          valid_cycles++;
        end

        // Ignore initial pipeline cycles
        if (valid_cycles > 1) begin
          if (t.out == expected) begin
            $display("PASS: t=%0t D=%b out=%b expected=%b rst=%b",
                     $time, t.D, t.out, expected, t.rst);
            pass++;
          end
          else begin
            $display("FAIL: t=%0t D=%b out=%b expected=%b rst=%b",
                     $time, t.D, t.out, expected, t.rst);
            fail++;
          end
        end
      end

      $display("=================================");
      $display("PASS COUNT = %0d", pass);
      $display("FAIL COUNT = %0d", fail);
      $display("=================================");
    endtask
  endclass


  // Instances
  D_gen        g;
  D_driver     d;
  D_monitor    m;
  D_scoreboard s;

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
    join

    $display("Simulation Finished");
    $finish;
  end

endmodule
