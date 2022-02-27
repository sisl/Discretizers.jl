struct DiscretizeQuantile <: DiscretizationAlgorithm
    nbins::Int
    trim::Bool # Whether to automatically remove extremely narrow bins caused by duplicate entries
end

# Set trim to false by default
DiscretizeQuantile(nbins::Int) = DiscretizeQuantile(nbins, false)

function binedges(alg::DiscretizeQuantile, data::AbstractArray{N}) where {N<:Union{Int, AbstractFloat }}
    nbins = alg.nbins

    n = length(data)
    n ≥ nbins || error("too many bins requested")

    qs = range(0, 1; length=(nbins+1))
    retval = quantile(data, qs)

    # trim bins that are too small, caused by duplicate entiries
    keep_bin = diff(retval) .> 1e-8

    if alg.trim # trim bins that are too small
        # Ref: https://github.com/scikit-learn/scikit-learn/blob/main/sklearn/preprocessing/_discretization.py#L288
        # Always keep the first bin edge
        insert!(keep_bin, 1, true)
        retval = retval[keep_bin] # NOTE: this reduces our bin count
        length(retval) > 1 || error("no bins remaining")
    else
        # As with other methods, throw an error if there are non-unique bin edges
        !all(keep_bin) && error("binedges non-unique")
    end

    retval
end
