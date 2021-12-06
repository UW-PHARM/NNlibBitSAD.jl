BitSAD.is_trace_primitive(::Type{typeof(NNlib.upsample_nearest)},
                          ::Type{<:AbstractArray{<:SBitstream}},
                          ::Type{<:Any}) = true
BitSAD.getsimulator(::typeof(NNlib.upsample_nearest), x, scale) = NNlib.upsample_nearest

struct SUpsampleNearestHandler end

BitSAD.gethandler(broadcasted,
                  ::Type{typeof(NNlib.upsample_nearest)},
                  ::Type{<:AbstractArray{<:SBitstream}},
                  ::Type{<:NTuple{<:Any, <:Integer}}) =
    !broadcasted ? SUpsampleNearestHandler() : error("Cannot generate hardware for broadcasted upsample_nearest.")
BitSAD.init_state(::SUpsampleNearestHandler) = (id = 0,)

function (handler::SUpsampleNearestHandler)(buffer, netlist, state, inputs, outputs)
    # set input/output at as signed and delete cdims from netlist
    BitSAD.setsigned!(netlist, inputs[1], true)
    BitSAD.setsigned!(netlist, outputs[1], true)
    delete!(netlist, inputs[2])

    # extract scaling and dimensions
    scaling = reverse(BitSAD.value(inputs[2]))
    sizes = reverse(BitSAD.netsize(outputs[1]))
    @assert length(scaling) <= length(sizes) """
        Dimension mismatch in UpsampleNearestHandler:
            - scaling is $scaling
            - output array size is $sizes
        Expected: length(scaling) <= length(sizes)
        """
    scaling = (ntuple(i -> "1", length(sizes) - length(scaling))..., scaling...)

    # loop from outer most dimension inward
    # divide output index by scale to get matched input index
    write(buffer, "// BEGIN upsample_nearest$(state.id)\n")
    write(buffer, "genvar ")
    write(buffer, join(ntuple(i -> "upsample_nearest_idx_$i", length(sizes)), ", "))
    write(buffer, ";\ngenerate\n")
    for (i, (scale, sz)) in enumerate(zip(scaling, sizes))
        padding = repeat(" ", (i - 1) * 4)
        write(buffer, """
            $(padding)for (upsample_nearest_idx_$i = 0; upsample_nearest_idx_$i < $sz; upsample_nearest_idx_$i = upsample_nearest_idx_$i + 1) begin : upsample_nearest_dim_$i
            $(padding)    localparam input_idx_$i = upsample_nearest_idx_$i / $scale;
            """)
    end
    padding = repeat(" ", length(sizes) * 4)
    # compute linear output index
    write(buffer, padding * "localparam out_i = ")
    for (i, sz) in enumerate(sizes[1:(end - 1)])
        write(buffer, "$sz * upsample_nearest_idx_$i + ")
    end
    write(buffer, "upsample_nearest_idx_$(length(sizes));\n")
    # compute linear input index
    write(buffer, padding * "localparam in_i = ")
    for (i, sz) in enumerate(reverse(BitSAD.netsize(inputs[1]))[1:(end - 1)])
        write(buffer, "$sz * input_idx_$i + ")
    end
    write(buffer, "input_idx_$(length(sizes));\n")
    # assign output
    write(buffer, padding * "assign $(BitSAD.name(outputs[1]))[out_i] = $(BitSAD.name(inputs[1]))[in_i];\n")
    for i in length(sizes):-1:1
        padding = repeat(" ", (i - 1) * 4)
        write(buffer, "$(padding)end\n")
    end
    write(buffer, "endgenerate\n//END upsample_nearest$(state.id)\n\n")

    return buffer, (id = state.id + 1,)
end
