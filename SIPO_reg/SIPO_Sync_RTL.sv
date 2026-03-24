module SIPO_reg (in,clk,rst,out);
  input in,clk,rst;
  output reg [3:0] out;
  
  
  
  always @(posedge clk) begin
    if(rst) begin
      out<=4'b0000;
    end
    
    else begin
      out<={out[2:0],in};
    end
    
  end
  
  
endmodule

  

