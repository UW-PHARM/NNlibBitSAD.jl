for f in (:output_size,
          :channels_in,
          :channels_out,
          :channel_multiplier)
    @eval BitSAD.@nosim NNlib.$(f)(cdims::NNlib.ConvDims)
end

BitSAD.@nosim NNlib.DenseConvDims(x::AbstractArray{<:SBitstream}, w::AbstractArray{<:SBitstream}) kwargs=true
BitSAD.@nosim NNlib.DenseConvDims(cdims::ConvDims)

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

Base.@kwdef mutable struct Im2ColHandler
    id = 0
end

BitSAD.gethandler(::Type{typeof(im2col)}, ::Type{<:AbstractArray{<:SBitstream}}, ::Type{<:ConvDims}) =
    Im2ColHandler()

function (handler::Im2ColHandler)(netlist::Netlist, inputs::Netlist, outputs::Netlist)
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

    outstring = """
        $(BitSAD.stdcomment)
        // BEGIN im2col$(handler.id)
        im2col #(
                .IM_HEIGHT($IM_H),
                .IM_WIDTH($IM_W),
                .CHANNELS($CHANNELS),
                .KERNEL_H($KERNEL_H),
                .KERNEL_W($KERNEL_W),
                .PAD_H($PAD_H),
                .PAD_W($PAD_W),
                .STRIDE_H($STRIDE_H),
                .STRIDE_W($STRIDE_W)
            ) im2col$(handler.id) (
                .CLK(CLK),
                .nRST(nRST),
                .im_p($(BitSAD.name(inputs[1]))_p),
                .im_m($(BitSAD.name(inputs[1]))_m),
                .col_p($(BitSAD.name(outputs[1]))_p),
                .col_m($(BitSAD.name(outputs[1]))_m)
            );
        // END im2col$(handler.id)
        \n"""

    handler.id += 1

    return outstring
end
