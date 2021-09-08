for f in (:output_size, :channels_in, :channels_out, :channel_multiplier)
    @eval begin
        BitSAD.is_trace_primitive(::Type{<:Tuple{typeof(NNlib.$f), C}}) where C = true
        BitSAD.getsimulator(::typeof(NNlib.$f), cdims) = NNlib.$f
    end
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

# NNlib.conv(x::AbstractArray{<:SBitstream, 3}, w::AbstractArray{<:SBitstream, 4}, cdims::ConvDims) =
#     NNlib.conv(reshape(x, size(x)..., 1), w, cdims)

function NNlib.conv(x::AbstractArray{<:SBitstream, 4},
                    w::AbstractArray{<:SBitstream, 4},
                    cdims::ConvDims)
    xgemm = im2col(x, cdims)
    wgemm = reshape(w, :, size(w, 4))
    ygemm = xgemm * wgemm
    y = reshape(ygemm, NNlib.output_size(cdims)..., NNlib.channels_out(cdims), size(x, 4))

    return y
end

function NNlib.depthwiseconv(x::AbstractArray{<:SBitstream, 4},
                             w::AbstractArray{<:SBitstream, 4},
                             cdims::ConvDims)
    N = NNlib.channels_in(cdims)
    K = NNlib.channel_multiplier(cdims)
    M = prod(NNlib.output_size(cdims))
    x_col = im2col(x, cdims)
    xgemm = reshape(x_col, M, :, N)
    wgemm = reshape(w, :, K, N)
    ygemms = map(*, eachslice(xgemm, dims=3), eachslice(wgemm, dims=3))
    ygemm = cat(ygemms...; dims = 3)
    y = reshape(ygemm, NNlib.output_size(cdims)..., N*K, size(x, 4))
    return y
end


