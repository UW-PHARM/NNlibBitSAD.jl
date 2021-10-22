using BitSAD
using NNlib
using NNlibBitSAD
using Statistics: mean
using Flux
using Functors
using Ghost

##

x = SBitstream.(rand(32, 32, 3, 1) / 100)
w = SBitstream.(rand(3, 3, 3, 16) / 100)
cdims = DenseConvDims(x, w)

##

NNlibBitSAD.im2col(x, cdims)

##

yfloat = conv(float.(x), float.(w), cdims)
y = conv(x, w, cdims)
mean(abs.(float.(y) .- yfloat))

##

sim = simulatable(conv, x, w, cdims)
for t in 1:100
    ybit = pop!.(sim(conv, x, w, cdims))
    push!.(y, ybit)
end
mean(abs.(estimate.(y) .- yfloat)) / maximum(yfloat)

##

function two_conv(x, w)
    y = conv(x, w; pad = 1)
    return conv(y, w)
end

w = SBitstream.(rand(3, 3, 3, 3) / 100)
yfloat = two_conv(float.(x), float.(w))
y = two_conv(x, w)

sim = simulatable(two_conv, x, w)
for t in 1:100
    ybit = pop!.(sim(two_conv, x, w))
    push!.(y, ybit)
end
mean(abs.(estimate.(y) .- yfloat)) / maximum(yfloat)

##

clayers = [Conv((3, 3), 3 => 16, relu),
           Conv((3, 3), 16 => 64, relu),
           Conv((3, 3), 64 => 128, relu)]
csize = prod(Flux.outputsize(clayers, size(x)))
nn = clayers[1]
# nn = Chain(clayers..., Flux.flatten, Dense(csize, 10))

##

nn = fmap(x -> SBitstream.(x), nn; exclude = x -> x isa AbstractArray)
BitSAD.show_simulatable(nn, x)

##

tape = BitSAD.trace(nn, x; isprimitive = BitSAD.is_hardware_primitive)
BitSAD.transform!(BitSAD._unbroadcast, tape)
BitSAD.transform!(BitSAD._squash_binary_vararg, tape)
tape = Ghost.Tape(tape.ops, tape.result, tape.parent, tape.meta, BitSAD.TupleCtx())
BitSAD.transform!(BitSAD._record_tuples_and_splats, tape)
BitSAD.transform!(BitSAD._reroute_tuple_index, tape)
BitSAD.transform!(BitSAD._desplat, tape)

# extract tape into module
m = BitSAD.Module(fn = nn, name = :top)
BitSAD.extracttrace!(m, tape)

##

outfile = open("top.v", "w")
_, m = generatehw(outfile, nn, x);
close(outfile)
