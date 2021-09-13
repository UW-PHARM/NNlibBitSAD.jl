NNlib.relu(x::SBitstream) = SBitstream(NNlib.relu(float(x)))

struct SReluer end
(op::SReluer)(x::SBit) = SBit((pos(x), false))

BitSAD.is_trace_primitive(::Type{typeof(NNlib.relu)}, ::Type{<:SBitstream}) = true
BitSAD.is_trace_primitive(::Type{typeof(Base.broadcasted)},
                          ::Type{typeof(NNlib.relu)},
                          ::Type{<:SBitstreamLike}) = true
BitSAD.getsimulator(::typeof(NNlib.relu), ::SBitstream) = SReluer()

Base.@kwdef mutable struct ReluHandler
    id = 0
end

BitSAD.gethandler(::Bool, ::Type{typeof(NNlib.relu)}, ::Type{<:SBitstreamLike}) = ReluHandler()

function (handler::ReluHandler)(netlist::Netlist, inputs::Netlist, outputs::Netlist)
    # set input/output at as signed
    BitSAD.setsigned!(netlist, inputs[1], true)
    BitSAD.setsigned!(netlist, outputs[1], true)

    num_elements = prod(BitSAD.netsize(inputs[1]))

    outstring = """
        $(BitSAD.stdcomment)
        // BEGIN relu$(handler.id)
        integer relu$(handler.id)_i;

        for (relu$(handler.id)_i = 0; i < $num_elements; i = i + 1) begin
            relu relu$(handler.id) (
                    .CLK(CLK),
                    .nRST(nRST),
                    .in_p($(BitSAD.name(inputs[1]))_p[relu$(handler.id)_i]),
                    .in_m($(BitSAD.name(inputs[1]))_m[relu$(handler.id)_i]),
                    .out_p($(BitSAD.name(outputs[1]))_p[relu$(handler.id)_i]),
                    .out_m($(BitSAD.name(outputs[1]))_m[relu$(handler.id)_i])
                );
        end
        // END relu$(handler.id)
        \n"""

    handler.id += 1

    return outstring
end
