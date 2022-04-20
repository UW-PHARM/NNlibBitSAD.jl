for f in (:output_size,
          :channels_in,
          :channels_out,
          :channel_multiplier)
    @eval @nosim NNlib.$(f)(cdims::NNlib.ConvDims)
end

@nosim NNlib.DenseConvDims(x::AbstractArray{<:SBitstream}, w::AbstractArray{<:SBitstream}) kwargs=true
@nosim NNlib.DenseConvDims(cdims::ConvDims)
@nosim NNlib.PoolDims(x::AbstractArray{<:SBitstream}, k) kwargs=true
