

type DiscretizeMODL <: DiscretizationAlgorithm 
    version :: Symbol # :greedy, :optimal, :postgreedy
    max_bin_count :: Int

    DiscretizeMODL(version::Symbol=:optimal, max_bin_count::Int=5) = new(version, max_bin_count)
end

function binedges{N<:Real, I<:Integer}(alg::DiscretizeMODL, data_continuous::AbstractArray{N}, data_class::AbstractArray{I})

    p = sortperm(data_continuous)
    data_continuous = data_continuous[p]
    data_class = data_class[p]

    if alg.version == :greedy
        _binedges_greedy()
    end
end