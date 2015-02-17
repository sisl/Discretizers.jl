
LinearDiscretizer([0.0,0.5,1.0], [1=>:A, 2=>:B])
LinearDiscretizer([0.0,0.5,1.0], Uint8)
@test_throws ErrorException LinearDiscretizer([0.0])
@test_throws ErrorException LinearDiscretizer([0.5,0.0])
@test_throws ErrorException LinearDiscretizer([0.0,1.0,1.0])

ld = LinearDiscretizer([0.0,0.5,1.0])
@test encode(ld, -1.0) == 1
@test encode(ld,  0.0) == 1
@test encode(ld,  0.2) == 1
@test encode(ld,  0.5) == 2
@test encode(ld,  0.7) == 2
@test encode(ld,  1.0) == 2
@test encode(ld,  1.2) == 2
@test encode(ld,  Inf) == 2
@test_throws ErrorException encode(ld,  NaN)
@test encode(ld, float32(0.2)) == 1
@test encode(ld, [-1.0, 0.0, 0.2, 0.5, 0.7, 1.0, 1.2, Inf]) == 
        [1,1,1,2,2,2,2,2]
@test encode(ld, convert(Vector{Float32}, [0.2,0.6])) ==
        [1,2]
@test encode(ld, [0.0 1.0; 0.5 0.2]) == [1 2; 2 1]

@test 0.0 ≤ decode(ld, 1) ≤ 0.5
@test 0.5 ≤ decode(ld, 2) ≤ 1.0
@test_throws KeyError decode(ld,  0)
@test_throws KeyError decode(ld,  3)
@test 0.5 ≤ decode(ld, uint8(2)) ≤ 1.0
mat = decode(ld, [2 1; 1 2])
@test 0.5 ≤ mat[1,1] ≤ 1.0
@test 0.5 ≤ mat[2,2] ≤ 1.0
@test 0.0 ≤ mat[1,2] ≤ 0.5
@test 0.0 ≤ mat[2,1] ≤ 0.5

@test array_matches([extrema(ld)...], [0.0, 1.0], 1e-8)
@test array_matches([extrema(ld, 1)...], [0.0, 0.5], 1e-8)
@test array_matches([extrema(ld, 2)...], [0.5, 1.0], 1e-8)

@test nlabels(ld) == 2
@test array_matches(bincenters(ld), [0.25,0.75], 1e-8)

############################################################

ld = LinearDiscretizer([0,10,20])
@test encode(ld,  -1) == 1
@test encode(ld,   0) == 1
@test encode(ld,   4) == 1
@test encode(ld,  10) == 2
@test encode(ld,  14) == 2
@test encode(ld,  20) == 2
@test encode(ld,  25) == 2
@test_throws InexactError encode(ld,  NaN)
@test encode(ld, uint8(4)) == 1
@test encode(ld, [-1,0,4,10,14,20,25]) == [1,1,1,2,2,2,2]
@test encode(ld, convert(Vector{Uint8}, [4,14])) == [1,2]
@test encode(ld, [-1 4; 14 25]) == [1 1; 2 2]

@test  0 ≤ decode(ld, 1) < 10
@test 10 ≤ decode(ld, 2) ≤ 20
@test_throws KeyError decode(ld,  0)
@test_throws KeyError decode(ld,  3)
@test 10 ≤ decode(ld, uint8(2)) ≤ 20
mat = decode(ld, [2 1; 1 2])
@test 10 ≤ mat[1,1] ≤ 20
@test 10 ≤ mat[2,2] ≤ 20
@test  0 ≤ mat[1,2] < 10
@test  0 ≤ mat[2,1] < 10

@test extrema(ld) == (0,20)
@test extrema(ld, 1) == (0,9)
@test extrema(ld, 2) == (10,20)

@test nlabels(ld) == 2
@test array_matches(bincenters(ld), [4.5,15], 1e-8)