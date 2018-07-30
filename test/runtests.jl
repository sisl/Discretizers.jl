using Base.Test

# using Lint
# lintpkg( "Discretizers" )
# @test isempty(lintpkg( "Discretizers", returnMsgs=true))

################

using Discretizers

function array_matches(arr::AbstractVector{S}, arr2::AbstractVector{T}) where {S<:Integer, T<:Integer}
    n = length(arr)
    @assert(length(arr2) == n)
    for i = 1 : n
        if arr[i] != arr2[i]
            return false
        end
    end
    true
end
function array_matches(arr::AbstractVector{S}, arr2::AbstractVector{T}, abs_tolerance::AbstractFloat=eps(Float64)) where {S<:Real, T<:Real}
    n = length(arr)
    @assert(length(arr2) == n)
    for i = 1 : n
        if abs(arr[i] - arr2[i]) > abs_tolerance
            return false
        end
    end
    true
end


include("test_categorical_discretizer.jl")
include("test_linear_discretizer.jl")
include("test_hybrid_discretizer.jl")

include("test_common.jl")

include("test_disc_uniformwidth.jl")
include("test_disc_uniformcount.jl")
include("test_disc_bayesianblocks.jl")
include("test_disc_MODL.jl")
