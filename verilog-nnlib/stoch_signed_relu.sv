`timescale 1ns / 1ps

module stoch_signed_relu (
  input logic CLK,
  input logic nRST,
  input logic in_p,
  input logic in_m,
  output logic out_p,
  output logic out_m
);

assign out_p = in_p;
assign out_m = 1'b0;

endmodule
