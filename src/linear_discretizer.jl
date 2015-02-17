
# NOTE(tim):
# value V will be placed in bin B if V ∈ [Bₗ Bᵣ)
# (or V ∈ [Bₗ Bᵣ] if B is the rightmost bin)

# TODO(tim):
# handle NA
# handle Nullable
# specify how to handle NaN

const DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST = true

immutable LinearDiscretizer{N<:Real, D} <: AbstractDiscretizer{N,D}
    binedges :: Vector{N}   # list of bin edges, sorted smallest to largest
    nbins    :: Int
    i2d      :: Dict{Int,D} # maps bin index to discrete label
    d2i      :: Dict{D,Int} # maps discrete label to bin index
    force_outliers_to_closest :: Bool # if true, real values outside of the bin ranges will be forced to the nearest bin, otherwise will throw an error
end

function LinearDiscretizer{N<:Real, D}( binedges::Vector{N}, i2d::Dict{Int,D};
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST )

    length(binedges) > 1 || error("bin edges must contain at least 2 values")
    findfirst(i->binedges[i-1] > binedges[i], [2:length(binedges)]) == 0 || 
        error("Bin edges must be sorted in increasing order")
    for i = 1 : length(binedges)-1
        haskey(i2d, i) || error("i2d must contain all necessary keys")
    end

    d2i = Dict{D,Int}()
    for (k,v) in i2d
        d2i[v] = k
    end
    
    LinearDiscretizer{N,D}(binedges, length(binedges)-1, i2d, d2i, force_outliers_to_closest)
end
function LinearDiscretizer{N<:Real, D<:Integer}( binedges::Vector{N}, ::Type{D} = Int;
    force_outliers_to_closest::Bool = DEFAULT_LIN_DISC_FORCE_OUTLIERS_TO_CLOSEST )

    length(binedges) > 1 || error("bin edges must contain at least 2 values")
    findfirst(i->binedges[i-1] > binedges[i], [2:length(binedges)]) == 0 || 
        error("Bin edges must be sorted in increasing order")

    i2d = Dict{Int,D}()
    for i = 1 : length(binedges)-1
        i2d[i] = convert(D, i)
    end
    
    LinearDiscretizer(binedges,i2d,force_outliers_to_closest=force_outliers_to_closest)
end

function encode{N,D}(ld::LinearDiscretizer{N,D}, x::N)
    if isnan(x)
        error("cannot encode NaN values")
    end
    if x < ld.binedges[1]
        return ld.force_outliers_to_closest ? ld.i2d[1] : throw(BoundsError())
    elseif x > ld.binedges[end]
        return ld.force_outliers_to_closest ? ld.i2d[ld.nbins] : throw(BoundsError())
    end

    # run bisection search
    binedges = ld.binedges
    a, b = 1, length(binedges)
    va, vb = binedges[a], binedges[b]
    if isapprox(vb, x)
        return b-1
    end
    while b-a > 1
        c = div(a+b, 2)
        vc = binedges[c]
        if isapprox(x, vc)
            return c
        end
        if x < vc
            b, vb = c, vc
        else
            a, va = c, vc
        end
    end
    return a
end
encode{N,D}(ld::LinearDiscretizer{N,D}, x) = encode(ld, convert(N, x))::D
encode{N,D}(ld::LinearDiscretizer{N,D}, data::AbstractArray) = 
    reshape(D[encode(ld, x) for x in data], size(data))

# function decode{N,D}(ld::LinearDiscretizer{N,D}, x::S)
#     ind = ld.d2i[x]
#     lo  = ld.binedges[ind]
#     hi  = ld.binedges[ind+1]

#     if ld.zero_bin && lo <= 0 <= hi
#         0.0
#     else
#         rand(T)*(hi-lo) + lo
#     end
# end
# decode{N,D}(ld::LinearDiscretizer{N,D}, x) = decode(ld, convert(S,x))::T
# decode{N,D}(ld::LinearDiscretizer{N,D}, data::AbstractArray{S}) = 
#     reshape(T[decode(ld, x) for x in data], size(data))
# decode{N,D}(ld::LinearDiscretizer{N,D}, data::DataArray{S}) = 
#     reshape(T[decode(ld, x) for x in data], size(data))

# function bin_bounds{N,D}(ld::LinearDiscretizer{N,D}, x::S)
#     ind = ld.d2i[x]
#     lo  = ld.binedges[ind]
#     hi  = ld.binedges[ind+1]
#     (lo, hi)
# end
# bin_centers(ld::LinearDiscretizer) = 0.5*(ld.binedges[1:ld.nbins] + ld.binedges[2:end])

# nlabels(ld::LinearDiscretizer) = ld.nbins