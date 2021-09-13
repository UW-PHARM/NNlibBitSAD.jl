# NNlib.conv(x::AbstractArray{<:SBitstream, 3}, w::AbstractArray{<:SBitstream, 4}, cdims::ConvDims) =
#     NNlib.conv(reshape(x, size(x)..., 1), w, cdims)

function NNlib.conv(x::AbstractArray{<:SBitstream, 4},
                    w::AbstractArray{<:SBitstream, 4},
                    cdims::ConvDims)
    xgemm = im2col(x, cdims)
    wgemm = reshape(w, :, size(w, 4))
    ygemm = xgemm * wgemm
    osize = NNlib.output_size(cdims)
    y = reshape(ygemm, osize[1], osize[2], NNlib.channels_out(cdims), size(x, 4))

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
