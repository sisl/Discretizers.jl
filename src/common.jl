

# AbstractDiscretizer

abstract AbstractDiscretizer{N,D}
    # N indicates the natural type
    # D indicates the discrete type, typically an integer

supports_encoding{N,D}(::AbstractDiscretizer{N,D}, typ::Type) = typ <: N
supports_encoding{N,D}(::AbstractDiscretizer{N,D}, x) = isa(x, N)

supports_decoding{N,D}(::AbstractDiscretizer{N,D}, typ::Type) = typ <: D
supports_decoding{N,D}(::AbstractDiscretizer{N,D}, x) = isa(x, D)


# DiscretizationAlgorithm

abstract DiscretizationAlgorithm