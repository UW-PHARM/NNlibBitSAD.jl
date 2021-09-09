module NNlibBitSAD

using BitSAD
using NNlib

export conv

include("conv.jl")
include("pooling.jl")
end # module
