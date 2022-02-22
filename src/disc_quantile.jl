using Statistics: quantile

struct DiscretizeQuantile <: DiscretizationAlgorithm
    nbins::Int
    trim::Bool
end

# Set trim to false by default
DiscretizeQuantile(nbins::Int) = DiscretizeQuantile(nbins, false)

function binedges(alg::DiscretizeQuantile, data::AbstractArray{N}) where {N<:Union{Int, AbstractFloat }}
    nbins = alg.nbins

    n = length(data)
    n ≥ nbins || error("too many bins requested")

    qs = range(0, 1; length=(nbins+1))
    retval = quantile.(Ref(data), qs)

    isunique = diff(retval) .> 1e-8

    if alg.trim # trim bins that are too small
        # Ref: https://github.com/scikit-learn/scikit-learn/blob/main/sklearn/preprocessing/_discretization.py#L288
        mask = vcat([true], isunique)
        retval = retval[mask] # note this makes length(retval) < nbins
    else
        # Throw error as in other methods if there are non-unique bin egdes
        any(.!(isunique)) && error("binedges non-unique")
    end

    retval
end
