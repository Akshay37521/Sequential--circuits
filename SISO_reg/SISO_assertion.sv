module SISO_reg (
  input  logic clk,
  input  logic rst,
  input  logic in,
  output logic out
);
  logic [3:0] shift_reg;

  always_ff @(posedge clk) begin
    if (rst)
      shift_reg <= 4'b0;
    else
      shift_reg <= {shift_reg[2:0], in};
  end

  assign out = shift_reg[3];
endmodule





interface SISO_bus (input logic clk);

  logic rst;
  logic in;
  logic out;

  
  clocking cb @(posedge clk);
    default input #1 output #1;
    input  out;
    output rst, in;
  endclocking

  
  clocking cb_mon @(posedge clk);
    default input #1;
    input out;
    input in;
    input rst;
  endclocking

  modport tb  (clocking cb,     input clk);
  modport mon (clocking cb_mon, input clk);



  
  property reset_check;
    @(posedge clk)
    rst |=> (out == 0);
  endproperty
  assert property (reset_check)
    else $error("Assert Fail: Output not zero after sync reset");

  property shift_check;
    @(posedge clk)
    disable iff (rst)
      (!rst && $past(!rst,1) && $past(!rst,2) && $past(!rst,3) && $past(!rst,4))
        |-> (out == $past($sampled(in), 4));
  endproperty
  assert property (shift_check)
    else $error("Assert Fail: Shift behavior incorrect");

  property stability_check;
    @(posedge clk)
    disable iff (rst)
    $stable(in)[*4] |=> $stable(out)[*4];
  endproperty
  assert property (stability_check)
    else $error("Assert Fail: Stability incorrect");

endinterface





module top;

  bit clk = 0;
  always #5 clk = ~clk;

  SISO_bus inf (clk);

  initial begin
    inf.rst = 1;
    inf.in  = 0;
    repeat(3) @(posedge clk);
    inf.rst = 0;
  end

  SISO_reg dut (
    .clk (inf.clk),
    .rst (inf.rst),
    .in  (inf.in),
    .out (inf.out)
  );

  SISO_tb tb (inf);

endmodule





program SISO_tb (SISO_bus inf);



  
  class SISO_trans;
    rand bit in;
    rand bit rst;
    bit      out;

    constraint rst_dist { rst dist {1 := 10, 0 := 90}; }
    constraint valid    { if (rst) in == 0; }
  endclass

  mailbox #(SISO_trans) mbx = new();  
  mailbox #(SISO_trans) mbs = new();  

  
  
  
  class SISO_gen;
    mailbox #(SISO_trans) mbx;

    function new (mailbox #(SISO_trans) mbx);
      this.mbx = mbx;
    endfunction

    task run();
      SISO_trans t;
      repeat (200) begin
        t = new();
        assert(t.randomize());
        mbx.put(t);
      end
    endtask
  endclass

  
  
  
  class SISO_drive;
    virtual SISO_bus inf;
    mailbox #(SISO_trans) mbx;

    function new (virtual SISO_bus inf, mailbox #(SISO_trans) mbx);
      this.inf = inf;
      this.mbx = mbx;
    endfunction

    task run();
      SISO_trans t;
      forever begin
        mbx.get(t);
        @(inf.cb);
        inf.cb.in  <= t.in;
        inf.cb.rst <= t.rst;
      end
    endtask
  endclass

  
  
  
  class SISO_monitor;
    virtual SISO_bus inf;
    mailbox #(SISO_trans) mbs;

    function new (virtual SISO_bus inf, mailbox #(SISO_trans) mbs);
      this.inf = inf;
      this.mbs = mbs;
    endfunction

    task run();
      SISO_trans t;
      forever begin
        @(inf.cb_mon);

        t       = new();
        t.in    = inf.cb_mon.in;
        t.rst   = inf.cb_mon.rst;
        t.out   = inf.cb_mon.out;

        mbs.put(t);
      end
    endtask
  endclass

    class SISO_scoreb;
    mailbox #(SISO_trans) mbs;
    int       pass          = 0;
    int       fail          = 0;
    bit [3:0] expected      = 0;
    bit       pending_reset = 0;

    function new (mailbox #(SISO_trans) mbs);
      this.mbs = mbs;
    endfunction

    task run();
      SISO_trans t;
      forever begin
        mbs.get(t);

        
        
        
        if (pending_reset) begin
        
          if (t.out !== 1'b0) begin
            $display("[%0t] FAIL (RESET): out=%b  expected 0 (sync reset takes 1 cycle)",
                     $time, t.out);
            fail++;
          end else begin
            pass++;
          end
          pending_reset = 0;

        end else begin
          
          if (t.out !== expected[3]) begin
            $display("[%0t] FAIL: out=%b  expected_msb=%b  in=%b",
                     $time, t.out, expected[3], t.in);
            fail++;
          end else begin
            pass++;
          end
        end

        
        
        
        if (t.rst) begin
          pending_reset = 1;   
          expected      = 4'b0;
        end else begin
          expected = {expected[2:0], t.in};
        end

      end
    endtask
  endclass

  
  
  
  SISO_gen     g;
  SISO_drive   d;
  SISO_monitor m;
  SISO_scoreb  s;

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
    join_any

    wait(s.pass + s.fail == 200);

    #10;
    
    $display("  Total = %0d   Pass = %0d   Fail = %0d",
             s.pass + s.fail, s.pass, s.fail);
    

    $finish;
  end

endprogram
