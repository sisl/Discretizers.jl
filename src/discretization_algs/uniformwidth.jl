
type DiscretizeUniformWidth <: DiscretizationAlgorithm
    nbins :: Int
end

function binedges{N<:AbstractFloat}(alg::DiscretizeUniformWidth, data::AbstractArray{N})
    lo, hi = extrema(data)
    @assert(hi > lo)
    convert(Vector{N}, collect(linspace(lo, hi, alg.nbins+1)))
end
function binedges{N<:Integer}(alg::DiscretizeUniformWidth, data::AbstractArray{N})
    lo, hi = extrema(data)
    @assert(hi > lo)
    collect(linspace(lo, hi, alg.nbins+1))
end