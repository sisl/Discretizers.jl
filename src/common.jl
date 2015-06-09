

# AbstractDiscretizer

abstract AbstractDiscretizer{N,D}
    # N indicates the decoded, or natural type
    # D indicates the encoded, or discrete type

encoded_type{N,D}(::AbstractDiscretizer{N,D}) = D
decoded_type{N,D}(::AbstractDiscretizer{N,D}) = N


# DiscretizationAlgorithm

abstract DiscretizationAlgorithm