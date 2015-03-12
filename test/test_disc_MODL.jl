using Base.Test

include("disc_MODL.jl")

# Case1
continuous = [1.0]; class_value = [1];
@test binedges(optimal,continuous,class_value)     == [1.0,1.0]
@test binedges(greedy,continuous,class_value)      == [1.0,1.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,1.0]

# Case2
continuous = [1.0:1.0:4.0]; class_value = [1,1,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,4.0]
@test binedges(greedy,continuous,class_value)      == [1.0,4.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,4.0]

# Case3
continuous = [1.0:1.0:10.0]; class_value = [1,1,1,2,1,2,1,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,10.0]
@test binedges(greedy,continuous,class_value)      == [1.0,10.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,10.0]

# Case4
continuous = [1.0:1.0:20.0];
class_value = [1,1,1,2,2,2,2,2,2,2,1,1,1,1,2,2,2,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,20.0]
@test binedges(greedy,continuous,class_value)      == [1.0,3.5,10.5,14.5,20.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,20.0]

# Case5
continuous = [1.0:1.0:20.0];
class_value = [1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,2,2,2,2,2];
@test binedges(optimal,continuous,class_value)     == [1.0,3.5,20.0]
@test binedges(greedy,continuous,class_value)      == [1.0,3.5,10.5,15.5,20.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,3.5,20.0]

#Case6
continuous = [1.0:1.0:100.0];
class_value = Array(Int64,100)
for i = 1 : 100
        class_value[i] = div((i-1),20)
end
@test binedges(optimal,continuous,class_value)     == [1.0,20.5,40.5,60.5,80.5,100.0]
@test binedges(greedy,continuous,class_value)      == [1.0,20.5,40.5,60.5,80.5,100.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,20.5,40.5,60.5,80.5,100.0]
@test binedges(post_greedy,continuous,class_value,2) == [1.0,40.5,100.0]
@test binedges(post_greedy,continuous,class_value,3) == [1.0,40.5,80.5,100.0]
@test binedges(post_greedy,continuous,class_value,4) == [1.0,20.5,40.5,60.5,100.0]

#Case7
continuous = [1.0:1.0:100.0];
class_value = [1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,
               1,1,2,3,2,1,2,2,1,1,2,2,2,2,2,2,2,2,3,3,
               3,3,3,3,3,3,3,2,2,3,2,3,2,3,3,3,3,2,2,2,
               1,1,1,1,2,2,2,2,1,1,1,1,3,3,3,3,4,4,4,4,
               4,4,4,4,4,4,4,4,1,1,4,1,4,1,4,4,4,4,4,1];

@test binedges(optimal,continuous,class_value)     == [1.0,12.5,38.5,57.5,72.5,76.5,100.0]
@test binedges(greedy,continuous,class_value)      == [1.0,12.5,38.5,60.5,72.5,76.5,100.0]
@test binedges(post_greedy,continuous,class_value) == [1.0,12.5,38.5,57.5,72.5,76.5,100.0]
@test binedges(post_greedy,continuous,class_value,2) == [1.0,76.5,100.0]
@test binedges(post_greedy,continuous,class_value,3) == [1.0,12.5,76.5,100.0]
@test binedges(post_greedy,continuous,class_value,4) == [1.0,12.5,38.5,76.5,100.0]
@test binedges(post_greedy,continuous,class_value,5) == [1.0,12.5,38.5,57.5,76.5,100.0]
