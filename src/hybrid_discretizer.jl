
# categorical contains specific exceptions
# if we cannot map to categorical, we map to linear instead

immutable HybridDiscretizer{N<:Real, D<:Integer} <: AbstractDiscretizer{N,D}
    cat :: CategoricalDiscretizer{N,D}
    lin :: LinearDiscretizer{N,D}
end
function datalineardiscretizer{D<:Integer}(binedges::Vector{Float64}, ::Type{D}=Int)
    cat = CategoricalDiscretizer([Inf=>1])
    lin = LinearDiscretizer(binedges, D)
    HybridDiscretizer{Float64,D}(cat, lin)
end

function supports_encoding{N<:Real,D<:Integer}(disc::HybridDiscretizer{N,D}, x::N)
    if haskey(disc.cat.n2d, x) || disc.lin.force_outliers_to_closest
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
    if d < disc.lin.nbins
        retval = decode(disc.lin)
    else
        retval = decode(disc.cat - disc.lin.nbins, method)
    end
    convert(N, retval)
end
decode{N<:Real,D<:Integer,E<:Integer}(disc::HybridDiscretizer{N,D}, d::E, method::AbstractSampleMethod=SAMPLE_UNIFORM) = 
    decode(disc, convert(D, d), method)

function decode{N,D<:Integer}(disc::HybridDiscretizer{N,D}, data::AbstractArray{D}, M::AbstractSampleMethod=SAMPLE_UNIFORM)
    arr = Array(N, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(disc, d)
    end
    reshape(arr, size(data))
end

Base.max(disc::HybridDiscretizer) = Base.max(disc.lin)
Base.min(disc::HybridDiscretizer) = Base.min(disc.lin)
extrema{N,D}(disc::HybridDiscretizer{N,D}) = extrema(disc.lin)
extrema{N<:FloatingPoint,D}(disc::HybridDiscretizer{N,D}, d::D) = extrema(disc.lin)
extrema{N<:Integer,D}(disc::HybridDiscretizer{N,D}, d::D) = extrema(disc.lin)
totalwidth(disc::HybridDiscretizer) = totalwidth(disc.lin)

nlabels(disc::HybridDiscretizer) = disc.lin.nbins + nlabels(disc.cat)
bincenters{N<:Real,D}(disc::HybridDiscretizer{N,D}) = bincenters(disc.lin)
binwidth{N<:FloatingPoint,D}(disc::HybridDiscretizer{N,D}, d::D) = binwidth(disc.lin, d)
binwidths{N<:FloatingPoint,D}(disc::HybridDiscretizer{N,D}) = binwidths(disc.lin)