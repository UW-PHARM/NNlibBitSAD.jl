for f in (:output_size,
          :channels_in,
          :channels_out,
          :channel_multiplier)
    @eval @nosim NNlib.$(f)(cdims::NNlib.ConvDims)
end

@nosim NNlib.DenseConvDims(x::AbstractArray{<:SBitstream}, w::AbstractArray{<:SBitstream}) kwargs=true
@nosim NNlib.DenseConvDims(cdims::ConvDims)
@nosim NNlib.PoolDims(x::AbstractArray{<:SBitstream}, k) kwargs=true

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
    y = similar(x_expanded, NNlib.im2col_dims(cdims_expanded)[1:2])
    NNlib.im2col!(y, x_expanded[:, :, :, :, 1], cdims_expanded)

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
    # set input/output at as signed and delete cdims from netlist
    BitSAD.setsigned!(netlist, inputs[1], true)
    BitSAD.setsigned!(netlist, outputs[1], true)
    delete!(netlist, inputs[2])

    # extract parameters
    cdims = BitSAD.value(inputs[2])
    IM_H, IM_W = BitSAD.netsize(inputs[1])[1:2]
    CHANNELS = NNlib.channels_in(cdims)
    PAD_H, PAD_W = NNlib.padding(cdims)
    STRIDE_H, STRIDE_W = NNlib.stride(cdims)
    KERNEL_H, KERNEL_W = NNlib.kernel_size(cdims)

    write(buffer, """
        $(BitSAD.stdcomment)
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
