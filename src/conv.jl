# NNlib.conv(x::AbstractArray{<:SBitstream, 3}, w::AbstractArray{<:SBitstream, 4}, cdims::ConvDims) =
#     NNlib.conv(reshape(x, size(x)..., 1), w, cdims)

# groups == 1 conv
function _conv(x, w, cdims)
    xgemm = im2col(x, cdims)
    wgemm = reshape(w, :, size(w, 4))
    ygemm = xgemm * wgemm
    osize = NNlib.output_size(cdims)
    y = reshape(ygemm, osize[1], osize[2], NNlib.channels_out(cdims), size(x, 4))

    return y
end

function NNlib.conv(x::AbstractArray{<:SBitstream, 4},
                    w::AbstractArray{<:SBitstream, 4},
                    cdims::C) where {C<:ConvDims}
    C_in = NNlib.channels_in(cdims) ÷ NNlib.groupcount(cdims)
    C_out = NNlib.channels_out(cdims) ÷ NNlib.groupcount(cdims)
    _cdims = NNlib.basetype(C)(cdims, G = 1, C_in = C_in, C_out = C_out)

    x_cs = Iterators.partition(1:size(x, 3), C_in)
    w_cs = Iterators.partition(1:size(w, 4), C_out)

    y = zeros(eltype(x), NNlib.output_size(cdims)..., NNlib.channels_out(cdims), size(x, 4))
    for (xc, wc) in zip(x_cs, w_cs)
        x_i = @view x[ntuple(i -> i == 3 ? xc : Colon(), 4)...]
        w_i = @view w[ntuple(i -> i == 4 ? wc : Colon(), 4)...]
        y[ntuple(i -> i == 3 ? wc : Colon(), 4)...] = _conv(x_i, w_i, _cdims)
    end

    return y
end

# function NNlib.depthwiseconv(x::AbstractArray{<:SBitstream, 4},
#                              w::AbstractArray{<:SBitstream, 4},
#                              cdims::ConvDims)
#     N = NNlib.channels_in(cdims)
#     K = NNlib.channel_multiplier(cdims)
#     M = prod(NNlib.output_size(cdims))
#     x_col = im2col(x, cdims)
#     xgemm = reshape(x_col, M, :, N)
#     wgemm = reshape(w, :, K, N)
#     ygemms = map(*, eachslice(xgemm, dims=3), eachslice(wgemm, dims=3))
#     ygemm = cat(ygemms...; dims = 3)
#     y = reshape(ygemm, NNlib.output_size(cdims)..., N*K, size(x, 4))
#     return y
# end
