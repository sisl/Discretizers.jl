
optimal = DiscretizeMODL_Optimal()
greedy  = DiscretizeMODL_Greedy()
post_greedy = DiscretizeMODL_PostGreedy()

# Case1
continuous = [1.0]; class_value = [1];
@test binedges(optimal,continuous,class_value)     == [1.0,1.0]
@test binedges(greedy,continuous,class_value)      == [1.0,1.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,1.0]

# Case2
continuous = collect(1.0:1.0:4.0); class_value = [1,1,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,4.0]
@test binedges(greedy,continuous,class_value)      == [1.0,4.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,4.0]

# Case3
continuous = collect(1.0:1.0:10.0); class_value = [1,1,1,2,1,2,1,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,10.0]
@test binedges(greedy,continuous,class_value)      == [1.0,10.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,10.0]

# Case4
continuous = collect(1.0:1.0:20.0)
class_value = [1,1,1,2,2,2,2,2,2,2,1,1,1,1,2,2,2,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,20.0]
@test binedges(greedy,continuous,class_value)      == [1.0,3.5,10.5,14.5,20.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,20.0]

# Case5
continuous = collect(1.0:1.0:20.0)
class_value = [1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,2,2,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,3.5,20.0]
@test binedges(greedy,continuous,class_value)      == [1.0,3.5,10.5,15.5,20.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,3.5,20.0]

#Case6
continuous = collect(1.0:1.0:100.0)
class_value = Array{Int64}(undef, 100)
for i in 1 : 100
    class_value[i] = div((i-1),20)
end
@test binedges(optimal,continuous,class_value)     == [1.0,20.5,40.5,60.5,80.5,100.0]
@test binedges(greedy,continuous,class_value)      == [1.0,20.5,40.5,60.5,80.5,100.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,20.5,40.5,60.5,80.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(2)
@test binedges(post_greedy,continuous,class_value) == [1.0,40.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(3)
@test binedges(post_greedy,continuous,class_value) == [1.0,40.5,80.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(4)
@test binedges(post_greedy,continuous,class_value) == [1.0,20.5,40.5,60.5,100.0]

#Case7
continuous = collect(1.0:1.0:100.0)
class_value = [1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,
               1,1,2,3,2,1,2,2,1,1,2,2,2,2,2,2,2,2,3,3,
               3,3,3,3,3,3,3,2,2,3,2,3,2,3,3,3,3,2,2,2,
               1,1,1,1,2,2,2,2,1,1,1,1,3,3,3,3,4,4,4,4,
               4,4,4,4,4,4,4,4,1,1,4,1,4,1,4,4,4,4,4,1];

@test binedges(optimal,continuous,class_value)     == [1.0,12.5,38.5,57.5,72.5,76.5,100.0]
@test binedges(greedy,continuous,class_value)      == [1.0,12.5,38.5,60.5,72.5,76.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(0)
@test binedges(post_greedy,continuous,class_value) == [1.0,12.5,38.5,57.5,72.5,76.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(2)
@test binedges(post_greedy,continuous,class_value) == [1.0,76.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(3)
@test binedges(post_greedy,continuous,class_value) == [1.0,12.5,76.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(4)
@test binedges(post_greedy,continuous,class_value) == [1.0,12.5,38.5,76.5,100.0]
post_greedy = DiscretizeMODL_PostGreedy(5)
@test binedges(post_greedy,continuous,class_value) == [1.0,12.5,38.5,57.5,76.5,100.0]
