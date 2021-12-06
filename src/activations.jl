NNlib.relu(x::SBitstream) = SBitstream(NNlib.relu(float(x)))

struct SReluer end
(op::SReluer)(x::SBit) = SBit((pos(x), false))

BitSAD.is_trace_primitive(::Type{typeof(NNlib.relu)}, ::Type{<:SBitstream}) = true
BitSAD.is_trace_primitive(::Type{typeof(Base.broadcasted)},
                          ::Type{typeof(NNlib.relu)},
                          ::Type{<:SBitstreamLike}) = true
BitSAD.getsimulator(::typeof(NNlib.relu), ::SBitstream) = SReluer()

Base.@kwdef mutable struct ReluHandler
    id::Int = 0
    broadcasted::Bool
end

BitSAD.gethandler(broadcasted, ::Type{typeof(NNlib.relu)}, ::Type{<:SBitstreamLike}) =
    ReluHandler(broadcasted = broadcasted)

function (handler::ReluHandler)(buffer, netlist, inputs, outputs)
    # set input/output at as signed
    BitSAD.setsigned!(netlist, inputs[1], true)
    BitSAD.setsigned!(netlist, outputs[1], true)

    num_elements = join(BitSAD.netsize(inputs[1]), "*")

    broadcast = handler.broadcasted ? "_bcast" : ""
    write(buffer, """
        $(BitSAD.stdcomment)
        // BEGIN relu$(broadcast)$(handler.id)
        genvar relu$(broadcast)$(handler.id)_i;

        generate
        for (relu$(broadcast)$(handler.id)_i = 0; relu$(broadcast)$(handler.id)_i < $num_elements; relu$(broadcast)$(handler.id)_i = relu$(broadcast)$(handler.id)_i + 1) begin : relu$(broadcast)$(handler.id)_gen
            stoch_signed_relu relu$(broadcast)$(handler.id) (
                    .CLK(CLK),
                    .nRST(nRST),
                    .in_p($(BitSAD.name(inputs[1]))_p[relu$(broadcast)$(handler.id)_i]),
                    .in_m($(BitSAD.name(inputs[1]))_m[relu$(broadcast)$(handler.id)_i]),
                    .out_p($(BitSAD.name(outputs[1]))_p[relu$(broadcast)$(handler.id)_i]),
                    .out_m($(BitSAD.name(outputs[1]))_m[relu$(broadcast)$(handler.id)_i])
                );
        end
        endgenerate
        // END relu$(broadcast)$(handler.id)
        \n""")

    handler.id += 1

    return buffer
end
