
type DiscretizeUniformCount <: DiscretizationAlgorithm 
    nbins :: Int
end

function binedges{N<:FloatingPoint}(alg::DiscretizeUniformCount, data::AbstractArray{N})
    
    nbins = alg.nbins

    n = length(data)
    n >= nbins || error("too many bins requested")

    p = sortperm(data)
    counts_per_bin, remainder = div(n,nbins), rem(n,nbins)
    retval = Array(Float64, nbins+1)
    retval[1] = data[p[1]]
    retval[end] = data[p[end]]

    ind = 0
    for i = 2 : nbins
        counts = counts_per_bin + (remainder > 0.0 ? 1 : 0)
        remainder -= 1.0
        ind += counts
        retval[i] = (data[p[ind]] + data[p[ind+1]])/2
        retval[i-1] != retval[i] || error("binedges non-unique") # TODO(tim): should make the algorithm handle this
    end

    retval
end
