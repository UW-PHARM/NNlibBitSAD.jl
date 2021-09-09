Base.zero(::Type{BitSAD.SBit}) = BitSAD.SBit((false, false))
Base.one(::Type{BitSAD.SBit}) = BitSAD.SBit((true, false))
BitSAD.SBit(value::Number) = isone(value) ? one(BitSAD.SBit) :
              iszero(value) ? zero(BitSAD.SBit) :
              error("Cannot create an SBit($value). Use pop!(SBitstream($value)) instead.")
Base.:(==)(x::SBitstream, y::SBitstream) = float(x) == float(y)
Base.:(/)(x::SBitstream, y::Int) = x÷y

function NNlib.meanpool(x::AbstractArray{xT,N},
                        pdims::PoolDims; kwargs...) where {xT<:SBitstream, N}
     y = similar(x, NNlib.output_size(pdims)..., NNlib.channels_out(pdims), size(x, N))
     fill!(y, xT(0))
     return NNlib.meanpool!(y, x, pdims; kwargs...)
end

BitSAD.is_trace_primitive(::Type{typeof(NNlib.meanpool)}, 
                          ::Type{<:AbstractArray{<:SBitstream,N}}, 
                          pdims) where {N} = true
BitSAD.getsimulator(::Type{typeof(NNlib.meanpool)}, 
                    ::Type{<:AbstractArray{<:SBitstream,N}}, 
                    pdims) where {N} = NNlib.meanpool
