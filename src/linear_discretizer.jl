

const DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST = true

"""
    LinearDiscretizer

A discretizer which encodes (typically) continuous values into discrete bins.
A univariate domain is divided into discrete by edges.
A value V will be encoded into bin B if V ∈ [Bₗ Bᵣ)
(or V ∈ [Bₗ Bᵣ] if B is the rightmost bin)

If force_outliers_to_closest is set to true, then values outside of binedges will be
shunted into the nearest bin. Otherwise an error is thrown.

TODO(tim):
    handle NA
    handle Nullable
    handle NaN
    ability to specify decoding behavior
"""
struct LinearDiscretizer{N<:Real, D<:Integer} <: AbstractDiscretizer{N,D}
    binedges :: Vector{N}   # list of bin edges, sorted smallest to largest
    nbins    :: Int
    i2d      :: Dict{Int,D} # maps bin index to discrete label
    d2i      :: Dict{D,Int} # maps discrete label to bin index

    force_outliers_to_closest :: Bool # if true, real values outside of the bin ranges will be forced to the nearest bin, otherwise will throw an error
end

function LinearDiscretizer{N<:Real, D<:Integer}( binedges::Vector{N}, i2d::Dict{Int,D};
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST )

    length(binedges) > 1 || error("bin edges must contain at least 2 values")

    if N <: AbstractFloat # continuous values
        findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)) == 0 ||
            error("Bin edges must be sorted in increasing order")
    else # for integers, bins of unit width require repeated values
        (findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)-1) == 0 &&
         findfirst(i->binedges[i-1] > binedges[i], 2:length(binedges)) == 0 ) ||
            error("Bin edges must be sorted in increasing order")
    end

    all(haskey(i2d, i) for i in 1 : length(binedges)-1) || error("i2d must contain all necessary keys")

    d2i = Dict{D,Int}(v => k for (k,v) in i2d)

    return LinearDiscretizer{N,D}(binedges, length(binedges)-1, i2d, d2i, force_outliers_to_closest)
end
function LinearDiscretizer{N<:Real, D<:Integer}( binedges::Vector{N}, ::Type{D} = Int;
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST )

    length(binedges) > 1 || error("bin edges must contain at least 2 values")

    if N <: AbstractFloat
        findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)) == 0 ||
            error("Bin edges must be sorted in increasing order")
    else # for integers, bins of unit width require repeated values
        (findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)-1) == 0 &&
         findfirst(i->binedges[i-1] > binedges[i], 2:length(binedges)) == 0 ) ||
            error("Bin edges must be sorted in increasing order")
    end

    i2d = Dict{Int,D}(i => convert(D, i) for i in 1 : length(binedges)-1)

    return LinearDiscretizer(binedges,i2d,force_outliers_to_closest=force_outliers_to_closest)
end
function LinearDiscretizer{N<:Real, D<:Integer}(arr::AbstractVector{N}, ::Type{D}=Int;
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST)
    LinearDiscretizer(convert(Vector{N}, arr), D, force_outliers_to_closest=force_outliers_to_closest)
end

function supports_encoding{N<:Real,D<:Integer}(ld::LinearDiscretizer{N,D}, x::N)
    if ld.force_outliers_to_closest
        return true
    else
        return ld.binedges[1] ≤ x ≤ ld.binedges[end]
    end
end
supports_decoding{N<:Real,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D) = 1 ≤ d ≤ ld.nbins

function encode{N,D<:Integer}(ld::LinearDiscretizer{N,D}, x::N)
    !isnan(x) || error("cannot encode NaN values")

    if x < ld.binedges[1]
        return ld.force_outliers_to_closest ? ld.i2d[1] : throw(BoundsError())
    elseif x > ld.binedges[end]
        return ld.force_outliers_to_closest ? ld.i2d[ld.nbins] : throw(BoundsError())
    else

        # run bisection search
        binedges = ld.binedges
        a, b = 1, length(binedges)
        va, vb = binedges[a], binedges[b]
        while b-a > 1
            c = div(a+b, 2)
            vc = binedges[c]
            if x < vc
                b, vb = c, vc
            else
                a, va = c, vc
            end
        end
        return ld.i2d[a]
    end
end
encode{N,D}(ld::LinearDiscretizer{N,D}, x) = encode(ld, convert(N, x))::D
function encode{N,D<:Integer}(ld::LinearDiscretizer{N,D}, data::AbstractArray)
    arr = [encode(ld, x) for x in data]
    reshape(arr, size(data))
end

"""
There are several methods for decoding a LinearDiscretizer.
The default is SampleUniform, which uniformly samples from the bin.
SampleBinCenter returns the bin's center value.
"""
function decode{N<:AbstractFloat,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    convert(N, lo + rand()*(hi-lo))
end
function decode{N<:AbstractFloat,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    convert(N, (hi + lo)/2)
end
decode{N<:AbstractFloat,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D) = decode(ld, d, SAMPLE_UNIFORM)

function decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    if hi != ld.binedges[end]
        retval = rand(lo:hi-1)::Int
    else
        retval = rand(lo:hi)::Int
    end
    convert(N, retval)
end
function decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter)
    ind = ld.d2i[d]
    lo = ld.binedges[ind]
    hi = ld.binedges[ind+1]
    convert(N, div(lo+hi,2))
end
decode{N<:Integer,D<:Integer}(ld::LinearDiscretizer{N,D}, d::D) = decode(ld, d, SAMPLE_UNIFORM)

decode{N<:Real,D<:Integer,I<:Integer}(ld::LinearDiscretizer{N,D}, d::I, method::AbstractSampleMethod=SAMPLE_UNIFORM) =
    decode(ld, convert(D,d), method)

function decode{N,D<:Integer}(ld::LinearDiscretizer{N,D}, data::AbstractArray{D}, ::AbstractSampleMethod=SAMPLE_UNIFORM)
    arr = Array{N}(length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(ld, d)
    end
    reshape(arr, size(data))
end

Base.max(ld::LinearDiscretizer) = ld.binedges[end]
Base.min(ld::LinearDiscretizer) = ld.binedges[1]
function Base.extrema{N,D}(ld::LinearDiscretizer{N,D})
    lo  = ld.binedges[1]
    hi  = ld.binedges[end]
    return (lo, hi)
end
function Base.extrema{N<:AbstractFloat,D}(ld::LinearDiscretizer{N,D}, d::D)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    return (lo, hi)
end
function Base.extrema{N<:Integer,D}(ld::LinearDiscretizer{N,D}, d::D)
    ind = ld.d2i[d]
    lo  = ld.binedges[ind]
    hi  = ld.binedges[ind+1]
    if hi == ld.binedges[end]
        (lo, hi)
    else
        (lo, hi-1)
    end
end
function totalwidth(ld::LinearDiscretizer)
    ex = extrema(ld)
    ex[2] - ex[1]
end

nlabels(ld::LinearDiscretizer) = ld.nbins
binedges(ld::LinearDiscretizer) = ld.binedges
bincenters{N<:AbstractFloat,D}(ld::LinearDiscretizer{N,D}) = (0.5*(ld.binedges[1:ld.nbins] + ld.binedges[2:end]))::Vector{Float64}
function bincenters{N<:Integer,D}(ld::LinearDiscretizer{N,D})
    retval = Array{Float64}(ld.nbins)
    for i = 1 : length(retval)-1
        retval[i] = 0.5(ld.binedges[i+1]-1 + ld.binedges[i])
    end
    retval[end] = 0.5(ld.binedges[end] + ld.binedges[end-1])
    retval
end
binwidth{N<:AbstractFloat,D}(ld::LinearDiscretizer{N,D}, d::D) = ld.binedges[d+1] - ld.binedges[d]
binwidths{N<:AbstractFloat,D}(ld::LinearDiscretizer{N,D}) = ld.binedges[2:end] - ld.binedges[1:end-1]