# AbstractDiscretizer
abstract type AbstractDiscretizer{N,D} end
    # N indicates the decoded, or natural type
    # D indicates the encoded, or discrete type

encoded_type(::AbstractDiscretizer{N,D}) where {N,D} = D
decoded_type(::AbstractDiscretizer{N,D}) where {N,D} = N


# DiscretizationAlgorithm
abstract type DiscretizationAlgorithm end

function get_discretization_counts(disc::AbstractDiscretizer, data::AbstractArray)
    counts = zeros(Int, nlabels(disc))
    for v in data
        counts[encode(disc, v)] += 1
    end
    counts
end

function get_discretization_counts(discs::Vector{T}, data::AbstractMatrix{N}) where {N, D, T<:AbstractDiscretizer{N, D}}
    nobservations, ndimensions = size(data)
    @assert length(discs) == ndimensions

    nbins = Tuple(nlabels.(discs))
    counts = zeros(Int, nbins)
    for i in 1:nobservations  # for each data point
        binaddress = zeros(D, ndimensions)
        for j in 1:ndimensions  # for each dimension
            binaddress[j] = encode(discs[j], data[i, j])
        end
        counts[binaddress...] += 1
    end

    counts
end

function get_histogram_plot_arrays(binedges::Vector{R}, counts::AbstractVector{I}) where {R<:Real, I<:Integer}
    n = length(binedges)
    n == length(counts)+1 || error("binedges must have exactly one more entry than counts!")

    arr_x = Array{R}(n+1)
    arr_x[1] = binedges[1]
    arr_x[2:n+1] = binedges

    arr_y = Array{I}(n+1)
    arr_y[1] = zero(I)
    arr_y[2:n] = counts
    arr_y[end] = zero(I)

    (arr_x, arr_y)
end
function get_histogram_plot_arrays(binedges::Vector{R}, pdfs::AbstractVector{F}) where {R<:Real, F<:Real}
    n = length(binedges)
    n == length(pdfs)+1 || error("binedges must have exactly one more entry than counts!")

    arr_x = Array{R}(n+1)
    arr_x[1] = binedges[1]
    arr_x[2:n+1] = binedges

    arr_y = Array{F}(n+1)
    arr_y[1] = zero(F)
    arr_y[2:n] = pdfs
    arr_y[end] = zero(F)

    (arr_x, arr_y)
end