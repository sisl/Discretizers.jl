
type DiscretizeKnuth <: DiscretizationAlgorithm end

"""
Return the optimal histogram bin width using Knuth's rule.

Knuth's rule is a fixed-width, Bayesian approach to determining
the optimal bin width of a histogram.

Notes
-----
The optimal number of bins is the value M which maximizes the function

    F(M|x,I) = n\log(M) + \log\Gamma(\frac{M}{2})
    - M\log\Gamma(\frac{1}{2})
    - \log\Gamma(\frac{2n+M}{2})
    + \sum_{k=1}^M \log\Gamma(n_k + \frac{1}{2})

where `\Gamma` is the Gamma function,
      `n` is the number of data points,
      `n_k` is the number of measurements in bin `k`.

See: Knuth, K.H. "Optimal Data-Based Binning for Histograms" arXiv:0605197, 2006
Adapted from: http://docs.astropy.org/en/stable/_modules/astropy/stats/histogram.html
"""
function binedges{N<:Real}(alg::DiscretizeKnuth, data::AbstractArray{N})

    sort!(data)
    binedges0 = binedges(DiscretizeFreedman(), data)
    
    M = optimize.fmin(knuthF, len(bins0), disp=not quiet)[0]
    # bins = knuthF.bins(M)
    # dx = bins[1] - bins[0]

    # if return_bins:
    #     return dx, bins
    # else:
    #     return dx
end

"""
    _knuth_eval{N<:Real}(nbins::Int, data::AbstractArray{N})
The Knuth function that is to be minimized

This assumes data is sorted
"""
function _knuth_eval{N<:Real}(nbins::Int, data::AbstractArray{N})

    if nbins ≤ 0
        Inf
    end

    disc = LinearDiscretizer(linspace(data[1], data[end], nbins+1))
    counts = zeros(Float64, nbins)
    for v in data
        counts[encode(disc, v)] += 1.0
    end

    n = length(data)

    retval = n * log(nbins) + lgamma(nbins/2) - nbins * lgamma(0.5) - lgamma(n + nbins/2)
    for count in counts
        retval += lgamma(count .+ 0.5)
    end
    
    return -retval
end