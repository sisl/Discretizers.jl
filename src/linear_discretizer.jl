
immutable LinearDiscretizer{N<:FloatingPoint, D} <: AbstractDiscretizer{N,D}
    i2bin    :: Dict{Int,D}
    bin2i    :: Dict{D,Int}
    binedges :: Vector{N}
    nbins    :: Int
    # force_outliers_to_closest :: Bool # if true, real values outside of the bin ranges will be forced to the nearest bin, otherwise will throw an error
    # zero_bin :: Bool # if true, when decoding bin containing 0 return 0 instead of sampling
end