

# AbstractDiscretizer

abstract AbstractDiscretizer{N,D}
    # N indicates the decoded, or natural type
    # D indicates the encoded, or discrete type

encoded_type{N,D}(::AbstractDiscretizer{N,D}) = D
decoded_type{N,D}(::AbstractDiscretizer{N,D}) = N


# DiscretizationAlgorithm

abstract DiscretizationAlgorithm

function get_discretization_counts(disc::AbstractDiscretizer, data::AbstractArray)
    counts = zeros(Int, nlabels(disc))
    for v in data
        counts[encode(disc, v)] += 1
    end
    counts
end

function get_histogram_plot_arrays{R<:Real, I<:Integer}(binedges::Vector{R}, counts::AbstractVector{I})
    n = length(binedges)
    n == length(counts)+1 || error("binedges must have exactly one more entry than counts!")
    
    arr_x = Array(R, n+1)
    arr_x[1] = binedges[1]
    arr_x[2:n+1] = binedges

    arr_y = Array(I, n+1)
    arr_y[1] = zero(I)
    arr_y[2:n] = counts
    arr_y[end] = zero(I)

    (arr_x, arr_y)
end
function get_histogram_plot_arrays{R<:Real, F<:Real}(binedges::Vector{R}, pdfs::AbstractVector{F})
    n = length(binedges)
    n == length(pdfs)+1 || error("binedges must have exactly one more entry than counts!")
    
    arr_x = Array(R, n+1)
    arr_x[1] = binedges[1]
    arr_x[2:n+1] = binedges

    arr_y = Array(F, n+1)
    arr_y[1] = zero(F)
    arr_y[2:n] = pdfs
    arr_y[end] = zero(F)

    (arr_x, arr_y)
end