module NNlibBitSAD

using BitSAD
using BitSAD: SBitstreamLike, Net, Netlist
using NNlib

include("utils.jl")
include("activations.jl")
include("conv.jl")
include("pooling.jl")

end # module
