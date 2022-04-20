struct MaxPooler{T<:KernelPatch}
    kernels::Vector{T}
end
function MaxPooler(x::AbstractArray{<:SBitstream, 4}, pdims::PoolDims)
    patch_indices = patches(x, pdims)
    kernels = [KernelPatch(BitSAD.SSignedNMaxer(length(x[idx...])), idx)
               for idx in patch_indices if length(x[idx...]) > 0]

    MaxPooler(kernels)
end

function (op::MaxPooler)(x::AbstractArray{<:SBit, 4}, osize)
    y = similar(x, osize)
    for i in eachindex(y)
        y[i] = op.kernels[i](x)
    end

    return y
end
(op::MaxPooler)(x::AbstractArray{<:SBit, 4}, pdims::PoolDims) =
    op(x, (NNlib.output_size(pdims)..., size(x)[3:end]...))

BitSAD.is_trace_primitive(::Type{typeof(NNlib.maxpool)},
                          ::Type{<:AbstractArray{<:SBitstream}},
                          ::Type{<:NNlib.PoolDims}) = true
BitSAD.getsimulator(::typeof(NNlib.maxpool), x::AbstractArray{<:SBitstream}, pdims::NNlib.PoolDims) =
    MaxPooler(x, pdims)

struct SMaxPoolHandler end

BitSAD.gethandler(broadcasted,
                  ::Type{typeof(NNlib.maxpool)},
                  ::Type{<:AbstractArray{<:SBitstream}},
                  ::Type{<:NNlib.PoolDims}) =
    broadcasted ? error("Cannot generate hardware for broadcasted maxpool.") : SMaxPoolHandler()
BitSAD.init_state(::SMaxPoolHandler) = (id = 0,)

function (handler::SMaxPoolHandler)(buffer, netlist, state, inputs, outputs)
    # delete pdims from netlist
    delete!(netlist, inputs[2])

    # extract parameters
    pdims = BitSAD.value(inputs[2])
    IM_H, IM_W = BitSAD.netsize(inputs[1])[1:2]
    CHANNELS = NNlib.channels_in(pdims)
    PAD_H, PAD_W = NNlib.padding(pdims)
    STRIDE_H, STRIDE_W = NNlib.stride(pdims)
    KERNEL_H, KERNEL_W = NNlib.kernel_size(pdims)

    write(buffer, """
        // BEGIN maxpool$(state.id)
        stoch_signed_maxpool #(
                .IM_HEIGHT($IM_H),
                .IM_WIDTH($IM_W),
                .CHANNELS($CHANNELS),
                .KERNEL_H($KERNEL_H),
                .KERNEL_W($KERNEL_W),
                .PAD_H($PAD_H),
                .PAD_W($PAD_W),
                .STRIDE_H($STRIDE_H),
                .STRIDE_W($STRIDE_W)
            ) maxpool$(state.id) (
                .CLK(CLK),
                .nRST(nRST),
                .x_p($(BitSAD.name(inputs[1]))_p),
                .x_m($(BitSAD.name(inputs[1]))_m),
                .y_p($(BitSAD.name(outputs[1]))_p),
                .y_m($(BitSAD.name(outputs[1]))_m)
            );
        // END maxpool$(state.id)
        \n""")

    return buffer, (id = state.id + 1,)
end
