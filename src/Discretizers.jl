module Discretizers

# using DataArrays

import Base: extrema

export
    # generic types
    AbstractDiscretizer,
    DiscretizationAlgorithm,

    # discretizer types
    CategoricalDiscretizer, # maps 1D continuous values to/from discrete values
    LinearDiscretizer,      # maps discrete values to/from discrete values

    # discretization algorithms
    DiscretizeUniformWidth,
    DiscretizeUniformCount,
    DiscretizeMODL,

    # methods
    encode,             # map from natural to discretized state
    decode,             # map or sample from discretized to natural state
    nlabels,            # number of discrete labels
    supports_encoding,  # whether discretizer supports encoding given type or variable
    supports_decoding,  # whether discretizer supports decoding given type or variable
    binedges,           # compute bin edges using a discretization algorithm

    # linear discretizer
    extrema,            # (min,max) for bin or for entire set
    bincenters,         # Vector{Float64} list of bin centers

    # reexport
    NA,
    DataArray

### source files

include("common.jl")

include("categorical_discretizer.jl")
include("linear_discretizer.jl")
include("disc_uniformwidth.jl")


end # module
