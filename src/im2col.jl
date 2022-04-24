# prevent aliasing with im2col! and SBitstream
function NNlib.im2col!(col::AbstractArray{SBitstream{T}, 2},
                       x::AbstractArray{SBitstream{T}, 4},
                       cdims::ConvDims) where T
    colfloat = similar(col, T, size(col)...)
    NNlib.im2col!(colfloat, float.(x), cdims)
    col .= SBitstream.(colfloat)

    return col
end

function im2col(x, cdims)
    cdims_expanded = NNlib.insert_singleton_spatial_dimension(cdims)
    x_expanded = NNlib.insert_singleton_spatial_dimension(x)
    bs = size(x, 4)
    npatches, ps = NNlib.im2col_dims(cdims_expanded)[1:2]
    y = similar(x_expanded, npatches * bs, ps)
    @threads for i in 1:bs
        idx = ((i - 1) * npatches + 1):(i * npatches)
        y_i = @view y[idx, :]
        x_i = @view x_expanded[:, :, :, :, i]
        NNlib.im2col!(y_i, x_i, cdims_expanded)
    end

    return y
end

BitSAD.is_trace_primitive(::Type{typeof(im2col)},
                          ::Type{<:AbstractArray{<:SBitstream}},
                          ::Type{<:ConvDims}) = true
BitSAD.getsimulator(::typeof(im2col), x, cdims) = im2col

struct SIm2ColHandler end

BitSAD.gethandler(broadcasted, ::Type{typeof(im2col)}, ::Type{<:AbstractArray{<:SBitstream}}, ::Type{<:ConvDims}) =
    broadcasted ? error("Cannot generate hardware for broadcasted im2col.") : SIm2ColHandler()
BitSAD.init_state(::SIm2ColHandler) = (id = 0,)

function (handler::SIm2ColHandler)(buffer, netlist, state, inputs, outputs)
    # delete cdims from netlist
    delete!(netlist, inputs[2])

    # extract parameters
    cdims = BitSAD.value(inputs[2])
    IM_H, IM_W = BitSAD.netsize(inputs[1])[1:2]
    CHANNELS = NNlib.channels_in(cdims)
    PAD_H, PAD_W = NNlib.padding(cdims)
    STRIDE_H, STRIDE_W = NNlib.stride(cdims)
    KERNEL_H, KERNEL_W = NNlib.kernel_size(cdims)

    write(buffer, """
        // BEGIN im2col$(state.id)
        stoch_signed_im2col #(
                .IM_HEIGHT($IM_H),
                .IM_WIDTH($IM_W),
                .CHANNELS($CHANNELS),
                .KERNEL_H($KERNEL_H),
                .KERNEL_W($KERNEL_W),
                .PAD_H($PAD_H),
                .PAD_W($PAD_W),
                .STRIDE_H($STRIDE_H),
                .STRIDE_W($STRIDE_W)
            ) im2col$(state.id) (
                .CLK(CLK),
                .nRST(nRST),
                .im_p($(BitSAD.name(inputs[1]))_p),
                .im_m($(BitSAD.name(inputs[1]))_m),
                .col_p($(BitSAD.name(outputs[1]))_p),
                .col_m($(BitSAD.name(outputs[1]))_m)
            );
        // END im2col$(state.id)
        \n""")

    return buffer, (id = state.id + 1,)
end

function col2im(y, h, w, c, b)
    yim = similar(y, h, w, c, b)
    npatches = size(y, 1) ÷ b
    @threads for i in 1:b
        idx = ((i - 1) * npatches + 1):(i * npatches)
        yim[:, :, :, i] = reshape(y[idx, :], h, w, c, 1)
    end

    return yim
end

BitSAD.is_trace_primitive(::Type{typeof(col2im)},
                          ::Type{<:AbstractArray{<:SBitstream}},
                          h, w, c, b) = true
BitSAD.getsimulator(::typeof(col2im), y, h, w, c, b) = col2im
