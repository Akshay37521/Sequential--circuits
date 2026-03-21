// ---------------------------------------------------------
// 1. Interface with Clocking Block
// ---------------------------------------------------------
interface D_bus(input logic clk);
  logic D, rst, out;

  clocking cb @(posedge clk or posedge rst);
    default input #1 output #1;
    output D, rst;
    input out;
  endclocking

  modport tb(clocking cb, input clk, input D, input rst);
endinterface

// ---------------------------------------------------------
// 2. D-Flip-Flop DUT
// ---------------------------------------------------------
module D_ff (
  input clk, rst, D,
  output reg out
);
  always @(posedge clk) begin
    if (rst) out <= 1'b0;
    else     out <= D;
  end
endmodule

// ---------------------------------------------------------
// 3. Testbench Components
// ---------------------------------------------------------
module D_ff_tb;
  bit clk = 0;
  always #5 clk = ~clk;

  D_bus inf(clk);
  D_ff dut(.clk(inf.clk), .rst(inf.rst), .D(inf.D), .out(inf.out));

  class D_trans;
    rand bit D;
    rand bit rst;
    bit out;
  endclass

  mailbox #(D_trans) mbx = new(); 
  mailbox #(D_trans) mbs = new();

  // Generator: Creates 200 transactions
  class D_gen;
    mailbox #(D_trans) mbx;
    function new(mailbox #(D_trans) mbx); this.mbx = mbx; endfunction

    task run();
      D_trans t;
      repeat(5) begin // Initial Reset
        t = new(); t.rst = 1; t.D = 0;
        mbx.put(t);
      end
      repeat(195) begin // Random Stimulus
        t = new();
        void'(t.randomize() with { rst == 0; });
        mbx.put(t);
      end
    endtask
  endclass

  // Driver: Drives DUT via Clocking Block
  class D_driver;
    virtual D_bus inf;
    mailbox #(D_trans) mbx;
    function new(virtual D_bus inf, mailbox #(D_trans) mbx);
      this.inf = inf; this.mbx = mbx;
    endfunction

    task run();
      D_trans t;
      forever begin
        mbx.get(t);
        @(inf.cb);
        inf.cb.D   <= t.D;
        inf.cb.rst <= t.rst;
      end
    endtask
  endclass

  // Monitor: Samples DUT (Corrected Sampling)
  class D_monitor;
    virtual D_bus inf;
    mailbox #(D_trans) mbs;
    function new(virtual D_bus inf, mailbox #(D_trans) mbs);
      this.inf = inf; this.mbs = mbs;
    endfunction

    task run();
      D_trans t;
      forever begin
        @(inf.cb); 
        t = new();
        // Use raw signals for inputs to avoid Questasim vsim-8441 warning
        t.D   = inf.D;   
        t.rst = inf.rst;
        // Use cb for output to ensure #1 skew sampling
        t.out = inf.cb.out; 
        mbs.put(t);
      end
    endtask
  endclass

  // Scoreboard: Validates results (Corrected Logic)
  class D_scoreboard;
    mailbox #(D_trans) mbs;
    int item_pass = 0, item_fail = 0;
    bit expected = 0; 

    function new(mailbox #(D_trans) mbs); this.mbs = mbs; endfunction

    task run();
      D_trans t;
      forever begin
        mbs.get(t);
        if (t.out === expected) item_pass++;
        else begin
          item_fail++;
          $display("[%0t] FAIL: out=%b expected=%b (D=%b, rst=%b)", 
                   $time, t.out, expected, t.D, t.rst);
        end
        // Predict NEXT cycle's output based on CURRENT sampled inputs
        expected = t.rst ? 0 : t.D;
      end
    endtask
  endclass

  // ---------------------------------------------------------
  // 4. Main Simulation Control
  // ---------------------------------------------------------
  D_gen g; D_driver d; D_monitor m; D_scoreboard s;

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
    join_any // Generator finishes first

    // Wait until Scoreboard processes all 200 transactions
    wait(s.item_pass + s.item_fail == 200);
    
    #10; 
    $display("--- Final Results ---");
    $display("Total Transactions: %0d", s.item_pass + s.item_fail);
    $display("Pass: %0d, Fail: %0d", s.item_pass, s.item_fail);
    $finish;
  end
endmodule
