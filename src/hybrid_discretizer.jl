
# categorical contains specific exceptions
# if we cannot map to categorical, we map to linear instead

immutable HybridDiscretizer{N<:Real, D<:Integer} <: AbstractDiscretizer{N,D}
    cat :: CategoricalDiscretizer{N,D}
    lin :: LinearDiscretizer{N,D}
end

"""
a hybrid discretizers that maps a special missing value indicator (typically Inf or NaN)
to a discrete bin, but otherwise is a linear discretizer
"""
function datalineardiscretizer{D<:Integer}(binedges::Vector{Float64}, ::Type{D}=Int;
    missing_key::Float64=Inf,
    force_outliers_to_closest::Bool=DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST,
    )

    categorical = CategoricalDiscretizer(@compat Dict{Float64, Int}(missing_key=>1))
    linear = LinearDiscretizer(binedges, D, force_outliers_to_closest=force_outliers_to_closest)
    HybridDiscretizer{Float64,D}(categorical, linear)
end

function supports_encoding{N<:Real,D<:Integer}(disc::HybridDiscretizer{N,D}, x::N)
    if haskey(disc.cat.n2d, x) ||
        (disc.lin.force_outliers_to_closest && !isnan(x))
        return true
    else
        return disc.lin.binedges[1] ≤ x ≤ disc.lin.binedges[end]
    end
end
supports_decoding{N<:Real,D<:Integer}(disc::HybridDiscretizer{N,D}, d::D) = 1 ≤ d ≤ nlabels(disc)

function encode{N,D<:Integer}(disc::HybridDiscretizer{N,D}, x::N)

    if haskey(disc.cat.n2d, x)
        return encode(disc.cat, x) + disc.lin.nbins
    end

    convert(D, encode(disc.lin, x))
end
encode{N,D}(disc::HybridDiscretizer{N,D}, x) = encode(disc, convert(N, x))::D
function encode{N,D<:Integer}(disc::HybridDiscretizer{N,D}, data::AbstractArray)
    arr = Array(D, length(data))
    for (i,x) in enumerate(data)
        arr[i] = encode(disc, x)
    end
    reshape(arr, size(data))
end

function decode{N<:Real,D<:Integer}(disc::HybridDiscretizer{N,D}, d::D, method::AbstractSampleMethod=SAMPLE_UNIFORM)
    if d ≤ disc.lin.nbins
        retval = decode(disc.lin, d, method)
    else
        retval = decode(disc.cat,  d - disc.lin.nbins)
    end
    convert(N, retval)
end
decode{N<:Real,D<:Integer,E<:Integer}(disc::HybridDiscretizer{N,D}, d::E, method::AbstractSampleMethod=SAMPLE_UNIFORM) =
    decode(disc, convert(D, d), method)

function decode{N,D<:Integer}(disc::HybridDiscretizer{N,D}, data::AbstractArray{D}, ::AbstractSampleMethod=SAMPLE_UNIFORM)
    arr = Array(N, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(disc, d)
    end
    reshape(arr, size(data))
end

Base.max(disc::HybridDiscretizer) = Base.max(disc.lin)
Base.min(disc::HybridDiscretizer) = Base.min(disc.lin)
extrema{N,D}(disc::HybridDiscretizer{N,D}) = extrema(disc.lin)
extrema{N<:AbstractFloat,D}(disc::HybridDiscretizer{N,D}, d::D) = extrema(disc.lin, d)
extrema{N<:Integer,D}(disc::HybridDiscretizer{N,D}, d::D) = extrema(disc.lin, d)
totalwidth(disc::HybridDiscretizer) = totalwidth(disc.lin)

nlabels(disc::HybridDiscretizer) = disc.lin.nbins + nlabels(disc.cat)
bincenters{N<:Real,D}(disc::HybridDiscretizer{N,D}) = bincenters(disc.lin)
binwidth{N<:AbstractFloat,D}(disc::HybridDiscretizer{N,D}, d::D) = binwidth(disc.lin, d)
binwidths{N<:AbstractFloat,D}(disc::HybridDiscretizer{N,D}) = binwidths(disc.lin)