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

logic [(OUT_HEIGHT-1):0][(OUT_WIDTH-1:0)][(CHANNELS-1):0][(KERNEL_H-1):0][(KERNEL_W-1):0] x_patch_p, x_patch_m;

integer im_height, im_width, im_channels, k_height, k_width;
always @(x_p, x_m) begin
  for (im_channels = 0; im_channels < CHANNELS; im_channels = im_channels + 1) begin
    for (im_height = -PAD_H; im_height < IM_HEIGHT + PAD_H - KERNEL_H; im_height = im_height + STRIDE_H) begin
      for (im_width = -PAD_W; im_width < IM_WIDTH + PAD_W - KERNEL_W; im_width = im_width + STRIDE_W) begin
        for (k_height = 0; k_height < KERNEL_H; k_height = k_height + 1) begin
          for (k_width = 0; k_width < KERNEL_W; k_width = k_width + 1) begin
            integer out_height = (im_height + PAD_H) / STRIDE_H;
            integer out_width = (im_width + PAD_W) / STRIDE_W;
            if ((im_height + k_height >= 0) && (im_height + k_height < IM_HEIGHT) &&
                (im_width + k_width >= 0) && (im_width + k_width < IM_WIDHT)) begin
              x_patch_p[out_height][out_width][im_channels][k_height][k_width] =
                x_p[im_height + k_height][im_width + k_width][channels];
              x_patch_m[out_height][out_width][im_channels][k_height][k_width] =
                x_m[im_height + k_height][im_width + k_width][channels];
            end
            else begin
              x_patch_p[out_height][out_width][im_channels][k_height][k_width] = 1'b0;
              x_patch_m[out_height][out_width][im_channels][k_height][k_width] = 1'b0;
            end
          end
        end
      end
    end
  end
end

// genvar im_height, im_width, im_channels, k_width, k_height;
// generate
//     for (im_channels = 0; im_channels < CHANNELS; im_channels = im_channels + 1) begin : pad_channel_gen
//         for (im_width = -PAD_W; im_width < IM_WIDTH + PAD_W - KERNEL_W; im_width = im_width + STRIDE_W) begin : pad_width_gen
//             for (im_height = -PAD_H; im_height < IM_HEIGHT + PAD_H - KERNEL_H; im_height = im_height + STRIDE_H) begin : pad_height_gen
//                 localparam pad_width = im_width + PAD_W;
//                 localparam pad_height = im_height + PAD_H;
//                 localparam row = pad_height / STRIDE_H;
//                 localparam col = pad_width / STRIDE_W;
//                 localparam base = (col * OUT_HEIGHT + row + im_channels * OUT_WIDTH * OUT_HEIGHT) * KERNEL_H * KERNEL_W;
//                 for (k_width = 0; k_width < KERNEL_W; k_width = k_width + 1) begin : pad_k_width_gen
//                     for (k_height = 0; k_height < KERNEL_H; k_height = k_height + 1) begin : pad_k_height_gen
//                         localparam out_idx = base + k_width * KERNEL_H + k_height;
//                         localparam in_idx = (im_channels * IM_HEIGHT * IM_WIDTH) +
//                                             ((im_width + k_width) * IM_HEIGHT) + im_height + k_height;

//                         if ((im_width + k_width >= 0) && (im_width + k_width < IM_WIDTH) &&
//                            (im_height + k_height >= 0) && (im_height + k_height < IM_HEIGHT)) begin
//                             assign x_patch_p[out_idx] = x_p[in_idx];
//                             assign x_patch_m[out_idx] = x_m[in_idx];
//                         end
//                         else begin
//                             assign x_patch_p[out_idx] = 1'b0;
//                             assign x_patch_m[out_idx] = 1'b0;
//                         end
//                     end
//                 end
//             end
//         end
//     end
// endgenerate

genvar height, width, channels;
generate
    for (channels = 0; channels < CHANNELS; channels = channels + 1) begin : channel_gen
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
endgenerate

endmodule
