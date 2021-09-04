function im2col(x, cdims)
    cdims_expanded = NNlib.insert_singleton_spatial_dimension(cdims)
    x_expanded = NNlib.insert_singleton_spatial_dimension(x)
    y = similar(x_expanded, NNlib.im2col_dims(cdims_expanded)[1:2])
    NNlib.im2col!(y, x_expanded[:, :, :, :, 1], cdims_expanded)

    return y
end

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
