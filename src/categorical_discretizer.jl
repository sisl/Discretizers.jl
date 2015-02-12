
immutable CategoricalDiscretizer{N,D} <: AbstractDiscretizer{N,D}
    n2d :: Dict{N,D} # maps natural to discrete
    d2n :: Dict{D,N} # maps discrete to natural
end

function CategoricalDiscretizer{N,D}(natural_to_discrete::Dict{N,D})
    d2n = Dict{D,N}()
    for (k,v) in natural_to_discrete
        d2n[v] = k
    end
    CategoricalDiscretizer{N,D}(natural_to_discrete, d2n)
end
function CategoricalDiscretizer{N, D<:Integer}(data::AbstractArray{N}, ::Type{D})
    # build a label mapping N -> D <: Integer
    i = zero(S)
    n2d = (N=>D)[]
    for x in data
        if !haskey(n2d,x)
            n2d[x] = (i += 1)
        end
    end
    CategoricalDiscretizer(n2d)
end

encode{N,D}(cd::CategoricalDiscretizer{N,D}, x::N) = cd.n2d[x]::D
encode{N,D}(cd::CategoricalDiscretizer{N,D}, x) = cd.n2d[convert(N,x)]::D
encode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray{N}) = 
    reshape(D[encode(cd, x) for x in data], size(data))
encode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray) = 
    reshape(D[encode(cd, x) for x in data], size(data))
encode{N,D}(cd::CategoricalDiscretizer{N,D}, data::DataArray{N}) =
    reshape(D[encode(cd, x) for x in data], size(data))
encode{N,D}(cd::CategoricalDiscretizer{N,D}, data::DataArray) =
    reshape(D[encode(cd, x) for x in data], size(data))

decode{N,D}(cd::CategoricalDiscretizer{N,D}, x::D) = cd.d2n[x]::N
decode{N,D}(cd::CategoricalDiscretizer{N,D}, x) = cd.d2n[convert(D,x)]::N
decode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray{D}) = 
    reshape(N[decode(cd, x) for x in data], size(data))
decode{N,D}(cd::CategoricalDiscretizer{N,D}, data::AbstractArray) = 
    reshape(N[decode(cd, x) for x in data], size(data))
decode{N,D}(cd::CategoricalDiscretizer{N,D}, data::DataArray{D}) = 
    reshape(N[decode(cd, x) for x in data], size(data))
decode{N,D}(cd::CategoricalDiscretizer{N,D}, data::DataArray) = 
    reshape(N[decode(cd, x) for x in data], size(data))

nlabels(cd::CategoricalDiscretizer) = length(cd.n2d)