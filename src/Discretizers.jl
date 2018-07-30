__precompile__(true)

module Discretizers

import Base: extrema
import StatsBase: iqr, moment
import Statistics: std
import SpecialFunctions: lfactorial

export
    # generic types
    AbstractDiscretizer,
    DiscretizationAlgorithm,

    # discretizer types
    CategoricalDiscretizer, # maps 1D continuous values to/from discrete values
    LinearDiscretizer,      # maps discrete values to/from discrete values
    HybridDiscretizer,      # encodes categorical values first and then applies linear discretization

    # discretization algorithms
    DiscretizeUniformWidth,
    DiscretizeUniformCount,
    DiscretizeMODL_Optimal,
    DiscretizeMODL_Greedy,
    DiscretizeMODL_PostGreedy,
    DiscretizeBayesianBlocks,

    # sampling methods
    AbstractSampleMethod,
    SampleUniform,                    # sample uniform from bin bounds
    SampleBinCenter,                  # return bin center
    SAMPLE_UNIFORM,
    SAMPLE_BIN_CENTER,

    # methods
    encode,             # map from natural to discretized state
    decode,             # map or sample from discretized to natural state
    nlabels,            # number of discrete labels
    encoded_type,       # obtain the encoded type, typically discrete
    decoded_type,       # obtain the decoded type, often continuous
    supports_encoding,  # whether discretizer supports encoding given variable
    supports_decoding,  # whether discretizer supports decoding given variable
    binedges,           # compute bin edges using a discretization algorithm
    binwidth,           # the width of the ith bin
    binwidths,          # an array of bin widths

    get_discretization_counts, # get a list of counts; can be used to generate a histogram
    get_histogram_plot_arrays, # returns arr_x and arr_y for plotting a histogram given binedges and counts

    datalineardiscretizer, # build a linear discretizer which maps Inf to a bin

    # linear discretizer
    totalwidth,        # total width of set, max-mina
    bincenters         # Vector{Float64} list of bin centers

### source files

include("common.jl")

include("sample_methods.jl")

include("categorical_discretizer.jl")
include("linear_discretizer.jl")
include("hybrid_discretizer.jl")

include("disc_uniformwidth.jl")
include("disc_uniformcount.jl")
include("disc_MODL.jl")
include("disc_bayesianblocks.jl")

end # module