`timescale 1ns / 1ps

module stoch_signed_relu(CLK, nRST, in_p, in_m, out_p, out_m);

// I/O
input CLK, nRST;
input in_p, in_m;
output out_p, out_m;

assign out_p = in_p;
assign out_m = 1'b0;

endmodule
