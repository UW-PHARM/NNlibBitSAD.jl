module NNlibBitSAD

using BitSAD
using BitSAD: @nosim, SBitstreamLike, Net, Netlist
using NNlib
using Functors: fmap

export tosbitstream

include("helpers.jl")
include("utils.jl")
include("activations.jl")
include("conv.jl")
include("pooling.jl")
include("upsampling.jl")

tosbitstream(f) = fmap(x -> SBitstream.(x), f; exclude = x -> x isa AbstractArray)

end # module
