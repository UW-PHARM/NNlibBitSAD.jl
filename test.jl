using BitSAD
using NNlib
using NNlibBitSAD
using Statistics: mean

##

x = SBitstream.(rand(32, 32, 3, 1) / 10)
w = SBitstream.(rand(3, 3, 3, 16) / 10)
cdims = DenseConvDims(x, w)

##

yfloat = conv(float.(x), float.(w), cdims)
y = conv(x, w, cdims)
mean(abs.(float.(y) .- yfloat))

##

sim = simulatable(conv, x, w, cdims)
for t in 1:1000
    ybit = pop!.(sim(conv, x, w, cdims))
    push!.(y, ybit)
end
mean(abs.(estimate.(y) .- yfloat))
