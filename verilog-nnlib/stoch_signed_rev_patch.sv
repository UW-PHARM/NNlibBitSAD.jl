`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: PHARM
// Engineer: Kyle Daruwalla
//
// Create Date: 02/01/2022
// Module Name: stoch_signed_rev_patch
// Description:
//  Given a signed stochastic input array, select a 2D patch of the array.
//  Like stoch_signed_patch except the patch port is DEPTH x HEIGHT x WIDTH
//   instead of HEIGHT x WIDTH x DEPTH
//////////////////////////////////////////////////////////////////////////////////
module stoch_signed_rev_patch #(
  parameter WIDTH = 32,
  parameter HEIGHT = 32,
  parameter CHANNELS = 3,
  parameter BASE_W = 0,
  parameter BASE_H = 0,
  parameter PATCH_W = 3,
  parameter PATCH_H = 3,
  parameter DEFAULT = 1'b0
) (
  input logic CLK,
  input logic nRST,
  input logic [(HEIGHT-1):0][(WIDTH-1):0][(CHANNELS-1):0] in_p,
  input logic [(HEIGHT-1):0][(WIDTH-1):0][(CHANNELS-1):0] in_m,
  output logic [(CHANNELS-1):0][(PATCH_H-1):0][(PATCH_W-1):0] patch_p,
  output logic [(CHANNELS-1):0][(PATCH_H-1):0][(PATCH_W-1):0] patch_m
);

localparam integer MAX_CHANNEL_PER_LOOP = (CHANNELS < 10) ? 1 : 10;

integer channel_block, channel, patch_row, patch_col;
always @(in_p, in_m) begin
  for (channel_block = 0; channel_block < CHANNELS / MAX_CHANNEL_PER_LOOP; channel_block = channel_block + 1) begin
    for (channel = channel_block * MAX_CHANNEL_PER_LOOP; channel < MAX_CHANNEL_PER_LOOP; channel = channel + 1) begin
      for (patch_row = 0; patch_row < PATCH_H; patch_row = patch_row + 1) begin
        for (patch_col = 0; patch_col < PATCH_W; patch_col = patch_col + 1) begin
          if ((BASE_H + patch_row >= 0) && (BASE_H + patch_row < HEIGHT) &&
              (BASE_W + patch_col >= 0) && (BASE_W + patch_col < WIDTH)) begin
            patch_p[channel][patch_row][patch_col] = in_p[BASE_H + patch_row][BASE_W + patch_col][channel];
            patch_m[channel][patch_row][patch_col] = in_m[BASE_H + patch_row][BASE_W + patch_col][channel];
          end
          else begin
            patch_p[channel][patch_row][patch_col] = DEFAULT;
            patch_m[channel][patch_row][patch_col] = DEFAULT;
          end
        end
      end
    end
  end

  for (channel = MAX_CHANNEL_PER_LOOP * (CHANNELS / MAX_CHANNEL_PER_LOOP); channel < CHANNELS; channel = channel + 1) begin
    for (patch_row = 0; patch_row < PATCH_H; patch_row = patch_row + 1) begin
      for (patch_col = 0; patch_col < PATCH_W; patch_col = patch_col + 1) begin
        if ((BASE_H + patch_row >= 0) && (BASE_H + patch_row < HEIGHT) &&
            (BASE_W + patch_col >= 0) && (BASE_W + patch_col < WIDTH)) begin
          patch_p[channel][patch_row][patch_col] = in_p[BASE_H + patch_row][BASE_W + patch_col][channel];
          patch_m[channel][patch_row][patch_col] = in_m[BASE_H + patch_row][BASE_W + patch_col][channel];
        end
        else begin
          patch_p[channel][patch_row][patch_col] = DEFAULT;
          patch_m[channel][patch_row][patch_col] = DEFAULT;
        end
      end
    end
  end
end

endmodule
