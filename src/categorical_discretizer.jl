# TODO(tim): support NA
# TODO(tim): support Nullable
# TODO(tim): support default value for missing keys

immutable CategoricalDiscretizer{N,D} <: AbstractDiscretizer{N,D}
    n2d :: Dict{N,D}    # maps natural to discrete
    d2n :: Dict{D,N}    # maps discrete to natural
end

function CategoricalDiscretizer{N,D}(natural_to_discrete::Dict{N,D})
    d2n = Dict{D,N}()
    for (k,v) in natural_to_discrete
        d2n[v] = k
    end
    CategoricalDiscretizer{N,D}(natural_to_discrete, d2n)
end
function CategoricalDiscretizer{N, D<:Integer}(data::AbstractArray{N}, ::Type{D}=Int)
    # build a label mapping N -> D <: Integer
    i = zero(D)
    n2d = @compat Dict{N, D}()
    for x in data
        if !haskey(n2d,x)
            n2d[x] = (i += 1)
        end
    end
    CategoricalDiscretizer(n2d)
end

supports_encoding{N,D}(cd::CategoricalDiscretizer{N,D}, x::N) = haskey(cd.n2d, x)
supports_decoding{N,D}(cd::CategoricalDiscretizer{N,D}, d::D) = 1 ≤ d ≤ nlabels(cd)

encode{N,D}(cd::CategoricalDiscretizer{N,D}, x::N) = cd.n2d[x]::D
encode{N,D}(cd::CategoricalDiscretizer{N,D}, x) = cd.n2d[convert(N,x)]::D
function encode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray)
    arr = Array(D, length(data))
    for (i,x) in enumerate(data)
        arr[i] = encode(cd, x)
    end
    reshape(arr, size(data))
end

decode{N,D}(cd::CategoricalDiscretizer{N,D}, x::D) = cd.d2n[x]::N
decode{N,D}(cd::CategoricalDiscretizer{N,D}, x) = cd.d2n[convert(D,x)]::N
function decode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray{D})
    arr = Array(N, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(cd, d)
    end
    reshape(arr, size(data))
end

nlabels(cd::CategoricalDiscretizer) = length(cd.n2d)