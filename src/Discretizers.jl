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
    DiscretizeMODL_Optimal,
    DiscretizeMODL_Greedy,
    DiscretizeMODL_PostGreedy,

    # sampling methods
    AbstractSampleMethod,
    SampleUniform,                    # sample uniform from bin bounds
    SampleBinCenter,                  # return bin center
    SampleUniformZeroBin,             # return 0 if bin contains it, otherwise sample uniform
    SAMPLE_UNIFORM,
    SAMPLE_BIN_CENTER,
    SAMPLE_UNIFORM_ZERO_BIN,

    # methods
    encode,             # map from natural to discretized state
    decode,             # map or sample from discretized to natural state
    nlabels,            # number of discrete labels
    supports_encoding,  # whether discretizer supports encoding given type or variable
    supports_decoding,  # whether discretizer supports decoding given type or variable
    binedges,           # compute bin edges using a discretization algorithm
    binwidth,           # the width of the ith bin
    binwidths,          # an array of bin widths

    # linear discretizer
    extrema,            # (min,max) for bin or for entire set
    totalwidth,         # total width of set, max-min
    bincenters,         # Vector{Float64} list of bin centers


    # reexport
    NA,
    DataArray

### source files

include("common.jl")

include("categorical_discretizer.jl")
include("linear_discretizer.jl")
include("sample_methods.jl")

include("disc_uniformwidth.jl")
include("disc_uniformcount.jl")
include("disc_MODL.jl")


end # module

