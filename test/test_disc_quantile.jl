@test DiscretizeQuantile(2) == DiscretizeQuantile(2, false)

# NOTE: Test cases are generated by sklearn.preprocessing.KBinsDiscretizer
@test array_matches(binedges(DiscretizeQuantile(1), [1.0,2.0,3.0,4.0,5.0,6.0]), [1.0, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeQuantile(2), [1.0,2.0,3.0,4.0,5.0,6.0]), [1.0, 3.5, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeQuantile(2), [6.0,2.0,30.0,4.0,1.0,1.0]), [1.0, 3.0, 30.0], 1e-8)
@test array_matches(binedges(DiscretizeQuantile(2), [1.0,2.0,3.0,4.0,5.0]), [1.0, 3.0, 5.0], 1e-8)
@test array_matches(binedges(DiscretizeQuantile(3), [1.0,2.0,3.0,4.0,5.0]), [1.0, 2+1/3, 3+2/3, 5.0], 1e-8)
@test_throws ErrorException binedges(DiscretizeQuantile(3, false), [1.0, 1.0])
@test_throws ErrorException binedges(DiscretizeQuantile(3), [1.0,1.0,1.0,1.0,1.0,1.0])

@test array_matches(binedges(DiscretizeQuantile(2, true), [1,2]), [1.0, 1.5, 2.0])
@test array_matches(binedges(DiscretizeQuantile(3, true), [1,2,2,2,3]), [1.0, 2.0, 3.0])
@test array_matches(binedges(DiscretizeQuantile(3, true), [1,2,2,2,50]), [1.0, 2.0, 50.0])
@test array_matches(binedges(DiscretizeQuantile(3, true), [1,2,2,2,51]), [1.0, 2.0, 51.0])
@test array_matches(binedges(DiscretizeQuantile(3, true), [1,1,1,2,3,4,50,51,52]), [1.0, 1+2/3, 19+1/3, 52.0], 1e-8)
@test_throws ErrorException binedges(DiscretizeQuantile(3, false), [1,2,2,2,3])
@test_throws ErrorException binedges(DiscretizeQuantile(3), [2,2,2,2,2])
