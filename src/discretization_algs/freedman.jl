
type DiscretizeFreedman <: DiscretizationAlgorithm end

"""
Return the optimal histogram bin width using the Freedman-Diaconis rule

The Freedman-Diaconis rule is a normal reference rule like Scott's
rule, but uses rank-based statistics for results which are more robust
to deviations from a normal distribution.

Notes
-----
The optimal bin width is

    \Delta_b = \frac{2(q_{75} - q_{25})}{n^{1/3}}

where `q_{N}` is the `N` percent quartile of the data, and
`n` is the number of data points.

References
----------
See: D. Freedman & P. Diaconis (1981)
   "On the histogram as a density estimator: L2 theory".
   Probability Theory and Related Fields 57 (4): 453-476
Adapted from: http://docs.astropy.org/en/stable/_modules/astropy/stats/histogram.html
"""
function binedges{N<:Real}(alg::DiscretizeFreedman, data::AbstractArray{N})

    n = length(data)
    n > 3 || error("data should have more than three entries")

    percentile_arr = percentile(data, [25, 75])
    v25, v75 = percentile_arr[1], percentile_arr[2]

    binwidth = 2 * (v75 - v25) / cbrt(n)

    lo, hi = extrema(data)
    midpt = (lo + hi)/2
    nbins = max(1, ceil(Int, (hi - lo)/binwidth))

    collect(linspace(midpt - nbins*binwidth/2, midpt + nbins*binwidth/2, nbins+1))
end