
# categorical contains specific exceptions
# if we cannot map to categorical, we map to linear instead

struct HybridDiscretizer{N<:Real, D<:Integer} <: AbstractDiscretizer{N,D}
    cat :: CategoricalDiscretizer{N,D}
    lin :: LinearDiscretizer{N,D}
end

"""
a hybrid discretizers that maps a special missing value indicator (typically Inf or NaN)
to a discrete bin, but otherwise is a linear discretizer
"""
function datalineardiscretizer(binedges::Vector{Float64}, ::Type{D}=Int;
    missing_key::Float64=Inf,
    force_outliers_to_closest::Bool=DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST,
    ) where {D<:Integer}

    categorical = CategoricalDiscretizer(Dict{Float64, Int}(missing_key=>1))
    linear = LinearDiscretizer(binedges, D, force_outliers_to_closest=force_outliers_to_closest)
    HybridDiscretizer{Float64,D}(categorical, linear)
end

function supports_encoding(disc::HybridDiscretizer{N,D}, x::N) where {N<:Real,D<:Integer}
    if haskey(disc.cat.n2d, x) ||
        (disc.lin.force_outliers_to_closest && !isnan(x))
        return true
    else
        return disc.lin.binedges[1] ≤ x ≤ disc.lin.binedges[end]
    end
end
supports_decoding(disc::HybridDiscretizer{N,D}, d::D) where {N<:Real,D<:Integer} = 1 ≤ d ≤ nlabels(disc)

function encode(disc::HybridDiscretizer{N,D}, x::N) where {N,D<:Integer}

    if haskey(disc.cat.n2d, x)
        return encode(disc.cat, x) + disc.lin.nbins
    end

    convert(D, encode(disc.lin, x))
end
encode(disc::HybridDiscretizer{N,D}, x) where {N,D} = encode(disc, convert(N, x))::D
function encode(disc::HybridDiscretizer{N,D}, data::AbstractArray) where {N,D<:Integer}
    arr = Vector{D}(undef, length(data))
    for (i,x) in enumerate(data)
        arr[i] = encode(disc, x)
    end
    reshape(arr, size(data))
end

function decode(disc::HybridDiscretizer{N,D}, d::D, method::AbstractSampleMethod=SAMPLE_UNIFORM)::N where {N<:Real,D<:Integer}
    if d ≤ disc.lin.nbins
        retval = decode(disc.lin, d, method)
    else
        retval = decode(disc.cat,  d - disc.lin.nbins)
    end
    return retval
end
decode(disc::HybridDiscretizer{N,D}, d::E, method::AbstractSampleMethod=SAMPLE_UNIFORM) where {N<:Real,D<:Integer,E<:Integer} =
    decode(disc, convert(D, d), method)

function decode(disc::HybridDiscretizer{N,D}, data::AbstractArray{D}, ::AbstractSampleMethod=SAMPLE_UNIFORM) where {N,D<:Integer}
    arr = Vector{N}(undef, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(disc, d)
    end
    reshape(arr, size(data))
end

Base.max(disc::HybridDiscretizer) = Base.max(disc.lin)
Base.min(disc::HybridDiscretizer) = Base.min(disc.lin)
Base.extrema(disc::HybridDiscretizer) = extrema(disc.lin)
Base.extrema(disc::HybridDiscretizer{N,D}, d::D) where {N<:AbstractFloat,D} = extrema(disc.lin, d)
Base.extrema(disc::HybridDiscretizer{N,D}, d::D) where {N<:Integer,D} = extrema(disc.lin, d)
totalwidth(disc::HybridDiscretizer) = totalwidth(disc.lin)

nlabels(disc::HybridDiscretizer) = disc.lin.nbins + nlabels(disc.cat)
bincenters(disc::HybridDiscretizer) = bincenters(disc.lin)
binwidth(disc::HybridDiscretizer{N,D}, d::D) where {N<:AbstractFloat,D} = binwidth(disc.lin, d)
binwidths(disc::HybridDiscretizer{N,D}) where {N<:AbstractFloat,D} = binwidths(disc.lin)