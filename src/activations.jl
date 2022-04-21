NNlib.relu(x::SBitstream) = SBitstream(NNlib.relu(float(x)))

struct SReluer end
function (op::SReluer)(x::SBit)
    z = pos(x) && !neg(x)

    return SBit((z, false))
end

BitSAD.is_trace_primitive(::Type{typeof(NNlib.relu)}, ::Type{<:SBitstream}) = true
BitSAD.is_trace_primitive(::Type{typeof(Base.broadcasted)},
                          ::Type{typeof(NNlib.relu)},
                          ::Type{<:SBitstreamLike}) = true
BitSAD.getsimulator(::typeof(NNlib.relu), ::SBitstream) = SReluer()
BitSAD.getsimulator(::typeof(Base.broadcasted),
                    ::typeof(NNlib.relu),
                    x::SBitstreamLike) = BitSAD.getsimulator.(relu, x)

struct SReluHandler end

BitSAD.gethandler(::Bool, ::Type{typeof(NNlib.relu)}, ::Type{<:SBitstreamLike}) = SReluHandler()
BitSAD.init_state(::SReluHandler) = (id = 0,)

function (handler::SReluHandler)(buffer, netlist, state, inputs, outputs)
    num_elements = join(BitSAD.netsize(inputs[1]), "*")
    write(buffer, """
        // BEGIN relu$(state.id)
        """)
    BitSAD.write_bcast_instantiation(buffer, "relu$(state.id)", BitSAD.netsize(outputs[1]), """
        stoch_signed_relu relu$(state.id) (
                .CLK(CLK),
                .nRST(nRST),
                .in_p($(BitSAD.name(inputs[1]))_p[relu$(state.id)_i]),
                .in_m($(BitSAD.name(inputs[1]))_m[relu$(state.id)_i]),
                .out_p($(BitSAD.name(outputs[1]))_p[relu$(state.id)_i]),
                .out_m($(BitSAD.name(outputs[1]))_m[relu$(state.id)_i])
            );""")
    write(buffer, """
        // END relu$(state.id)
        \n""")

    return buffer, (id = state.id + 1,)
end
