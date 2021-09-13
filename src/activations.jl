NNlib.relu(x::SBitstream) = SBitstream(NNlib.relu(float(x)))

struct SReluer end
(op::SReluer)(x::SBit) = SBit(pos = pos(x), neg = false)

BitSAD.is_trace_primitive(::Type{typeof(NNlib.relu)}, ::Type{<:SBitstream}) = true
BitSAD.getsimulator(::typeof(NNlib.relu), ::SBitstream) = SReluer()
