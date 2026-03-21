module D_ff(D,rst,out,clk);
  input D,rst,clk;
  output reg out;
  always @(posedge clk or posedge rst) begin
    if(rst)
      out<=0;
    else
      out<=D;
  end
endmodule

  
