# TODO(tim): support NA
# TODO(tim): support Nullable
# TODO(tim): support default value for missing keys

struct CategoricalDiscretizer{N,D} <: AbstractDiscretizer{N,D}
    n2d :: Dict{N,D}    # maps natural to discrete
    d2n :: Dict{D,N}    # maps discrete to natural
end

function CategoricalDiscretizer(natural_to_discrete::Dict{N,D}) where {N,D}
    d2n = Dict{D,N}()
    for (k,v) in natural_to_discrete
        d2n[v] = k
    end
    CategoricalDiscretizer{N,D}(natural_to_discrete, d2n)
end
function CategoricalDiscretizer(data::AbstractArray{N}, ::Type{D}=Int) where {N, D<:Integer}
    # build a label mapping N -> D <: Integer
    i = zero(D)
    n2d = Dict{N, D}()
    for x in data
        if !haskey(n2d,x)
            n2d[x] = (i += 1)
        end
    end
    CategoricalDiscretizer(n2d)
end

supports_encoding(cd::CategoricalDiscretizer{N,D}, x::N) where {N,D} = haskey(cd.n2d, x)
supports_decoding(cd::CategoricalDiscretizer{N,D}, d::D) where {N,D} = 1 ≤ d ≤ nlabels(cd)

encode(cd::CategoricalDiscretizer{N,D}, x::N) where {N,D} = cd.n2d[x]::D
encode(cd::CategoricalDiscretizer{Symbol,D}, x::AbstractString) where {D} = cd.n2d[Symbol(x)]::D
encode(cd::CategoricalDiscretizer{N,D}, x) where {N,D} = cd.n2d[convert(N,x)]::D
function encode(cd::CategoricalDiscretizer{N,D}, data::AbstractArray) where {N,D}
    arr = Array{D}(undef, length(data))
    for (i,x) in enumerate(data)
        arr[i] = encode(cd, x)
    end
    reshape(arr, size(data))
end

decode(cd::CategoricalDiscretizer{N,D}, x::D) where {N,D} = cd.d2n[x]::N
decode(cd::CategoricalDiscretizer{N,D}, x) where {N,D} = cd.d2n[convert(D,x)]::N
function decode(cd::CategoricalDiscretizer{N,D}, data::AbstractArray{D}) where {N,D}
    arr = Array{N}(undef, length(data))
    for (i,d) in enumerate(data)
        arr[i] = decode(cd, d)
    end
    reshape(arr, size(data))
end

nlabels(cd::CategoricalDiscretizer) = length(cd.n2d)