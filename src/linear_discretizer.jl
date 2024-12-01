

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
    force_outliers_to_closest :: Bool # if true, real values outside of the bin ranges will be forced to the nearest bin, otherwise will throw an error
end

function LinearDiscretizer(binedges::AbstractArray{N}, ::Type{D} = Int;
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST ) where {N<:Real, D<:Integer}

    length(binedges) > 1 || error("bin edges must contain at least 2 values")

    if N <: AbstractFloat
        findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)) == nothing ||
            error("Bin edges must be sorted in increasing order")
    else # for integers, bins of unit width require repeated values
        (findfirst(i->binedges[i-1] ≥ binedges[i], 2:length(binedges)-1) == nothing &&
         findfirst(i->binedges[i-1] > binedges[i], 2:length(binedges)) == nothing ) ||
            error("Bin edges must be sorted in increasing order")
    end

    nbins = length(binedges)-1

    return LinearDiscretizer{N,D}(convert(Vector{N}, binedges), nbins, force_outliers_to_closest)
end

function supports_encoding(ld::LinearDiscretizer{N,D}, x::N) where {N<:Real,D<:Integer}
    if ld.force_outliers_to_closest
        return true
    else
        return ld.binedges[1] ≤ x ≤ ld.binedges[end]
    end
end
supports_decoding(ld::LinearDiscretizer{N,D}, d::D) where {N<:Real,D<:Integer} = 1 ≤ d ≤ ld.nbins

function encode(ld::LinearDiscretizer{N,D}, x::N) where {N<:Real,D<:Integer}
    !isnan(x) || error("cannot encode NaN values")

    if x < ld.binedges[1]
        return ld.force_outliers_to_closest ? convert(D,1) : throw(BoundsError())
    elseif x > ld.binedges[end]
        return ld.force_outliers_to_closest ? convert(D,ld.nbins) : throw(BoundsError())
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
        return convert(D,a)
    end
end
encode(ld::LinearDiscretizer{N,D}, x) where {N<:Real,D<:Integer} = encode(ld, convert(N, x))::D
function encode(ld::LinearDiscretizer{N,D}, data::AbstractArray) where {N<:Real,D<:Integer}
    arr = [encode(ld, x) for x in data]
    reshape(arr, size(data))
end

"""
There are several methods for decoding a LinearDiscretizer.
The default is SampleUniform, which uniformly samples from the bin.
SampleBinCenter returns the bin's center value.
"""
function decode(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform) where {N<:AbstractFloat,D<:Integer}
    lo  = ld.binedges[d]
    hi  = ld.binedges[d+1]
    convert(N, lo + rand()*(hi-lo))
end
function decode(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter) where {N<:AbstractFloat,D<:Integer}
    lo  = ld.binedges[d]
    hi  = ld.binedges[d+1]
    convert(N, (hi + lo)/2)
end
decode(ld::LinearDiscretizer{N,D}, d::D) where {N<:AbstractFloat,D<:Integer} = decode(ld, d, SAMPLE_UNIFORM)

function decode(ld::LinearDiscretizer{N,D}, d::D, ::SampleUniform) where {N<:Integer,D<:Integer}
    lo  = ld.binedges[d]
    hi  = ld.binedges[d+1]
    if hi != ld.binedges[end]
        retval = rand(lo:hi-1)::Int
    else
        retval = rand(lo:hi)::Int
    end
    convert(N, retval)
end
function decode(ld::LinearDiscretizer{N,D}, d::D, ::SampleBinCenter) where {N<:Integer,D<:Integer}
    lo = ld.binedges[d]
    hi = ld.binedges[d+1]
    convert(N, div(lo+hi,2))
end
decode(ld::LinearDiscretizer{N,D}, d::D) where {N<:Integer,D<:Integer} = decode(ld, d, SAMPLE_UNIFORM)

decode(ld::LinearDiscretizer{N,D}, d::I, method::AbstractSampleMethod=SAMPLE_UNIFORM) where {N<:Real,D<:Integer,I<:Integer} =
    decode(ld, convert(D,d), method)

function decode(ld::LinearDiscretizer{N,D}, data::AbstractArray{D}, method::AbstractSampleMethod=SAMPLE_UNIFORM) where {N<:Real,D<:Integer}
    arr = Vector{N}(undef, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(ld, d, method)
    end
    reshape(arr, size(data))
end

Base.max(ld::LinearDiscretizer) = ld.binedges[end]
Base.min(ld::LinearDiscretizer) = ld.binedges[1]
function Base.extrema(ld::LinearDiscretizer{N,D}) where {N<:Real,D<:Integer}
    lo  = ld.binedges[1]
    hi  = ld.binedges[end]
    return (lo, hi)
end
function Base.extrema(ld::LinearDiscretizer{N,D}, d::D) where {N<:AbstractFloat,D<:Integer}
    lo  = ld.binedges[d]
    hi  = ld.binedges[d+1]
    return (lo, hi)
end
function Base.extrema(ld::LinearDiscretizer{N,D}, d::D) where {N<:Integer,D<:Integer}
    lo  = ld.binedges[d]
    hi  = ld.binedges[d+1]
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
bincenters(ld::LinearDiscretizer{N,D}) where {N<:AbstractFloat,D<:Integer} = (0.5*(ld.binedges[1:ld.nbins] + ld.binedges[2:end]))::Vector{Float64}
function bincenters(ld::LinearDiscretizer{N,D}) where {N<:Integer,D<:Integer}
    retval = Vector{Float64}(undef, ld.nbins)
    for i = 1 : length(retval)-1
        retval[i] = 0.5(ld.binedges[i+1]-1 + ld.binedges[i])
    end
    retval[end] = 0.5(ld.binedges[end] + ld.binedges[end-1])
    retval
end
bincenter(ld::LinearDiscretizer{N}, i) where N <: AbstractFloat = 0.5*(ld.binedges[i+1] + ld.binedges[i])
function bincenter(ld::LinearDiscretizer{N}, i) where N <: Integer
    if i == length(ld.binedges)-1
        return 0.5*(ld.binedges[end] + ld.binedges[end-1])
    else
        return 0.5*(ld.binedges[i+1]-1 + ld.binedges[i])
    end
end

binwidth(ld::LinearDiscretizer{N,D}, d::D) where {N<:Real,D<:Integer} = ld.binedges[d+1] - ld.binedges[d]
binwidths(ld::LinearDiscretizer{N,D}) where {N<:Real,D<:Integer} = ld.binedges[2:end] - ld.binedges[1:end-1]
