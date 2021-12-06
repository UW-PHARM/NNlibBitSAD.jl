struct KernelPatch{T, S}
    kernel::T
    patch_indices::S
end
(op::KernelPatch)(x::AbstractArray{<:SBit}) = op.kernel(x[op.patch_indices...]...)

function patches(xsize::NTuple{4, Int}, ksize::NTuple{2, Int}; padding, stride)
    xh, xw, xd, _ = xsize
    ph, pw, _, _ = padding
    sh, sw = stride

    patch_indices = NTuple{3, Vector{Int}}[]
    for d in 1:xd
        for w in (1 - pw):sw:(xw + pw)
            for h in (1 - ph):sh:(xh + ph)
                idx = (filter(i -> i >= 1 && i <= xh, h:(h + ksize[1])),
                       filter(i -> i >= 1 && i <= xw, w:(w + ksize[1])),
                       d:d)
                push!(patch_indices, idx)
            end
        end
    end

    return patch_indices
end
patches(x::AbstractArray, pdims::PoolDims) =
    patches(size(x), NNlib.kernel_size(pdims); padding = NNlib.padding(pdims), stride = NNlib.stride(pdims))
