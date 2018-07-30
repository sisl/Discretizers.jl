using DataStructures

abstract type DiscretizeMODL <: DiscretizationAlgorithm end

struct DiscretizeMODL_Optimal <: DiscretizeMODL end
struct DiscretizeMODL_Greedy <: DiscretizeMODL end
struct DiscretizeMODL_PostGreedy <: DiscretizeMODL
    max_bin_count :: Int
    DiscretizeMODL_PostGreedy(max_bin_count::Integer = 0) = new(round(Int, max_bin_count))
end

function binedges(
    alg             :: DiscretizeMODL,
    data_continuous :: AbstractArray{N},
    data_class      :: AbstractArray{I},
    ) where {N<:Real, I<:Integer}

    @assert(length(data_continuous)==length(data_class))
    p = sortperm(data_continuous)
    data_continuous = data_continuous[p]
    data_class = data_class[p]

    if isa(alg, DiscretizeMODL_Optimal)
        return optimal_result(data_continuous,data_class)
    elseif isa(alg, DiscretizeMODL_Greedy)
        return greedy_merge(data_continuous,data_class)
    else
        @assert(isa(alg, DiscretizeMODL_PostGreedy))
        return post_greedy_result(data_continuous,data_class,alg.max_bin_count)
    end
end

function MODL_value2_oneintval(
    continuous_ij  :: AbstractArray{T},
    class_value_ij :: AbstractArray{S},
    class_uniq     :: AbstractArray{S},
    ) where {T<:AbstractFloat, S<:Integer}

    n = length(continuous_ij)
    J = length(class_uniq)

    first_part = lfactorial(n+J-1) - lfactorial(J-1) - lfactorial(n)
    second_part = lfactorial(n)
    # Note(Yi-Chun): lfactorial(n) is log(n!)

    for J_index = 1:J
            n_J = count(x->x==class_uniq[J_index],class_value_ij)
            second_part = second_part - lfactorial(n_J)
    end

    return first_part+second_part
end

function optimal_result(
    continuous      :: AbstractArray{T},
    discrete_target :: AbstractArray{S}
    ) where {T<:AbstractFloat, S<:Integer}

    n = length(continuous)

    Disc_ijk_retval = Array{Array}(undef,n,n)
    Disc_ijk_MODL_value = Array{AbstractFloat}(undef,n,n)
    for j = 1:n
            for k = 1:n
                    if k > j
                            Disc_ijk_MODL_value[j,k] = Inf
                            Disc_ijk_retval[j,k] = [0]
                    end
            end
    end

    class_uniq = unique(discrete_target)

    for k = 1:n
        for j = k:n
            if k == 1
                Disc_ijk_retval[j,k] = [j]
                Disc_ijk_MODL_value[j,k] = MODL_value2_oneintval(
                                      continuous[1:j], discrete_target[1:j],class_uniq)
            else
                MODL_value = Inf
                select_intval = 0

                for i = 1:j-1
                    second_MODL = MODL_value2_oneintval(
                                  continuous[i+1:j],discrete_target[i+1:j],class_uniq)
                    current_MODL = Disc_ijk_MODL_value[i,k-1] + second_MODL
                    if current_MODL < MODL_value
                        MODL_value = current_MODL
                        select_intval = i
                    end
                end

                Disc_ijk_retval[j,k] = append!(copy(Disc_ijk_retval[select_intval,k-1]),[j])
                Disc_ijk_MODL_value[j,k] = MODL_value
            end

        end
    end

    full_length_k_intval = copy(Disc_ijk_MODL_value[n,:])

    for l = 1:n
        full_length_k_intval[l] += lfactorial(n+l-1) - lfactorial(l-1) - lfactorial(n)
    end

    desired_intval_number = argmin(full_length_k_intval)

    bin_edges_index = Disc_ijk_retval[n,desired_intval_number]
    bin_edges = append!([1],bin_edges_index)

    bin_edge_value = Vector{AbstractFloat}(undef,length(bin_edges))

    for index = 1 : length(bin_edge_value)
        if index == 1
                bin_edge_value[index] = continuous[1]
        elseif index == length(bin_edge_value)
                bin_edge_value[index] = continuous[end]
        else
                bin_edge_value[index] = 0.5*(continuous[bin_edges[index]]+
                                             continuous[bin_edges[index]+1])
        end
    end
    return bin_edge_value
end

function merge_adj_intval(
    A_distr :: AbstractArray{S}, # Note(Yi-Chun): Distribution of class values in A
    B_distr :: AbstractArray{S}  # Note(Yi-Chun): Distribution of class values in B
    ) where {S<:Integer}

    @assert(length(A_distr) == length(B_distr))
    J = length(B_distr)

    n_A = sum(A_distr)
    n_B = sum(B_distr)

    Delta = lfactorial(n_A+n_B+J-1) + lfactorial(J-1) - lfactorial(n_A+J-1) - lfactorial(n_B+J-1)

    for j = 1:J
        n_A_J = A_distr[j]
        n_B_J = B_distr[j]
        Delta = Delta - lfactorial(n_A_J+n_B_J) + lfactorial(n_A_J) + lfactorial(n_B_J)
    end
    Delta
end

function greedy_merge_index(
    continuous  :: AbstractArray{T},
    class_value :: AbstractArray{S},
    ) where {T<:AbstractFloat,S<:Integer}

    @assert(length(continuous) == length(class_value))

    n = length(continuous)
    all_class_value = unique(class_value)
    J = length(all_class_value)

    if n==1
        return [1]
    end

    pq = DataStructures.PriorityQueue()
    # Note(Yi-Chun): The PriorQueue sorts differences of MODL after merging of adjacent intervals
    distr_in_intval = Dict()
    # Note(Yi-Chun): This dictionary contains the distribution in each interval
    adj_for_intval = Dict()
    # Note(Yi-Chun): This dictionary contains the two adjacent interval for interval i

    MODL = log(n) + lfactorial(2n-1) - lfactorial(n-1) - lfactorial(n) + n*log(J-1)
    # Note(Yi-Chun): Intial MODL when each attribute is treated as a single bin

    for i = 1:n-1
        A_Distrib_in_intval = zeros(Int64,J)
        A_value_index = something(findfirst(isequal(class_value[i]), all_class_value), 0)

        A_Distrib_in_intval[A_value_index] = 1
        # Note(Yi-Chun): Set up distribution in each bin as [0,0,..0,1,0,..0]
        distr_in_intval[i] = A_Distrib_in_intval
        # Note(Yi-Chun): Here we label intervals by the index of their first boundary.

        # Note(Yi-Chun): For each interval we assign 4 adjacent intervals for it.
        #                Two in the front and two in the behind.
        if i==1
            adj_for_intval[i] = [2,3]
        elseif i==2
            adj_for_intval[i] = [1,3,4]
        elseif i==n-1
            adj_for_intval[i] = [i-2,i-1,i+1]
        else
            adj_for_intval[i] = [i-2,i-1,i+1,i+2]
        end

        B_Distrib_in_intval = zeros(Int64,J)
        B_value_index = something(findfirst(isequal(class_value[i+1]), all_class_value), 0)

        B_Distrib_in_intval[B_value_index] = 1
        if i == (n-1) # Note(Yi-Chun): The adjacents of the last interval are n-2 and n-1
            distr_in_intval[n] = B_Distrib_in_intval
            adj_for_intval[i+1] = [i-1,i]
        end

        X = merge_adj_intval(A_Distrib_in_intval,B_Distrib_in_intval)
        pq[i+1] = X
    end

    n_intval = n
    first_could_remove = 2
    last_could_remove = n

    while n_intval > 4
        min_diff = DataStructures.peek(pq)[2]
        first_term_in_delta = log((n_intval-1)/(n+n_intval-1))

        if (min_diff + first_term_in_delta) < 0
            MODL = MODL + min_diff + first_term_in_delta
            removed = DataStructures.dequeue!(pq)
            if removed == first_could_remove
                # Note(Yi-Chun): Interval labels: y=1,(removed),z,w,s
                @assert(length(adj_for_intval[removed]) == 3)
                @assert(adj_for_intval[removed][1] == 1)
                z = adj_for_intval[removed][2]
                w = adj_for_intval[removed][3]
                first_could_remove = z
                # Note(Yi-Chun): Merge the distribution
                Merge_distr = distr_in_intval[1] + distr_in_intval[removed]
                # Note(Yi-Chun): Update the Delta value for the only one adjacent
                pq[z] = merge_adj_intval(Merge_distr,distr_in_intval[z])
                # Note(Yi-Chun): Update the structure
                distr_in_intval[1] = Merge_distr

                # Note(Yi-Chun): Update the adjacent structure
                adj_for_intval[1][1] = z
                adj_for_intval[1][2] = w
                s = adj_for_intval[z][4]
                adj_for_intval[z] = [1,w,s]
                adj_for_intval[w][1] = 1

                # Note(Yi-Chun): Delete the information of removed one
                delete!(adj_for_intval,removed)
                delete!(distr_in_intval,removed)

            elseif removed == last_could_remove
                @assert(length(adj_for_intval[removed]) == 2)
                x = adj_for_intval[removed][1]
                y = adj_for_intval[removed][2]
                last_could_remove = y
                Merge_distr = distr_in_intval[y] + distr_in_intval[removed]
                pq[y] = merge_adj_intval(distr_in_intval[x],Merge_distr)
                distr_in_intval[y] = Merge_distr
                pop!(adj_for_intval[x])
                pop!(adj_for_intval[y])
                delete!(adj_for_intval,removed)
                delete!(distr_in_intval,removed)

            else
                # Note(Yi-Chun): Interval labels: x,y,(removed),z,w
                # Note(Yi-Chun): Merge the distribution
                y = adj_for_intval[removed][2]
                Merge_distr = distr_in_intval[y] + distr_in_intval[removed]
                # Note(Yi-Chun): Update the Delta value for two adjacents
                x = adj_for_intval[removed][1]
                pq[y] = merge_adj_intval(distr_in_intval[x],Merge_distr)
                z= adj_for_intval[removed][3]
                pq[z] = merge_adj_intval(Merge_distr,distr_in_intval[z])
                # Note(Yi-Chun): Update the structure
                distr_in_intval[y] = Merge_distr

                # Note(Yi-Chun): Update the adjacent structure
                if length(adj_for_intval[removed]) == 3
                    adj_for_intval[y][3] = z
                    pop!(adj_for_intval[y])
                    adj_for_intval[x][end] = z
                    adj_for_intval[z][1] = x
                    adj_for_intval[z][2] = y
                else
                    w = adj_for_intval[removed][4]
                    adj_for_intval[x][end] = z
                    adj_for_intval[y][end-1] = z
                    adj_for_intval[y][end] = w
                    adj_for_intval[z][1] = x
                    adj_for_intval[z][2] = y
                    adj_for_intval[w][1] = y
                end

                # Note(Yi-Chun): Delete the information of removed one
                delete!(adj_for_intval,removed)
                delete!(distr_in_intval,removed)
            end
            n_intval = n_intval - 1
        else
            break
        end
    end
    # Note(Yi-Chun): Here we manage the case that when bin number goes under 4,
    #                since we have to use different label for intervals

    if n_intval > 4
        binedges = sort(collect(keys(distr_in_intval)))
        return binedges
    else
        binedges = sort(collect(keys(distr_in_intval)))
        while ((DataStructures.peek(pq)[2] + log((n_intval-1)/(n+n_intval-1)))<0) && (n_intval>2)
            MODL = MODL + DataStructures.peek(pq)[2] + log((n_intval-1)/(n+n_intval-1))
            n_intval = n_intval-1
            removed = DataStructures.dequeue!(pq)
            prior = binedges[something(findfirst(isequal(removed), binedges), 0)-1]

            Merge_distr = distr_in_intval[removed] + distr_in_intval[prior]
            distr_in_intval[prior] = Merge_distr
            delete!(adj_for_intval,removed)
            delete!(distr_in_intval,removed)
            binedges = sort(collect(keys(distr_in_intval)))

            for i = 1 : n_intval-1
                X = distr_in_intval[binedges[i]]
                Y = distr_in_intval[binedges[i+1]]
                pq[binedges[i+1]] = merge_adj_intval(X,Y)
            end
        end

        if (DataStructures.peek(pq)[2] + log((n_intval-1)/(n+n_intval-1)))<0
            return [1]
        else
            return binedges
        end
    end
end

function greedy_merge(
    continuous  :: AbstractArray{T},
    class_value :: AbstractArray{S},
    ) where {T<:AbstractFloat,S<:Integer}

    binedges = greedy_merge_index(continuous,class_value)
    append!(binedges,[length(continuous)])
    n = length(binedges)
    bin_edges = Vector{Float64}(undef,n)
    for i = 2: n-1
        binedges[i] = binedges[i]-1
    end

    for j = 1: n
        if j == 1
            bin_edges[1] = continuous[binedges[1]]
        elseif j==n
            bin_edges[n] = continuous[binedges[n]]
        else
            bin_edges[j] = 0.5*(continuous[binedges[j]] + continuous[binedges[j]+1])
        end
    end

    return bin_edges
end

# Note(Yi-Chun): The following 4 functions are used in post_greedy methods.

function methods_split(continuous,class_value,distr,i,j,uniq_class,I)

    N = length(continuous)
    continuous_ij = continuous[i:j-1]
    class_ij = class_value[i:j-1]
    distr_ij = distr[i]

    n = length(continuous_ij)
    J = length(uniq_class)
    distr_A = zeros(Int64,J)

    current_MODL = Inf
    current_split = 0
    current_distr_A = zeros(Int64,J)
    current_distr_B = distr_ij

    for n_A_end = 1:n-1
        distr_A[something(findfirst(isequal(class_ij[n_A_end]), uniq_class),0)] += 1
        distr_B = distr_ij - distr_A

        Del = lfactorial(n_A_end+J-1)+lfactorial(n-n_A_end+J-1)-lfactorial(n+J-1)-lfactorial(J-1)

        for j = 1:J
            Del += lfactorial(distr_A[j]+distr_B[j])-lfactorial(distr_A[j])-lfactorial(distr_B[j])
        end


        if Del < current_MODL
            current_MODL = Del
            current_split = n_A_end
            current_distr_A = deepcopy(distr_A)
            current_distr_B = deepcopy(distr_B)
        end
    end

    current_MODL += log((N+I)/(I))
    current_split += i

    return (current_MODL,current_split,current_distr_A,current_distr_B)
end

function methods_merge(
    A_distr   :: AbstractArray{S},
    B_distr   :: AbstractArray{S},
    N,
    I,
    ) where {S<:Integer}

    # Note(Yi-Chun): This function is similar to the previous function merge_adj_intval.
    #                The only different part is the difference of MODL value after merging.
    @assert(length(A_distr) == length(B_distr))
    J = length(B_distr)
    n_A = sum(A_distr)
    n_B = sum(B_distr)
    Delta = lfactorial(n_A+n_B+J-1) + lfactorial(J-1) - lfactorial(n_A+J-1) - lfactorial(n_B+J-1)
    for j = 1:J
        n_A_J = A_distr[j]
        n_B_J = B_distr[j]
        Delta = Delta - lfactorial(n_A_J+n_B_J) + lfactorial(n_A_J) + lfactorial(n_B_J)
    end
    Delta += log((I-1)/(N+I-1))
    return Delta
end

function methods_merge_split(continuous,class_value,distr,i,j,k,uniq_class,I)

    continuous_ij = continuous[i:j-1]
    class_ij = class_value[i:j-1]
    continuous_jk = continuous[j:k-1]
    class_jk = class_value[j:k-1]
    distr_ij = distr[i]
    distr_jk = distr[j]
    N = length(continuous)
    Del_1 = methods_merge(distr_ij,distr_jk,N,I)

    pseudo_dict = Dict()
    pseudo_dict[i] = distr_ij + distr_jk
    split_result = methods_split(continuous,class_value,pseudo_dict,i,k,uniq_class,I-1)

    Del = Del_1 + split_result[1]
    return (Del,split_result[2],split_result[3],split_result[4])
end

function methods_merge2_split(continuous,class_value,distr,i,j,k,l,uniq_class,I)

    N = length(continuous)
    continuous_ij = continuous[i:j-1]
    continuous_jk = continuous[j:k-1]
    continuous_kl = continuous[k:l-1]
    class_ij = class_value[i:j-1]
    class_jk = class_value[j:k-1]
    class_kl = class_value[k:l-1]
    distr_ij = distr[i]
    distr_jk = distr[j]
    distr_kl = distr[k]
    Del_1 = methods_merge(distr_ij,distr_jk,N,I)
    Del_2 = methods_merge(distr_ij + distr_jk,distr_kl,N,I-1)
    pseudo_dict = Dict()
    pseudo_dict[i] = distr_ij + distr_jk + distr_kl
    split_result = methods_split(continuous,class_value,pseudo_dict,i,l,uniq_class,I-2)

    Del = Del_1 + Del_2 + split_result[1]

    return (Del,split_result[2],split_result[3],split_result[4])
end

function PQ_methods_updata(continuous,class_value,uniq_class,binedges,distr,post_pq,effects,index,method)
    # Note(Yi-Chun): (index,method) is the index of the edge that we want to update its method in priorityqueue
    I = length(binedges) - 1
    # Note(Yi-Chun): Since in post_greedy part, we add the index N+1 as ending of bin edges for convenience
    N = length(continuous)

    if method == "M"
        A_distr = distr[binedges[index]]
        B_distr = distr[binedges[index+1]]
        post_pq[(binedges[index],method)] = methods_merge(A_distr,B_distr,N,I)
    elseif method == "S"
        method_result = methods_split(continuous,class_value,distr,binedges[index],binedges[index+1],uniq_class,I)
        post_pq[(binedges[index],method)] = method_result[1]
        effects[(binedges[index],method)] = method_result[2:end]
    elseif method == "MS"
        method_result = methods_merge_split(continuous,class_value,distr,binedges[index],
                                            binedges[index+1],binedges[index+2],uniq_class,I)
        post_pq[(binedges[index],method)] = method_result[1]
        effects[(binedges[index],method)] = method_result[2:end]
    else
        method_result = methods_merge2_split(continuous,class_value,distr,binedges[index],binedges[index+1],
                                             binedges[index+2],binedges[index+3],uniq_class,I)
        post_pq[(binedges[index],method)] = method_result[1]
        effects[(binedges[index],method)] = method_result[2:end]
    end
end

function remove_methods_on_index(index,methods_on_index,post_pq,effects)
    meth = methods_on_index[index]
    for i = 1: length(meth)
        post_pq[(index,meth[i])] = Inf
        delete!(effects,(index,meth[i]))
    end
end

insert_and_dedup!(v::Vector, x) = (splice!(v, searchsorted(v,x), [x]); v)


function uncondi_greedy_merge_index(
    continuous  :: AbstractArray{T},
    class_value :: AbstractArray{S}
    ) where {T<:AbstractFloat,S<:Integer}
    # Note(Yi-Chun): This function processes the unconditional bin merge, Adapted from the function greedy_merge
    @assert(length(continuous) == length(class_value))

    n = length(continuous)
    all_class_value = unique(class_value)
    J = length(all_class_value)
    length_of_Greedy_merge = length(greedy_merge_index(continuous,class_value))

    pq = DataStructures.PriorityQueue()
    distr_in_intval = Dict()
    adj_for_intval = Dict()

    MODL = log(n) + lfactorial(2n-1) - lfactorial(n-1) - lfactorial(n) + n*log(J-1)

    total_distrib = zeros(Int64,J)

    for i = 1:n-1
        A_Distrib_in_intval = zeros(Int64,J)
        A_value_index = something(findfirst(isequal(class_value[i]), all_class_value), 0)
        A_Distrib_in_intval[A_value_index] = 1
        distr_in_intval[i] = A_Distrib_in_intval

        if i==1
            adj_for_intval[i] = [2,3]
        elseif i==2
            adj_for_intval[i] = [1,3,4]
        elseif i==n-1
            adj_for_intval[i] = [i-2,i-1,i+1]
        else
            adj_for_intval[i] = [i-2,i-1,i+1,i+2]
        end

        total_distrib += A_Distrib_in_intval

        B_Distrib_in_intval = zeros(Int64,J)
        B_value_index = something(findfirst(isequal(class_value[i+1]), all_class_value), 0)
        B_Distrib_in_intval[B_value_index] = 1
        if i == (n-1)
            distr_in_intval[n] = B_Distrib_in_intval
            adj_for_intval[i+1] = [i-1,i]
            total_distrib += B_Distrib_in_intval
        end

        X = merge_adj_intval(A_Distrib_in_intval,B_Distrib_in_intval)
        pq[i+1] = X
    end

    one_bin_distrib = Dict()
    one_bin_distrib[1] = total_distrib

    if n==1|J==1
        best_for_far = [1]
        best_for_far_MODL = -Inf
        return (best_for_far,one_bin_distrib)
    end

    n_intval = n
    first_could_remove = 2
    last_could_remove = n

    # Note(Yi-Chun): This best_so_far part will record the best dicretization we meet while merging unconditionally
    best_so_far = collect(1:n)
    best_so_far_MODL = Inf
    best_adj = Dict()
    best_distr = Dict()

    while n_intval > 4
        min_diff = DataStructures.peek(pq)[2]
        first_term_in_delta = log((n_intval-1)/(n+n_intval-1))

        MODL = MODL + min_diff + first_term_in_delta
        removed = DataStructures.dequeue!(pq)
        if removed == first_could_remove
            @assert(length(adj_for_intval[removed]) == 3)
            @assert(adj_for_intval[removed][1] == 1)
            z = adj_for_intval[removed][2]
            w = adj_for_intval[removed][3]
            first_could_remove = z
            # Note(Yi-Chun): Merge the distribution
            Merge_distr = distr_in_intval[1] + distr_in_intval[removed]
            # Note(Yi-Chun): Update the Delta value for the only one adjacent
            pq[z] = merge_adj_intval(Merge_distr,distr_in_intval[z])
            # Note(Yi-Chun): Update the structure
            distr_in_intval[1] = Merge_distr
            # Note(Yi-Chun): Update the pointers
            adj_for_intval[1][1] = z
            adj_for_intval[1][2] = w
            s = adj_for_intval[z][4]
            adj_for_intval[z] = [1,w,s]
            adj_for_intval[w][1] = 1
            # Note(Yi-Chun): Delete the information of removed one
            delete!(adj_for_intval,removed)
            delete!(distr_in_intval,removed)
        elseif removed == last_could_remove
            @assert(length(adj_for_intval[removed]) == 2)
            x = adj_for_intval[removed][1]
            y = adj_for_intval[removed][2]
            last_could_remove = y
            Merge_distr = distr_in_intval[y] + distr_in_intval[removed]
            pq[y] = merge_adj_intval(distr_in_intval[x],Merge_distr)
            distr_in_intval[y] = Merge_distr
            pop!(adj_for_intval[x])
            pop!(adj_for_intval[y])
            delete!(adj_for_intval,removed)
            delete!(distr_in_intval,removed)
        else
            # Note(Yi-Chun): Interval labels: x,y,(removed),z,w
            # Note(Yi-Chun): Merge the distribution
            y = adj_for_intval[removed][2]
            Merge_distr = distr_in_intval[y] + distr_in_intval[removed]
            # Note(Yi-Chun): Update the Delta value for two adjacents
            x = adj_for_intval[removed][1]
            pq[y] = merge_adj_intval(distr_in_intval[x],Merge_distr)
            z= adj_for_intval[removed][3]
            pq[z] = merge_adj_intval(Merge_distr,distr_in_intval[z])
            # Note(Yi-Chun): Update the structure
            distr_in_intval[y] = Merge_distr
            if length(adj_for_intval[removed]) == 3
                adj_for_intval[y][3] = z
                pop!(adj_for_intval[y])
                adj_for_intval[x][end] = z
                adj_for_intval[z][1] = x
                adj_for_intval[z][2] = y
            else
                w = adj_for_intval[removed][4]
                adj_for_intval[x][end] = z
                adj_for_intval[y][end-1] = z
                adj_for_intval[y][end] = w
                adj_for_intval[z][1] = x
                adj_for_intval[z][2] = y
                adj_for_intval[w][1] = y
            end
            # Note(Yi-Chun): Delete the information of removed one
            delete!(adj_for_intval,removed)
            delete!(distr_in_intval,removed)
        end
        n_intval = n_intval - 1

        if (MODL < best_so_far_MODL) && (n_intval<length_of_Greedy_merge+5)
            best_so_far_MODL = MODL
            best_so_far = deepcopy(collect(keys(distr_in_intval)))
            best_distr = deepcopy(distr_in_intval)
        end
    end

    if n_intval > 4
        binedges = sort(collect(keys(distr_in_intval)))
        return binedges
    else
        binedges = sort(collect(keys(distr_in_intval)))
        while (n_intval>2)
            MODL = MODL + DataStructures.peek(pq)[2] + log((n_intval-1)/(n+n_intval-1))
            n_intval = n_intval-1
            removed = DataStructures.dequeue!(pq)
            prior = binedges[something(findfirst(isequal(removed), binedges),0)-1]
            Merge_distr = distr_in_intval[removed] + distr_in_intval[prior]
            distr_in_intval[prior] = Merge_distr
            delete!(adj_for_intval,removed)
            delete!(distr_in_intval,removed)
            binedges = sort(collect(keys(distr_in_intval)))

            for i = 1 : n_intval-1
                X = distr_in_intval[binedges[i]]
                Y = distr_in_intval[binedges[i+1]]
                pq[binedges[i+1]] = merge_adj_intval(X,Y)
            end

            if MODL < best_so_far_MODL
                best_so_far_MODL = MODL
                best_so_far = deepcopy(collect(keys(distr_in_intval)))
                best_distr = deepcopy(distr_in_intval)
            end
        end

        if (DataStructures.peek(pq)[2] + log((n_intval-1)/(n+n_intval-1)))<0
            best_for_far = [1]
            return (best_for_far,one_bin_distrib)
        else
            return (sort(best_so_far),best_distr)
        end
    end
end

function post_greedy_index(continuous,class_value,upper_bound = 0)

    N = length(continuous)
    uniq_class = unique(class_value)
    J = length(uniq_class)

    # Note(Yi-Chun): Check whether we have restriction on bin size
    if upper_bound == 0 # Note(Yi-Chun): the case for no upper bound of bin size
        (bins,distr) = uncondi_greedy_merge_index(continuous,class_value)
        @assert(bins == sort(collect(keys(distr))))
        I = length(bins)
        methods_on_index = Dict()
        for i = 1:I
            methods_on_index[bins[i]] = ["S"]
        end
        append!(bins,[N+1]) # Note(Yi-Chun): for convenience
    else # Note(Yi-Chun): the case for having upper bound of bin size
        I = upper_bound-1
        reminder = N%I
        new_edge = 1
        bins = [1]
        for i = 1 : I-1
            new_edge += div(N,I)
            if reminder > 0
                new_edge += 1
                reminder -= 1
            end
            append!(bins,[new_edge])
        end
        append!(bins,[N+1])
        distr = Dict()
        for bin_index = 1 : I
            distr[bins[bin_index]] = Vector{Int64}(undef,J)
            for j_index = 1 : J
                n_J = count(x->x==uniq_class[j_index],class_value[bins[bin_index]:bins[bin_index+1]-1])
                distr[bins[bin_index]][j_index] = n_J
            end
        end
        methods_on_index = Dict()
        for i = 1:I
            methods_on_index[bins[i]] = ["S"]
        end
    end

        # Note(Yi-Chun): Add methods on each bin into PriorityQueue
        post_pq = DataStructures.PriorityQueue()
        # Note(Yi-Chun): keys in post_pq are represented as: (x,y), where x is the index of bin, y are methods.
        # Note(Yi-Chun): If "S"->split, "M"->merge, "MS"->merge_split, "MMS"->merge_merge_split

        effects = Dict()
        # Note(Yi-Chun): This dictionary record the effects of the methods

        # Note(Yi-Chun): Here we initialize the methods in PriorityQueue
        # Note(Yi-Chun): Methods on bin[1],... ,bin[I-2]. Each bin has 4 methods
        for i = 1 : I-2
            # Note(Yi-Chun): splitting in bin[i]
            method_result = methods_split(continuous,class_value,distr,bins[i],bins[i+1]-1,uniq_class,I)
            post_pq[(bins[i],"S")] = method_result[1]
            effects[(bins[i],"S")] = method_result[2:end]
            # Note(Yi-Chun): merge bin[i] with bin[i+1]
            method_result = methods_merge(distr[bins[i]],distr[bins[2]],N,I)
            post_pq[(bins[i],"M")] = method_result
            append!(methods_on_index[bins[i]],["M"])
            # Note(Yi-Chun): merge_split on bin[i]
            method_result = methods_merge_split(continuous,class_value,distr,
                                                bins[i],bins[i+1],bins[i+2],uniq_class,I)
            post_pq[(bins[i],"MS")] = method_result[1]
            effects[(bins[i],"MS")] = method_result[2:end]
            append!(methods_on_index[bins[i]],["MS"])
            # merge_merge_split on bin[i]
            method_result = methods_merge2_split(continuous,class_value,distr,
                                                 bins[i],bins[i+1],bins[i+2],bins[i+3],uniq_class,I)
            post_pq[(bins[i],"MMS")] = method_result[1]
            effects[(bins[i],"MMS")] = method_result[2:end]
            append!(methods_on_index[bins[i]],["MMS"])
        end

        # Note(Yi-Chun): Methods on bin[I-1]. Only Split, Merge, Merge_Split.
        if I>1
            method_result = methods_split(continuous,class_value,distr,bins[I-1],bins[I]-1,uniq_class,I)
            post_pq[(bins[I-1],"S")] = method_result[1]
            effects[(bins[I-1],"S")] = method_result[2:end]
            method_result = methods_merge(distr[bins[I-1]],distr[bins[I]],N,I)
            post_pq[(bins[I-1],"M")] = method_result
            append!(methods_on_index[bins[I-1]],["M"])
            method_result = methods_merge_split(continuous,class_value,distr,bins[I-1],bins[I],N+1,uniq_class,I)
            post_pq[(bins[I-1],"MS")] = method_result[1]
            effects[(bins[I-1],"MS")] = method_result[2:end]
            append!(methods_on_index[bins[I-1]],["MS"])
        end

        # Note(Yi-Chun): Method on bin[I]. Only Split.
        method_result = methods_split(continuous,class_value,distr,bins[I],N+1,uniq_class,I)
        post_pq[(bins[I],"S")] = method_result[1]
        effects[(bins[I],"S")] = method_result[2:end]

        # Note(Yi-Chun): Here we start the dequeue process
        current_I = I
        time_dequeue = 0
        while (DataStructures.peek(post_pq)[2] < -0.00001 )
            MODL = DataStructures.peek(post_pq)[2]
            time_dequeue += 1

            (removed_index,removed_method) = DataStructures.dequeue!(post_pq)
            removed_posit_bins = searchsorted(bins,removed_index)[1]
            # Note(Yi-Chun): Ittells the position of removed_index in binedges

            # Note(Yi-Chun): This part updates the binedges and distribution of each bin after the dequeue
            if removed_method == "M"
                merged_index = bins[removed_posit_bins+1]
                distr[removed_index] = distr[removed_index] + distr[merged_index]
                delete!(distr,merged_index)
                remove_methods_on_index(merged_index,methods_on_index,post_pq,effects)
                current_I -= 1
                splice!(bins,removed_posit_bins+1)
                methods_on_index[merged_index] = ["S"]

            elseif removed_method == "S"
                effect = effects[(removed_index,removed_method)]
                delete!(effects,(removed_index,removed_method))
                distr[removed_index] = effect[2]
                distr[effect[1]] = effect[3]
                methods_on_index[effect[1]] = ["S"]
                current_I += 1
                insert_and_dedup!(bins, effect[1])

            elseif removed_method == "MS"
                delete!(distr,bins[removed_posit_bins+1])
                effect = effects[(removed_index,removed_method)]
                delete!(effects,(removed_index,removed_method))
                distr[removed_index] = effect[2]
                distr[effect[1]] = effect[3]
                methods_on_index[effect[1]] = ["S"]
                remove_methods_on_index(bins[removed_posit_bins+1],methods_on_index,post_pq,effects)
                methods_on_index[bins[removed_posit_bins+1]] = ["S"]
                splice!(bins,removed_posit_bins+1)
                insert_and_dedup!(bins, effect[1])

            else # Note(Yi-Chun): removed_method == "MMS"
                delete!(distr,bins[removed_posit_bins+1])
                delete!(distr,bins[removed_posit_bins+2])
                remove_methods_on_index(bins[removed_posit_bins+1],methods_on_index,post_pq,effects)
                remove_methods_on_index(bins[removed_posit_bins+2],methods_on_index,post_pq,effects)
                effect = effects[(removed_index,removed_method)]
                delete!(effects,(removed_index,removed_method))
                distr[removed_index] = effect[2]
                distr[effect[1]] = effect[3]
                methods_on_index[effect[1]] = ["S"]
                current_I -= 1
                methods_on_index[bins[removed_posit_bins+1]] = ["S"]
                methods_on_index[bins[removed_posit_bins+2]] = ["S"]
                splice!(bins,removed_posit_bins+1)
                splice!(bins,removed_posit_bins+1)
                insert_and_dedup!(bins, effect[1])
            end

            # Note(Yi-Chun): This part updates the priorityqueue and the effect of each method
            for be_modified = (removed_posit_bins - 2) : (removed_posit_bins + 1)
                 # Note(Yi-Chun): Update the method "Split"
                if (be_modified > 0)
                    PQ_methods_updata(continuous,class_value,uniq_class,bins,distr,
                                        post_pq,effects,be_modified,"S")
                    methods_on_index[bins[be_modified]] = ["S"]
                end
                # Note(Yi-Chun): Update the method "Merge"
                if (be_modified > 0) && (be_modified+1 < current_I+1)
                    PQ_methods_updata(continuous,class_value,uniq_class,bins,distr,
                                        post_pq,effects,be_modified,"M")

                    append!(methods_on_index[bins[be_modified]],["M"])
                end
                # Note(Yi-Chun): Update the method "MergeSplit"
                if (be_modified > 0) && (be_modified+1 < current_I+1)
                    PQ_methods_updata(continuous,class_value,uniq_class,bins,distr,
                                        post_pq,effects,be_modified,"MS")
                    append!(methods_on_index[bins[be_modified]],["MS"])
                end
                # Note(Yi-Chun): Update the method "MergeMergeSplit"
                if (be_modified > 0) && (be_modified+2 < current_I+1)
                    PQ_methods_updata(continuous,class_value,uniq_class,bins,distr,
                                        post_pq,effects,be_modified,"MMS")
                    append!(methods_on_index[bins[be_modified]],["MMS"])
                end
            end

            if upper_bound != 0
                if current_I >= upper_bound
                    for i = 1 : current_I
                        post_pq[(bins[i],"S")] = Inf
                    end
                end
            end
        end
        return bins
end

function post_greedy_result(continuous,class_value,upper_bound=0)

    binedges = post_greedy_index(continuous,class_value,upper_bound)
    bins = Vector{Float64}(undef,length(binedges))
    for i = 1 : length(binedges)
        if i==1
            bins[1] = continuous[1]
        elseif i == length(binedges)
            bins[i] = continuous[end]
        else
            bins[i] = 0.5*(continuous[binedges[i]-1] + continuous[binedges[i]])
        end
    end
    return bins
end
