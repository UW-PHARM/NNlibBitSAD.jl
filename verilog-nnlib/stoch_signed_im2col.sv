`timescale 1ns / 1ps

module stoch_signed_im2col #(
  parameter IM_HEIGHT = 12;
  parameter IM_WIDTH = 12;
  parameter CHANNELS = 256;
  parameter KERNEL_H = 3;
  parameter KERNEL_W = 3;
  parameter PAD_H = 2;
  parameter PAD_W = 2;
  parameter STRIDE_H = 1;
  parameter STRIDE_W = 1;
) (
  input logic CLK,
  input logic nRST,
  input logic [(IM_HEIGHT-1):0][(IM_WIDTH-1):0][(CHANNELS-1):0] im_p,
  input logic [(IM_HEIGHT-1):0][(IM_WIDTH-1):0][(CHANNELS-1):0] im_m,
  output logic [(COL_HEIGHT-1):0][(COL_WIDTH-1):0] col_p,
  output logic [(COL_HEIGHT-1):0][(COL_WIDTH-1):0] col_m
);

// parameters
localparam IM_PAD_W = IM_WIDTH + PAD_W * 2;
localparam IM_PAD_H = IM_HEIGHT + PAD_H * 2;
localparam COL_HEIGHT = ((IM_PAD_H-KERNEL_H)/STRIDE_H +1)*((IM_PAD_W-KERNEL_W)/STRIDE_W +1);
localparam COL_WIDTH = KERNEL_H*KERNEL_W*CHANNELS;

integer channel, kernel_row, kernel_col, input_row, input_col;
always @(im_p, im_m) begin
  for (input_row = -PAD_H; input_row < IM_HEIGHT + PAD_H; input_row = input_row + STRIDE_H) begin
    for (input_col = -PAD_W; input_col < IM_WIDTH + PAD_W; input_col = input_col + STRIDE_W) begin
      for (channel = 0; channel < CHANNELS; channel = channel + 1) begin
        for (kernel_row = 0; kernel_row < KERNEL_H; kernel_row = kernel_row + 1) begin
          for (kernel_col = 0; kernel_col < KERNEL_W; kernel_col = kernel_col + 1) begin
            localparam integer output_row = (input_col + PAD_W) / STRIDE_W +
                                            ((input_row + PAD_H) / STRIDE_H) * ((IM_PAD_W - KERNEL_W) / STRIDE_W + 1);
            localparam integer output_col = kernel_col + kernel_row * KERNEL_W + channel * KERNEL_H * KERNEL_W;

            if ((input_row + kernel_row >= 0) && (input_row + kernel_row < IM_HEIGHT) &&
                (input_col + kernel_col >= 0) && (input_col + kernel_col < IM_WIDTH)) begin
              col_p[output_row][output_col] <= im_p[input_row + kernel_row][input_col + kernel_col][channel];
              col_m[output_row][output_col] <= im_m[input_row + kernel_row][input_col + kernel_col][channel];
            end
            else begin
              col_p[output_row][output_col] <= 1'b0;
              col_m[output_row][output_col] <= 1'b0;
            end
          end
        end
      end
    end
  end
end
// genvar channel, kernel_row, kernel_col, input_row, input_col;
// generate
// for (input_row = 0; input_row < IM_PAD_H-KERNEL_H+STRIDE_H; input_row = input_row + STRIDE_H) begin
//   for (input_col = 0; input_col < IM_PAD_W-KERNEL_W+STRIDE_W; input_col = input_col + STRIDE_W) begin
//     for (channel = 0 ; channel < CHANNELS ; channel = channel + 1) begin
//       for (kernel_row = 0; kernel_row < KERNEL_H; kernel_row = kernel_row + 1) begin
//         for (kernel_col = 0; kernel_col < KERNEL_W; kernel_col = kernel_col + 1) begin

//           localparam integer output_col = kernel_col+kernel_row*KERNEL_W+channel*KERNEL_H*KERNEL_W;
//           localparam integer output_row = input_col/STRIDE_W + (input_row/STRIDE_H)*((IM_PAD_W-KERNEL_W)/STRIDE_W + 1);
//           localparam integer input_offset = input_col+input_row*IM_PAD_W;
//           localparam integer input_idx = input_offset + kernel_col + kernel_row * IM_PAD_W;
//           // localparam integer idx_inChannel = input_idx % (IM_PAD_W*IM_PAD_H);

//           if (input_idx < IM_PAD_W * PAD_H ||
//               input_idx >= (IM_PAD_W * (IM_HEIGHT + PAD_H)) ||
//               (input_idx % IM_PAD_W) < PAD_W ||
//               (input_idx % IM_PAD_W) >= (IM_WIDTH + PAD_W) ) begin
//             assign col_p[output_row][output_col] = 1'b0;
//             assign col_m[output_row][output_col] = 1'b0;
//           end
//           else begin
//             assign col_p[output_row][output_col] = im_p[input_idx - PAD_H * IM_PAD_W - PAD_W - (input_row+kernel_row-PAD_H)*PAD_W*2 + channel*IM_HEIGHT*IM_WIDTH];
//             assign col_m[output_row][output_col] = im_m[input_idx - PAD_H * IM_PAD_W - PAD_W - (input_row+kernel_row-PAD_H)*PAD_W*2 + channel*IM_HEIGHT*IM_WIDTH];
//           end
//         end
//       end
//     end
//   end
// end
// endgenerate

endmodule
