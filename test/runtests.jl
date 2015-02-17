using Discretizers
using Base.Test

function array_matches{S<:Integer, T<:Integer}(arr::AbstractVector{S}, arr2::AbstractVector{T})
    n = length(arr)
    @assert(length(arr2) == n)
    for i = 1 : n
        if arr[i] != arr2[i]
            return false
        end
    end
    true
end
function array_matches{S<:Real, T<:Real}(arr::AbstractVector{S}, arr2::AbstractVector{T}, abs_tolerance::FloatingPoint)
    n = length(arr)
    @assert(length(arr2) == n)
    for i = 1 : n
        if abs(arr[i] - arr2[i]) > abs_tolerance
            return false
        end
    end
    true
end

LinearDiscretizer([0.0,0.5,1.0], [1=>:A, 2=>:B])
LinearDiscretizer([0.0,0.5,1.0], Uint8)

ld = LinearDiscretizer([0.0,0.5,1.0])
@test encode(ld, -1.0) == 1
@test encode(ld,  0.0) == 1
@test encode(ld,  0.2) == 1
@test encode(ld,  0.5) == 2
@test encode(ld,  0.7) == 2
@test encode(ld,  1.0) == 2
@test encode(ld,  1.2) == 2
@test encode(ld,  Inf) == 2
@test_throws ErrorException encode(ld,  NaN)
@test encode(ld, float32(0.2)) == 1
@test encode(ld, [-1.0, 0.0, 0.2, 0.5, 0.7, 1.0, 1.2, Inf]) == 
        [1,1,1,2,2,2,2,2]
@test encode(ld, convert(Vector{Float32}, [0.2,0.6])) ==
        [1,2]

# @test decode(ld, 1)

# @test encode(cd, "B") == 2
# @test encode(cd, [:C, :B, :A, :B, :C]) == [3,2,1,2,3]
# @test encode(cd, [:A :B; :C :A]) == [1 2; 3 1]
# @test_throws KeyError encode(cd, :D)
# @test_throws KeyError encode(cd, [:A, :D])

include("test_categorical_discretizer.jl")