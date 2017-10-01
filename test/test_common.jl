
@test get_discretization_counts(LinearDiscretizer([0.0,1.0,2.0]), [0.5,0.5,0.5,1.5,1.5]) == [3,2]

# Test for multidimensional discretization
disc1 = LinearDiscretizer([0.0, 1.0, 2.0])
disc2 = LinearDiscretizer([2.0, 3.0, 4.0, 5.0])
data = [0.5 2.5
        0.5 2.5
        0.5 3.5
        0.5 4.5
        1.5 2.5
        1.5 3.5
        1.5 3.5
        1.5 3.5]
counts = [2 1 1
          1 3 0]
@test get_discretization_counts([disc1, disc2], data) == counts
