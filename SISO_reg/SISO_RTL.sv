module SISO_reg (
    input clk,
    input rst,
    input in,
    output reg out
);
    reg [3:0] tmp;

    always @(posedge clk) begin
        if (rst) begin
            tmp <= 4'b0000;
        end else begin
            // Shift logic: bit 0 takes 'in', bits 1-3 shift up
            tmp <= {tmp[2:0], in}; 
        end
    end

    // Standard 4-bit SISO: output is the last bit in the chain
    assign out = tmp[3]; 
endmodule

