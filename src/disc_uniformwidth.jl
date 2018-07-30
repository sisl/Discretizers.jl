"""
   DiscretizeUniformWidth(alg::Symbol)
If `nbins` is a symbol, automatically determine the number of bins to use
"""
struct DiscretizeUniformWidth <: DiscretizationAlgorithm
    nbins::Union{Int,Symbol}
end

function get_nbins(alg::Symbol, data::AbstractArray{N}) where {N<:Real}

    n = length(data)

    if alg == :sqrt
        # Square root (of data size) estimator, used by Excel and other programs for its speed and simplicity.
        nbins = ceil(Int, sqrt(n))
    elseif alg == :sturges
        # R’s default method, only accounts for data size.
        # Only optimal for gaussian data and underestimates number of bins for large non-gaussian datasets.
        # It implicitly bases the bin sizes on the range of the data and can perform poorly if n < 30,
        # because the number of bins will be small—less than seven—and unlikely to show trends in the data well.
        # It may also perform poorly if the data are not normally distributed.
        nbins = ceil(Int, log(2,n)) + 1
    elseif alg == :rice
        # Estimator does not take variability into account, only data size. Commonly overestimates number of bins required.
        nbins = ceil(Int, 2cbrt(n))
    elseif alg == :doane
        # An improved version of Sturges’ estimator that works better with non-normal datasets.
        g₁ = moment(data, 3)
        σ = sqrt((6*(n-2))/((n+1)*(n+3)))
        nbins = ceil(Int, 1 + log(2,n) + log(2, 1+abs(g₁)/σ))
    elseif alg == :scott
        # Less robust estimator that that takes into account data variability and data size.
        σ = std(data)
        binwidth = 3.5σ/cbrt(n)
        lo, hi = extrema(data)
        nbins = ceil(Int, (hi - lo)/binwidth)
    elseif alg == :fd # Freedman Diaconis Estimator
        # Robust (resilient to outliers) estimator that takes into account data variability and data size
        binwidth = 2iqr(data)/cbrt(n)
        lo, hi = extrema(data)
        nbins = ceil(Int, (hi - lo)/binwidth)
    else # alg == :auto
        # Maximum of the ‘sturges’ and ‘fd’ estimators. Provides good all round performance

        binwidth = 2iqr(data)/cbrt(n)
        lo, hi = extrema(data)
        nbins_fd = ceil(Int, (hi - lo)/binwidth)
        nbins_sturges = ceil(Int, log(2,n)) + 1
        nbins = max(nbins_fd, nbins_sturges)
    end

    nbins
end

function binedges(alg::DiscretizeUniformWidth, data::AbstractArray{N}) where {N<:AbstractFloat}
    lo, hi = extrema(data)
    @assert(hi > lo)

    nbins = (isa(alg.nbins, Symbol) ? get_nbins(alg.nbins, data) : alg.nbins)::Int

    convert(Vector{N}, collect(range(lo, stop=hi, length=nbins+1)))
end
function binedges(alg::DiscretizeUniformWidth, data::AbstractArray{N}) where {N<:Integer}
    lo, hi = extrema(data)
    @assert(hi > lo)
    collect(range(lo, stop=hi, length=alg.nbins+1))
end