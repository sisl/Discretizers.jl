# Bayesian blocks
# Implementation by Michael P.H. Stumpf and T. Chan
# Based on the Python Code of Jake Vanderplas.

# This version implements Bayesian blocks for histograms, where the
# data are sorted, then treated as event data (see Scargle 2012).
# Defaults as suggested in Scargle 2012 are used.

# References:
# Scargle 2012: http://adsabs.harvard.edu/abs/2012arXiv1207.5578S
# Python implementation: https://github.com/astroML/astroML/blob/master/astroML/density_estimation/bayesian_blocks.py

struct DiscretizeBayesianBlocks <: DiscretizationAlgorithm
end

function binedges(alg::DiscretizeBayesianBlocks, data::AbstractArray{N}) where {N<:AbstractFloat}

	unique_data = unique(data)
	unique_data = sort(unique_data)

	n = length(unique_data) # Number of observations

	edges = zeros(n+1)
	edges[1] = unique_data[1]
	for i in 1 : (n-1)
		edges[i+1] = 0.5 * (unique_data[i]+unique_data[i+1])
	end
	edges[end] = unique_data[end]
	block_length = unique_data[end] .- edges

	if length(unique_data) == length(data)
		nn_vec = ones(length(data))
	else
		nn_vec = convert(Array{Float64}, [length(findall((in)(v), data)) for v in unique_data])
	end

	count_vec = zeros(n)
	best = zeros(n)
	last = zeros(Int64,n)

	for K in 1 : n
		widths = block_length[1:K] .- block_length[K+1]
		count_vec[1 : K] .+= nn_vec[K]

		# Fitness function (eq. 19 from Scargle 2012)
		fit_vec = count_vec[1 : K] .* log.(count_vec[1 : K] ./ widths)
		# Prior (eq. 21 from Scargle 2012)
		fit_vec .-= 4 - log(73.53 * 0.05 * ((K)^-0.478))
		fit_vec[2:end] += best[1 : K-1]

		i_max = argmax(fit_vec)
		last[K] = i_max
		best[K] = fit_vec[i_max]
	end

	change_points = zeros(Int64,n)
	i_cp = n+1
	ind = n+1
	while true
		i_cp -= 1
		change_points[i_cp] = ind
		if ind == 1
			break
		end
		ind = last[ind-1]
	end
	change_points = change_points[i_cp : end]
	edges[change_points]

end
function binedges(alg::DiscretizeBayesianBlocks, data::AbstractArray{N}) where {N<:Integer}
	data = convert(Array{Float64}, data)
	return binedges(alg, data)
end
