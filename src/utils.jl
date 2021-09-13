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
