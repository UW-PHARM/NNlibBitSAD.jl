`timescale 1ns / 1ps

module stoch_signed_maxpool #(
  parameter IM_HEIGHT = 12,
  parameter IM_WIDTH = 12,
  parameter CHANNELS = 3,
  parameter KERNEL_H = 3,
  parameter KERNEL_W = 3,
  parameter PAD_H = 2,
  parameter PAD_W = 2,
  parameter STRIDE_H = 1,
  parameter STRIDE_W = 1,

  localparam IM_PAD_W = IM_WIDTH + PAD_W * 2,
  localparam IM_PAD_H = IM_HEIGHT + PAD_H * 2,
  // take ceil https://stackoverflow.com/questions/52372409/using-ceil-to-define-a-parameter-in-systemverilog-in-quartus-prime
  localparam OUT_HEIGHT = ((IM_PAD_H - KERNEL_H + STRIDE_H - 1) / STRIDE_H + 1),
  localparam OUT_WIDTH = ((IM_PAD_W - KERNEL_W + STRIDE_W - 1) / STRIDE_W + 1)
) (
  input logic CLK,
  input logic nRST,
  input logic [(IM_HEIGHT-1):0][(IM_WIDTH-1):0][(CHANNELS-1):0] x_p,
  input logic [(IM_HEIGHT-1):0][(IM_WIDTH-1):0][(CHANNELS-1):0] x_m,
  output logic [(OUT_HEIGHT-1):0][(OUT_WIDTH-1):0][(CHANNELS-1):0] y_p,
  output logic [(OUT_HEIGHT-1):0][(OUT_WIDTH-1):0][(CHANNELS-1):0] y_m
);

logic [(OUT_HEIGHT-1):0][(OUT_WIDTH-1):0][(CHANNELS-1):0][(KERNEL_H-1):0][(KERNEL_W-1):0] x_patch_p, x_patch_m;

localparam integer MAX_CHANNEL_PER_LOOP = (CHANNELS < 10) ? 1 : 10;

genvar im_height, im_width, k_height, k_width;
generate
for (im_height = -PAD_H; im_height < IM_HEIGHT + PAD_H - KERNEL_H; im_height = im_height + STRIDE_H) begin : im_height_gen
  for (im_width = -PAD_W; im_width < IM_WIDTH + PAD_W - KERNEL_W; im_width = im_width + STRIDE_W) begin : im_width_gen
    localparam integer out_height = (im_height + PAD_H) / STRIDE_H;
    localparam integer out_width = (im_width + PAD_W) / STRIDE_W;
    stoch_signed_rev_patch #(
        .WIDTH(IM_WIDTH),
        .HEIGHT(IM_HEIGHT),
        .CHANNELS(CHANNELS),
        .BASE_W(im_width),
        .BASE_H(im_height),
        .PATCH_W(KERNEL_W),
        .PATCH_H(KERNEL_H),
        .DEFAULT(1'b0)
      ) patchi (
        .CLK(CLK),
        .nRST(nRST),
        .in_p(x_p),
        .in_m(x_m),
        .patch_p(x_patch_p[out_height][out_width]),
        .patch_m(x_patch_m[out_height][out_width])
      );
  end
end
endgenerate

genvar height, width, channels, channel_block_1;
generate
for (channel_block_1 = 0; channel_block_1 < CHANNELS / MAX_CHANNEL_PER_LOOP; channel_block_1 = channel_block_1 + 1) begin : channel_block_gen
  for (channels = channel_block_1 * MAX_CHANNEL_PER_LOOP; channels < MAX_CHANNEL_PER_LOOP; channels = channels + 1) begin : channel_gen
    for (height = 0; height < OUT_HEIGHT; height = height + 1) begin : height_gen
      for (width = 0; width < OUT_WIDTH; width = width + 1) begin : width_gen
        stoch_signed_nmax #(
            .NUM_INPUTS(KERNEL_W * KERNEL_H)
          ) maxi (
            .CLK(CLK),
            .nRST(nRST),
            .as_p(x_patch_p[height][width][channels]),
            .as_m(x_patch_m[height][width][channels]),
            .y_p(y_p[height][width][channels]),
            .y_m(y_m[height][width][channels])
          );
      end
    end
  end
end

for (channels = MAX_CHANNEL_PER_LOOP * (CHANNELS / MAX_CHANNEL_PER_LOOP); channels < CHANNELS; channels = channels + 1) begin : channel_rem_gen
  for (height = 0; height < OUT_HEIGHT; height = height + 1) begin : height1_gen
    for (width = 0; width < OUT_WIDTH; width = width + 1) begin : width1_gen
      stoch_signed_nmax #(
          .NUM_INPUTS(KERNEL_W * KERNEL_H)
        ) maxi (
          .CLK(CLK),
          .nRST(nRST),
          .as_p(x_patch_p[height][width][channels]),
          .as_m(x_patch_m[height][width][channels]),
          .y_p(y_p[height][width][channels]),
          .y_m(y_m[height][width][channels])
        );
    end
  end
end
endgenerate

endmodule
