
type DiscretizeUniformWidth <: DiscretizationAlgorithm 
    nbins :: Int
end

function binedges{N<:FloatingPoint}(alg::DiscretizeUniformWidth, data::AbstractArray{N})
    lo, hi = extrema(data)
    @assert(hi > lo)
    convert(Vector{N}, linspace(lo, hi, alg.nbins+1))
end
function binedges{N<:Integer}(alg::DiscretizeUniformWidth, data::AbstractArray{N})
    lo, hi = extrema(data)
    @assert(hi > lo)
    linspace(lo, hi, alg.nbins+1)::Vector{Float64}
end