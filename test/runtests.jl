using Test
using Discretizers

function array_matches(arr::AbstractVector{S}, arr2::AbstractVector{T}) where {S<:Integer, T<:Integer}
    n = length(arr)
    if length(arr2) != n
        return false
    end
    for (a,b) in zip(arr, arr2)
        if a != b
            return false
        end
    end
    return true
end
function array_matches(arr::AbstractVector{S}, arr2::AbstractVector{T}, abs_tolerance::AbstractFloat=eps(Float64)) where {S<:Real, T<:Real}
    n = length(arr)
    if length(arr2) != n
        return false
    end
    for i in 1 : n
        if abs(arr[i] - arr2[i]) > abs_tolerance
            return false
        end
    end
    return true
end


include("test_categorical_discretizer.jl")
include("test_linear_discretizer.jl")
include("test_hybrid_discretizer.jl")

include("test_common.jl")

include("test_disc_uniformwidth.jl")
include("test_disc_uniformcount.jl")
include("test_disc_bayesianblocks.jl")
include("test_disc_MODL.jl")
